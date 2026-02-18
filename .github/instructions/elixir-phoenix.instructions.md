---
description: 'Elixir and Phoenix Framework coding conventions and guidelines'
applyTo: '**/*.ex, **/*.exs'
---

# Elixir and Phoenix Framework

## General Guidelines

- Follow the official Elixir Style Guide and use `mix format` for consistent formatting.
- Use snake_case for variables/functions/atoms and PascalCase for module names.
- Keep functions short and focused; prefer pattern matching and guard clauses over nested conditionals.
- Favor meaningful names over short or generic ones.
- Comment only when necessary — let pattern matching and function names document intent.
- Apply the Single Responsibility Principle to modules and functions.
- Prefer composition over complex abstractions; use `use`, `import`, and `alias` thoughtfully.
- Keep controllers thin — delegate business logic to contexts, services, or domain modules.
- Use Phoenix Contexts to organize related functionality and enforce boundaries.
- Extract reusable logic into separate modules or shared utilities.
- Use structs with `@enforce_keys` to ensure required fields are present.
- Leverage pattern matching for control flow instead of conditionals.
- Use the pipe operator (`|>`) for data transformation pipelines.
- Prefer immutability; avoid mutating data structures.
- Use `with` for sequential operations that may fail, ensuring clean error handling.
- Avoid deeply nested case/cond statements — favor pattern matching in function heads.
- Use `alias`, `import`, and `require` at the top of modules in a consistent order.
- Follow Phoenix conventions for routing and controller actions.
- Use Phoenix generators to scaffold resources consistently.
- Leverage Ecto for database interactions with changesets for validation.
- Always define migrations with `change/0` when possible, falling back to `up/down` only when necessary.
- Add database indexes for foreign keys and frequently queried columns.
- Use `null: false` in migrations to enforce non-null constraints at the DB level.
- Scope queries in context modules or dedicated query modules for clarity and reuse.
- Use `Repo.preload/2` to eagerly load associations and avoid N+1 queries.
- Leverage `Ecto.Multi` for complex database transactions.
- Keep secrets and configuration out of code using runtime configuration and environment variables.
- Write isolated unit tests for contexts, schemas, and business logic.
- Test controllers and LiveViews with integration tests using `ConnTest` or `LiveViewTest`.
- Use ExUnit callbacks (`setup`, `setup_all`) to prepare test fixtures.
- Avoid `IO.inspect` in production; use `Logger` with appropriate log levels.
- Document public APIs and complex modules with `@moduledoc` and `@doc`.

## Project Structure

- Organize code by **Contexts** (business domains) under `lib/<app_name>/`.
- Define web-related modules (controllers, views, templates, LiveViews) under `lib/<app_name>_web/`.
- Create **service objects** in `lib/<app_name>/services/` to encapsulate complex business logic.
- Define **background jobs** in `lib/<app_name>/jobs/` using Oban or similar job processors.
- Use `lib/<app_name>/types/` for custom Ecto types and domain-specific type definitions.
- Place GraphQL-related code (schemas, resolvers, types) in `lib/<app_name>_web/schema/` and `lib/<app_name>_web/resolvers/`.
- Keep **plugs** in `lib/<app_name>_web/plugs/` for request pipeline customizations.
- Define **channels** in `lib/<app_name>_web/channels/` for real-time WebSocket communication.
- Use `lib/<app_name>_web/components/` for reusable LiveView components and function components.
- Place **queries** in dedicated modules like `lib/<app_name>/queries/` for complex database queries.

## Commands

- Use `mix phx.new` to generate a new Phoenix application.
- Use `mix phx.gen.context` to generate a context with schema and migrations.
- Use `mix phx.gen.html` to generate a controller, views, and templates for a resource.
- Use `mix phx.gen.live` to generate a LiveView for a resource.
- Use `mix phx.gen.json` to generate a JSON API for a resource.
- Use `mix ecto.gen.migration` to create a new database migration.
- Use `mix ecto.migrate` to run pending migrations.
- Use `mix ecto.rollback` to revert the last migration.
- Use `mix ecto.reset` to drop, create, and migrate the database.
- Use `iex -S mix` to start an interactive Elixir shell with the application loaded.
- Use `iex -S mix phx.server` to start the Phoenix server in interactive mode.
- Use `mix phx.server` to start the Phoenix development server.
- Use `mix test` to run the test suite.
- Use `mix format` to format all Elixir files according to `.formatter.exs`.
- Use `mix credo` to run static code analysis for code quality.
- Use `mix deps.get` to fetch project dependencies.
- Use `mix phx.routes` to list all defined routes in the application.
- Use `mix phx.digest` to compile and digest static assets for production.

## Elixir Language Best Practices

### Pattern Matching
- Use pattern matching in function heads for clarity and polymorphism.
  ```elixir
  # Good: Pattern matching in function heads
  def process({:ok, result}), do: {:ok, transform(result)}
  def process({:error, reason}), do: {:error, reason}

  # Avoid: Using case inside function body when pattern matching suffices
  def process(result) do
    case result do
      {:ok, data} -> {:ok, transform(data)}
      {:error, reason} -> {:error, reason}
    end
  end
  ```

### Guard Clauses
- Use guards to add constraints to pattern matches.
  ```elixir
  def calculate_discount(price) when price > 100, do: price * 0.9
  def calculate_discount(price) when price > 50, do: price * 0.95
  def calculate_discount(price), do: price
  ```

### Pipe Operator
- Use the pipe operator for data transformation chains.
  ```elixir
  # Good: Clear data flow from top to bottom
  result =
    data
    |> parse()
    |> transform()
    |> validate()
    |> save()

  # Avoid: Nested function calls
  result = save(validate(transform(parse(data))))
  ```

### With Expression
- Use `with` for sequential operations that may fail.
  ```elixir
  def create_user(params) do
    with {:ok, validated} <- validate_params(params),
         {:ok, user} <- insert_user(validated),
         {:ok, _email} <- send_welcome_email(user) do
      {:ok, user}
    end
  end
  ```

### Error Handling
- Return `{:ok, result}` or `{:error, reason}` tuples for operations that may fail.
- Use `!` suffix (bang functions) only when you expect success and want to raise on errors.
  ```elixir
  # Good: Returns tuple for caller to handle
  def fetch_user(id), do: Repo.get(User, id) |> to_result()

  # Use ! for operations that should raise
  def fetch_user!(id), do: Repo.get!(User, id)
  ```

## Phoenix Framework Best Practices

### Contexts
- Organize related functionality into Phoenix Contexts.
- Keep contexts as the public API for business logic.
- Don't access Ecto schemas directly from controllers; go through contexts.
  ```elixir
  # Good: Controller delegates to context
  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} -> # handle success
      {:error, changeset} -> # handle error
    end
  end
  ```

### Controllers
- Keep controllers thin; delegate to contexts immediately.
- Use `action_fallback` for consistent error handling.
- Return appropriate HTTP status codes.
  ```elixir
  defmodule MyAppWeb.UserController do
    use MyAppWeb, :controller

    action_fallback MyAppWeb.FallbackController

    def create(conn, %{"user" => user_params}) do
      with {:ok, user} <- Accounts.create_user(user_params) do
        conn
        |> put_status(:created)
        |> render("show.json", user: user)
      end
    end
  end
  ```

### LiveView
- Use LiveView for interactive, real-time features without writing JavaScript.
- Keep LiveView modules focused on presentation; delegate to contexts for business logic.
- Use `assign/3` and `assign_new/3` to manage socket state.
- Leverage `handle_event/3` for user interactions.
- Use `handle_info/2` for handling PubSub broadcasts and async messages.
  ```elixir
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "updates")
    end

    {:ok, assign(socket, users: list_users())}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Accounts.delete_user(id)
    {:noreply, assign(socket, users: list_users())}
  end
  ```

### Plugs
- Use plugs for reusable request pipeline logic.
- Define plugs at the router level for authentication/authorization.
- Create custom plugs in `lib/<app_name>_web/plugs/`.
  ```elixir
  defmodule MyAppWeb.Plugs.RequireAuth do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, _opts) do
      case get_session(conn, :user_id) do
        nil -> conn |> put_status(:unauthorized) |> halt()
        _user_id -> conn
      end
    end
  end
  ```

### Changesets
- Use Ecto changesets for data validation and casting.
- Define changesets in schema modules or separate changeset modules.
- Validate data before inserting or updating.
  ```elixir
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :age])
    |> validate_required([:email, :name])
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than: 0)
    |> unique_constraint(:email)
  end
  ```

## Ecto Best Practices

### Queries
- Build queries using Ecto's query syntax.
- Avoid N+1 queries by preloading associations.
  ```elixir
  # Good: Preload associations
  User
  |> preload(:posts)
  |> Repo.all()

  # Avoid: N+1 query
  users = Repo.all(User)
  Enum.map(users, fn user -> Repo.preload(user, :posts) end)
  ```

### Transactions
- Use `Ecto.Multi` for complex transactions.
  ```elixir
  Multi.new()
  |> Multi.insert(:user, user_changeset)
  |> Multi.insert(:profile, fn %{user: user} ->
    profile_changeset(user)
  end)
  |> Repo.transaction()
  ```

### Schemas
- Define schemas with clear field types and associations.
- Use `@primary_key` and `@foreign_key_type` when customizing keys.
- Define virtual fields for computed or temporary data.
  ```elixir
  schema "users" do
    field :email, :string
    field :name, :string
    field :full_name, :string, virtual: true

    has_many :posts, Post

    timestamps()
  end
  ```

### Migrations
- Keep migrations reversible when possible using `change/0`.
- Add indexes for foreign keys and frequently queried columns.
- Use `null: false` to enforce constraints.
  ```elixir
  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:posts, [:user_id])
    create unique_index(:posts, [:title])
  end
  ```

## GraphQL with Absinthe Best Practices

- Define types in `lib/<app_name>_web/schema/types/`.
- Keep resolvers focused in `lib/<app_name>_web/resolvers/`.
- Use dataloaders to batch database queries and avoid N+1 issues.
- Define input objects for mutations.
  ```elixir
  # Type definition
  object :user do
    field :id, non_null(:id)
    field :email, non_null(:string)
    field :posts, list_of(:post), resolve: dataloader(Repo)
  end

  # Resolver
  def create_user(_parent, %{input: params}, _resolution) do
    Accounts.create_user(params)
  end
  ```

## Testing Guidelines

### Unit Tests
- Write unit tests for contexts, schemas, and pure functions.
- Use ExUnit's `describe` blocks to organize related tests.
- Use `setup` and `setup_all` for test fixtures.
  ```elixir
  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{email: "test@example.com", name: "Test"}
      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.email == "test@example.com"
    end

    test "returns error with invalid attributes" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(%{})
    end
  end
  ```

### Integration Tests
- Test controllers using `ConnTest`.
- Test LiveViews using `LiveViewTest`.
  ```elixir
  test "creates user", %{conn: conn} do
    conn = post(conn, Routes.user_path(conn, :create), user: @valid_attrs)
    assert %{id: id} = json_response(conn, 201)["data"]
  end
  ```

### Test Data
- Use `ExMachina` for factories to generate test data.
- Keep factories in `test/support/factory.ex`.
  ```elixir
  def user_factory do
    %User{
      email: sequence(:email, &"user#{&1}@example.com"),
      name: "Test User"
    }
  end
  ```

### Async Tests
- Use `async: true` for tests that don't share state.
  ```elixir
  use MyApp.DataCase, async: true
  ```

## Background Jobs with Oban

- Define jobs in `lib/<app_name>/jobs/`.
- Use `perform/1` to execute job logic.
- Configure queues and workers in `config/config.exs`.
  ```elixir
  defmodule MyApp.Jobs.SendEmailJob do
    use Oban.Worker, queue: :emails, max_attempts: 3

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
      user = Accounts.get_user!(user_id)
      Email.welcome_email(user) |> Mailer.deliver()
      :ok
    end
  end

  # Enqueue job
  %{user_id: user.id}
  |> MyApp.Jobs.SendEmailJob.new()
  |> Oban.insert()
  ```

## API Development Best Practices

- Use Phoenix's JSON rendering for API responses.
- Define JSON views in `lib/<app_name>_web/views/`.
- Use `action_fallback` controllers for consistent error handling.
- Return proper HTTP status codes (200, 201, 204, 400, 401, 404, 422, 500).
- Version APIs using route prefixes (`/api/v1/`).
  ```elixir
  defmodule MyAppWeb.UserView do
    use MyAppWeb, :view

    def render("index.json", %{users: users}) do
      %{data: render_many(users, __MODULE__, "user.json")}
    end

    def render("user.json", %{user: user}) do
      %{
        id: user.id,
        email: user.email,
        name: user.name
      }
    end
  end
  ```

## Security Best Practices

- Use strong parameters by casting and validating with changesets.
- Never trust user input; always validate and sanitize.
- Use CSRF protection (enabled by default in Phoenix).
- Store secrets in environment variables or runtime configuration.
- Use Bcrypt or Argon2 for password hashing (via `bcrypt_elixir` or `argon2_elixir`).
- Implement rate limiting for sensitive endpoints (e.g., with `Hammer`).
- Use HTTPS in production (configure in `endpoint.ex`).
- Set secure cookie options (`:http_only`, `:secure`, `:same_site`).

## Performance Best Practices

- Use database indexes for frequently queried columns.
- Preload associations to avoid N+1 queries.
- Use `Repo.stream/1` for processing large datasets.
- Cache expensive computations with `Cachex`, `Nebulex`, or ETS.
- Use `Task.async/await` for concurrent operations.
- Profile with `:observer`, `:fprof`, or `eprof` to identify bottlenecks.
- Use `telemetry` for metrics and monitoring.
- Defer heavy processing to background jobs.

## Common Pitfalls

- Not preloading associations, causing N+1 queries.
- Mixing business logic in controllers or views.
- Forgetting to add database indexes on foreign keys.
- Not handling errors gracefully in `with` statements.
- Using `!` functions (bang functions) when errors should be handled.
- Blocking the BEAM with long-running synchronous operations.
- Not using changesets for data validation.

## Deployment and Production

- Use releases for production deployments (`mix release`).
- Configure runtime environment in `config/runtime.exs`.
- Use environment variables for secrets and configuration.
- Enable SSL/HTTPS in production.
- Set up proper logging and monitoring.
- Use `mix phx.digest` to compile assets.
- Run migrations on deployment with `mix ecto.migrate`.

## Additional Resources

- [Elixir Official Documentation](https://hexdocs.pm/elixir/)
- [Phoenix Framework Documentation](https://hexdocs.pm/phoenix/)
- [Ecto Documentation](https://hexdocs.pm/ecto/)
- [Absinthe Documentation](https://hexdocs.pm/absinthe/)
- [Oban Documentation](https://hexdocs.pm/oban/)
- [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- [Phoenix LiveView Documentation](https://hexdocs.pm/phoenix_live_view/)
