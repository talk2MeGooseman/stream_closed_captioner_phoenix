---
description: 'Background job processing with Oban in Phoenix applications'
applyTo: 'lib/**/jobs/**/*.ex, **/workers/**/*.ex'
---

# Background Jobs with Oban

## Overview

Oban is a robust job processing library for Elixir that uses PostgreSQL for persistence and coordination. It provides reliable job execution, retries, scheduling, and monitoring.

## Setup

### Installation
```elixir
# mix.exs
defp deps do
  [
    {:oban, "~> 2.13"}
  ]
end
```

### Configuration
```elixir
# config/config.exs
config :my_app, Oban,
  repo: MyApp.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7}, # Prune jobs after 7 days
    {Oban.Plugins.Cron,
     crontab: [
       {"0 2 * * *", MyApp.Jobs.DailyCleanup},  # Run daily at 2am
       {"*/15 * * * *", MyApp.Jobs.StatusCheck}  # Every 15 minutes
     ]}
  ],
  queues: [
    default: 10,      # 10 concurrent jobs
    mailers: 20,      # 20 concurrent email jobs
    media: 5,         # 5 concurrent media jobs
    analytics: 2      # 2 concurrent analytics jobs
  ]

# config/test.exs
config :my_app, Oban, testing: :manual

# config/prod.exs
config :my_app, Oban,
  repo: MyApp.Repo,
  queues: [default: 50, mailers: 50, media: 20]
```

### Migration
```bash
mix ecto.gen.migration add_oban_jobs_table
```

```elixir
# priv/repo/migrations/20XX_add_oban_jobs_table.exs
defmodule MyApp.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def up do
    Oban.Migration.up(version: 11)
  end

  def down do
    Oban.Migration.down(version: 1)
  end
end
```

### Add to Application Supervisor
```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  children = [
    MyApp.Repo,
    MyAppWeb.Endpoint,
    {Oban, Application.fetch_env!(:my_app, Oban)}
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Creating Workers

### Basic Worker
```elixir
defmodule MyApp.Jobs.SendEmailJob do
  use Oban.Worker,
    queue: :mailers,
    max_attempts: 3

  alias MyApp.{Mailer, Emails}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "type" => type}}) do
    user = MyApp.Accounts.get_user!(user_id)

    email =
      case type do
        "welcome" -> Emails.welcome_email(user)
        "reminder" -> Emails.reminder_email(user)
      end

    case Mailer.deliver(email) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
```

### Worker with Custom Options
```elixir
defmodule MyApp.Jobs.ProcessVideoJob do
  use Oban.Worker,
    queue: :media,
    priority: 1,           # 0-3, lower is higher priority
    max_attempts: 5,
    unique: [
      period: 60,          # Only allow one job per video within 60 seconds
      fields: [:args],
      keys: [:video_id]
    ]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"video_id" => video_id}}) do
    video = MyApp.Media.get_video!(video_id)

    with {:ok, processed} <- transcode_video(video),
         {:ok, _} <- generate_thumbnail(processed),
         {:ok, _} <- update_video_status(video, :ready) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Snooze job if resource is temporarily unavailable
  def perform(%Oban.Job{args: %{"video_id" => video_id}} = job) do
    case check_video_service() do
      :available -> process_video(video_id)
      :unavailable -> {:snooze, 30}  # Retry in 30 seconds
    end
  end
end
```

## Enqueuing Jobs

### Basic Enqueue
```elixir
# Create and insert job
%{user_id: user.id, type: "welcome"}
|> MyApp.Jobs.SendEmailJob.new()
|> Oban.insert()

# With custom options
%{user_id: user.id}
|> MyApp.Jobs.SendEmailJob.new(
  queue: :high_priority,
  priority: 0,
  max_attempts: 5
)
|> Oban.insert()
```

### Scheduled Jobs
```elixir
# Schedule job to run in 1 hour
%{user_id: user.id}
|> MyApp.Jobs.ReminderJob.new(schedule_in: 3600)
|> Oban.insert()

# Schedule at specific time
scheduled_at = DateTime.add(DateTime.utc_now(), 86400, :second)

%{user_id: user.id}
|> MyApp.Jobs.ReminderJob.new(scheduled_at: scheduled_at)
|> Oban.insert()
```

### Bulk Enqueue
```elixir
jobs =
  users
  |> Enum.map(fn user ->
    MyApp.Jobs.SendEmailJob.new(%{user_id: user.id})
  end)

Oban.insert_all(jobs)
```

### Enqueue from Ecto.Multi
```elixir
Multi.new()
|> Multi.insert(:user, user_changeset)
|> Oban.insert(:welcome_job, fn %{user: user} ->
  MyApp.Jobs.SendEmailJob.new(%{user_id: user.id, type: "welcome"})
end)
|> Repo.transaction()
```

## Job Control Flow

### Success
```elixir
def perform(%Oban.Job{args: args}) do
  # Process successfully
  :ok
end
```

### Discard (Don't Retry)
```elixir
def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
  case MyApp.Accounts.get_user(user_id) do
    nil ->
      # User deleted, don't retry
      :discard

    user ->
      process_user(user)
  end
end
```

### Cancel
```elixir
def perform(%Oban.Job{args: %{"subscription_id" => id}}) do
  case check_subscription(id) do
    :cancelled -> {:cancel, "Subscription was cancelled"}
    :active -> process_subscription(id)
  end
end
```

### Snooze (Retry Later)
```elixir
def perform(%Oban.Job{attempt: attempt} = job) do
  case external_api_call() do
    {:ok, result} ->
      :ok

    {:error, :rate_limited} ->
      # Retry in exponential backoff
      snooze_time = :math.pow(2, attempt) * 60
      {:snooze, round(snooze_time)}

    {:error, reason} ->
      {:error, reason}
  end
end
```

## Error Handling & Retries

### Backoff Strategy
```elixir
defmodule MyApp.Jobs.ApiCallJob do
  use Oban.Worker,
    queue: :default,
    max_attempts: 10

  # Custom backoff
  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    # Exponential backoff: 2^attempt * 60 seconds
    :math.pow(2, attempt) * 60
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    case make_api_call(args) do
      {:ok, result} -> :ok
      {:error, _} = error -> error
    end
  end
end
```

### Custom Timeout
```elixir
use Oban.Worker,
  queue: :default,
  max_attempts: 3,
  timeout: :timer.minutes(5)  # 5 minute timeout
```

## Unique Jobs

### Prevent Duplicates
```elixir
defmodule MyApp.Jobs.SyncUserJob do
  use Oban.Worker,
    queue: :default,
    unique: [
      period: 60,                    # Within 60 seconds
      fields: [:queue, :worker],     # Check these fields
      keys: [:user_id],              # Plus these arg keys
      states: [:available, :scheduled, :executing]
    ]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    sync_user_data(user_id)
    :ok
  end
end

# Attempting to enqueue duplicate will return existing job
{:ok, job} =
  %{user_id: 123}
  |> MyApp.Jobs.SyncUserJob.new()
  |> Oban.insert()

# This will return the same job, not create a new one
{:ok, same_job} =
  %{user_id: 123}
  |> MyApp.Jobs.SyncUserJob.new()
  |> Oban.insert()

assert job.id == same_job.id
```

### Replace Strategy
```elixir
use Oban.Worker,
  unique: [
    period: :infinity,
    replace: [:scheduled_at, :args]  # Replace these fields
  ]
```

## Recurring Jobs (Cron)

### Configure Cron Plugin
```elixir
# config/config.exs
config :my_app, Oban,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       # Send daily report at 8am
       {"0 8 * * *", MyApp.Jobs.DailyReportJob, args: %{type: "summary"}},

       # Cleanup every hour
       {"0 * * * *", MyApp.Jobs.CleanupJob},

       # Health check every 5 minutes
       {"*/5 * * * *", MyApp.Jobs.HealthCheckJob},

       # Weekly backup on Sundays at midnight
       {"0 0 * * 0", MyApp.Jobs.BackupJob},

       # Run on first day of month
       {"0 0 1 * *", MyApp.Jobs.MonthlyBillingJob}
     ]}
  ]
```

### Cron Expression Reference
```
* * * * *
│ │ │ │ │
│ │ │ │ └─── Day of week (0-6, Sunday = 0)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

## Monitoring & Observability

### Job Telemetry
```elixir
# lib/my_app/telemetry.ex
def handle_event([:oban, :job, :start], measure, meta, _config) do
  Logger.info("Job started: #{meta.worker} - #{meta.id}")
end

def handle_event([:oban, :job, :stop], measure, meta, _config) do
  duration = System.convert_time_unit(measure.duration, :native, :millisecond)
  Logger.info("Job completed: #{meta.worker} in #{duration}ms")
end

def handle_event([:oban, :job, :exception], measure, meta, _config) do
  Logger.error("Job failed: #{meta.worker} - #{inspect(meta.reason)}")
end

# Attach handler in application.ex
:telemetry.attach_many(
  "oban-logger",
  [
    [:oban, :job, :start],
    [:oban, :job, :stop],
    [:oban, :job, :exception]
  ],
  &MyApp.Telemetry.handle_event/4,
  nil
)
```

### Check Job Status
```elixir
# Get job by ID
job = Oban.Job |> Repo.get(job_id)

# Query jobs
import Ecto.Query

# All scheduled jobs
scheduled_jobs =
  Oban.Job
  |> where([j], j.state == "scheduled")
  |> Repo.all()

# Failed jobs in last hour
recent_failures =
  Oban.Job
  |> where([j], j.state == "discarded")
  |> where([j], j.attempted_at > ago(1, "hour"))
  |> Repo.all()
```

### Cancel Jobs
```elixir
# Cancel specific job
Oban.cancel_job(job_id)

# Cancel all jobs for a worker
Oban.cancel_all_jobs(MyApp.Jobs.SendEmailJob)

# Cancel jobs matching query
import Ecto.Query

Oban.Job
|> where([j], j.queue == "low_priority")
|> where([j], j.state == "scheduled")
|> Oban.cancel_all_jobs()
```

## Testing

### Setup Test Mode
```elixir
# config/test.exs
config :my_app, Oban, testing: :manual
```

### Test Job Execution
```elixir
defmodule MyApp.Jobs.SendEmailJobTest do
  use MyApp.DataCase, async: true
  use Oban.Testing, repo: MyApp.Repo

  alias MyApp.Jobs.SendEmailJob

  test "sends welcome email successfully" do
    user = insert(:user)

    assert :ok =
      perform_job(SendEmailJob, %{user_id: user.id, type: "welcome"})

    # Verify email was sent
    assert_email_sent(to: user.email)
  end

  test "retries on API error" do
    user = insert(:user)

    # Mock API to fail
    expect(EmailProviderMock, :deliver, fn _ ->
      {:error, :timeout}
    end)

    assert {:error, _} =
      perform_job(SendEmailJob, %{user_id: user.id})
  end
end
```

### Test Job Enqueuing
```elixir
test "enqueues welcome job after user creation" do
  {:ok, user} = Accounts.create_user(valid_attrs)

  assert_enqueued worker: SendEmailJob, args: %{user_id: user.id}
end

test "enqueues job with correct options" do
  user = insert(:user)

  Accounts.schedule_reminder(user, days: 7)

  assert_enqueued worker: ReminderJob,
                  args: %{user_id: user.id},
                  scheduled_at: {7, :days}
end
```

### Test in Integration Mode
```elixir
# config/test.exs
config :my_app, Oban, testing: :inline

# Jobs will execute immediately in tests
test "processes payment and sends receipt" do
  {:ok, payment} = Payments.create_payment(attrs)

  # Job executed inline, email sent immediately
  assert_email_sent(to: payment.user.email)
end
```

## Best Practices

### Job Design
- Keep jobs small and focused on a single task
- Make jobs idempotent (safe to run multiple times)
- Use meaningful job names and args
- Add logging for debugging
- Handle all error cases explicitly

### Error Handling
- Return `:ok` for success
- Return `{:error, reason}` for retryable failures
- Return `:discard` for non-retryable failures
- Use `{:snooze, seconds}` for temporary issues
- Implement custom backoff for external API calls

### Performance
- Choose appropriate queue and concurrency limits
- Use `unique` option to prevent duplicate work
- Batch similar jobs when possible
- Monitor job execution time and adjust timeouts
- Use priority for time-sensitive jobs

### Monitoring
- Set up telemetry for job metrics
- Monitor queue depths and processing times
- Alert on high failure rates
- Regularly prune old job records
- Use Oban Web for dashboard monitoring

## Advanced Patterns

### Dynamic Queue Management
```elixir
# Adjust queue size dynamically
Oban.scale_queue(queue: :media, limit: 50)

# Pause queue
Oban.pause_queue(queue: :low_priority)

# Resume queue
Oban.resume_queue(queue: :low_priority)
```

### Job Chaining
```elixir
defmodule MyApp.Jobs.ProcessOrderJob do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"order_id" => order_id}}) do
    with {:ok, order} <- process_order(order_id),
         {:ok, _} <- charge_payment(order),
         {:ok, _} <- enqueue_fulfillment(order) do
      :ok
    end
  end

  defp enqueue_fulfillment(order) do
    %{order_id: order.id}
    |> MyApp.Jobs.FulfillOrderJob.new()
    |> Oban.insert()
  end
end
```

## Resources

- [Oban Documentation](https://hexdocs.pm/oban/)
- [Oban Pro](https://getoban.pro/) - Commercial plugins
- [Oban Web](https://hexdocs.pm/oban_web/) - Web dashboard
