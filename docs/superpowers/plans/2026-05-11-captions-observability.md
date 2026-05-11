# Captions Observability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Instrument the caption flow + its outbound HTTP dependencies with a single `:telemetry` emission layer that feeds structured JSON logs, Phoenix LiveDashboard, and Prometheus (via Prom_Ex), with two Grafana dashboards committed to the repo.

**Architecture:** One emission layer (`:telemetry.span/3` and `:telemetry.execute/3` calls at every caption-flow touchpoint), three consumers (Logger, LiveDashboard, Prom_Ex), single source of truth for metric definitions (`Observability.Metrics`). New Relic stays untouched as a SaaS backstop.

**Tech Stack:** Elixir / Phoenix 1.7, `:telemetry` + `:telemetry_metrics` + `:telemetry_poller` (already present), `prom_ex` ~> 1.10 (new), `logger_json` ~> 6.0 (new), ExUnit, Mox.

**Spec:** `docs/superpowers/specs/2026-05-11-captions-observability-design.md`

**Branch:** `captions-observability` (already created)

---

## File Structure

**New files (lib/):**
- `lib/stream_closed_captioner_phoenix/observability.ex` — public entry points: `attach_logger_handlers/0`, `measure_active_channels/0`
- `lib/stream_closed_captioner_phoenix/observability/metrics.ex` — `event_metrics/0`, `polling_metrics/0`, `metrics/0` (union for LiveDashboard)
- `lib/stream_closed_captioner_phoenix/observability/prom_ex_plugin.ex` — `PromEx.Plugin` reading from `Observability.Metrics`
- `lib/stream_closed_captioner_phoenix/observability/logger_handler.ex` — `:telemetry` handler emitting structured `Logger` lines
- `lib/stream_closed_captioner_phoenix/prom_ex.ex` — main Prom_Ex supervisor module
- `lib/stream_closed_captioner_phoenix_web/plugs/metrics_auth.ex` — bearer-token check for `/metrics`

**New files (priv/):**
- `priv/grafana/dashboards/captions_overview.json`
- `priv/grafana/dashboards/captions_latency.json`

**New files (test/):**
- `test/support/telemetry_capture.ex` — `ExUnit` helper to capture events
- `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
- `test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
- `test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
- `test/stream_closed_captioner_phoenix/observability/logger_handler_test.exs`
- `test/stream_closed_captioner_phoenix/observability/metrics_test.exs`
- `test/stream_closed_captioner_phoenix_web/plugs/metrics_auth_test.exs`

**Modified files:**
- `mix.exs` — add `prom_ex`, `logger_json` deps
- `config/dev.exs` — Logger format with metadata
- `config/test.exs` — disable Prom_Ex
- `config/runtime.exs` — JSON Logger formatter in prod; read `METRICS_AUTH_TOKEN`
- `lib/stream_closed_captioner_phoenix/application.ex` — add `PromEx` child, call `Observability.attach_logger_handlers/0`
- `lib/stream_closed_captioner_phoenix_web/telemetry.ex` — delegate `metrics/0`
- `lib/stream_closed_captioner_phoenix/captions_pipeline.ex` — wrap spans, emit events, rewrite Logger calls
- `lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex` — wrap span, emit `bits_debit`, rewrite Logger
- `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex` — Logger.metadata, channel events, reply span
- `lib/stream_closed_captioner_phoenix/services/azure.ex` — wrap `perform_translations/3` in span
- `lib/stream_closed_captioner_phoenix/services/gemini.ex` — wrap `perform_translations/3` in span
- `lib/stream_closed_captioner_phoenix/services/zoom.ex` — wrap `send_captions_to/3` in span
- `lib/stream_closed_captioner_phoenix_web/router.ex` — add `:metrics_scrape` pipeline and `/metrics` forward
- `CLAUDE.md` — add `METRICS_AUTH_TOKEN` to env-var list

---

## Conventions used throughout this plan

- **Pre-test invariant:** before each commit, the full suite passes. Use `mix test` to verify. Failing or skipped tests block the commit.
- **Mox setup:** the test_helper.exs already defines `Azure.MockCognitive`, `Gemini.MockCognitive`, `Twitch.MockExtension`, `Twitch.MockHelix`. Tests using these call `import Mox` and `setup :verify_on_exit!`.
- **Factory caveat:** `insert(:user)` already builds `stream_settings` and `bits_balance`. To customize them, pass `stream_settings: build(:stream_settings, ...)` to `insert(:user, ...)`. **Never** `insert(:stream_settings, user: user)` after `insert(:user)`.
- **TelemetryCapture helper (built in Task 2):** test process attaches a handler that forwards events to its mailbox; subsequent `assert_receive` is deterministic because `:telemetry` handlers run synchronously in the emitting process.
- **Commit messages:** keep concise; pattern is `feat:`, `test:`, `refactor:`, `chore:` (match existing repo style — see `git log --oneline`).

---

## Task 1: Add deps + skeletal modules

**Files:**
- Modify: `mix.exs`
- Create: `lib/stream_closed_captioner_phoenix/observability.ex`
- Create: `lib/stream_closed_captioner_phoenix/observability/metrics.ex`

- [ ] **Step 1: Add `prom_ex` and `logger_json` to `mix.exs` deps list**

Open `mix.exs`. In the `defp deps do [...]` block, alongside `{:new_relic_agent, "~> 1.30"}`, add:

```elixir
{:prom_ex, "~> 1.10"},
{:logger_json, "~> 6.0"},
```

- [ ] **Step 2: Fetch deps**

Run: `mix deps.get`
Expected: both new packages are downloaded; no errors.

- [ ] **Step 3: Create skeletal `Observability` module**

Create `lib/stream_closed_captioner_phoenix/observability.ex`:

```elixir
defmodule StreamClosedCaptionerPhoenix.Observability do
  @moduledoc """
  Entry points for the caption-flow observability layer.

  - `attach_logger_handlers/0` is called from `Application.start/2` to
    install the `:telemetry` handler that emits structured log lines.
  - `measure_active_channels/0` is invoked periodically by Prom_Ex to
    publish the active-channels gauge.
  """

  alias StreamClosedCaptionerPhoenix.Observability.LoggerHandler
  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  @spec attach_logger_handlers() :: :ok
  def attach_logger_handlers do
    LoggerHandler.attach()
  end

  @spec measure_active_channels() :: :ok
  def measure_active_channels do
    count = "active_channels" |> UserTracker.list() |> length()
    :telemetry.execute([:scc, :captions, :active_channels, :measure], %{count: count}, %{})
    :ok
  end
end
```

- [ ] **Step 4: Create skeletal `Observability.Metrics` module**

Create `lib/stream_closed_captioner_phoenix/observability/metrics.ex`:

```elixir
defmodule StreamClosedCaptionerPhoenix.Observability.Metrics do
  @moduledoc """
  Single source of truth for the `Telemetry.Metrics` list consumed by
  both LiveDashboard (`metrics/0`) and Prom_Ex (`event_metrics/0` +
  `polling_metrics/0`).
  """

  import Telemetry.Metrics

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics, do: event_metrics() ++ polling_metrics() ++ legacy_metrics()

  @spec event_metrics() :: [Telemetry.Metrics.t()]
  def event_metrics, do: []

  @spec polling_metrics() :: [Telemetry.Metrics.t()]
  def polling_metrics, do: []

  defp legacy_metrics, do: []
end
```

The empty lists are stubs; later tasks populate them.

- [ ] **Step 5: Create skeletal `LoggerHandler` module so `Observability.attach_logger_handlers/0` compiles**

Create `lib/stream_closed_captioner_phoenix/observability/logger_handler.ex`:

```elixir
defmodule StreamClosedCaptionerPhoenix.Observability.LoggerHandler do
  @moduledoc """
  Telemetry → Logger bridge. Attached at boot via
  `StreamClosedCaptionerPhoenix.Observability.attach_logger_handlers/0`.
  Clauses are added in Task 17.
  """

  @spec attach() :: :ok
  def attach, do: :ok
end
```

- [ ] **Step 6: Compile**

Run: `mix compile --warnings-as-errors`
Expected: clean compile, no warnings, no errors.

- [ ] **Step 7: Commit**

```bash
git add mix.exs mix.lock lib/stream_closed_captioner_phoenix/observability.ex lib/stream_closed_captioner_phoenix/observability/metrics.ex lib/stream_closed_captioner_phoenix/observability/logger_handler.ex
git commit -m "feat: add observability deps and skeletal modules"
```

---

## Task 2: Telemetry capture helper

**Files:**
- Create: `test/support/telemetry_capture.ex`

- [ ] **Step 1: Create the helper**

Create `test/support/telemetry_capture.ex`:

```elixir
defmodule StreamClosedCaptionerPhoenix.TelemetryCapture do
  @moduledoc """
  Attaches a `:telemetry` handler for the duration of one ExUnit test.
  Captured events are sent to the test process mailbox as
  `{:telemetry, name, measurements, metadata}` tuples, so tests can
  use `assert_receive/2` directly.
  """

  @spec attach([list(atom())]) :: :ok
  def attach(events) when is_list(events) do
    ref = make_ref()
    pid = self()
    id = "test-capture-#{inspect(ref)}"

    :telemetry.attach_many(
      id,
      events,
      fn name, measurements, metadata, _config ->
        send(pid, {:telemetry, name, measurements, metadata})
      end,
      nil
    )

    ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(id) end)
    :ok
  end
end
```

- [ ] **Step 2: Compile (test env)**

Run: `MIX_ENV=test mix compile --warnings-as-errors`
Expected: clean. (test/support is on the test elixirc path per `mix.exs`.)

- [ ] **Step 3: Commit**

```bash
git add test/support/telemetry_capture.ex
git commit -m "test: add TelemetryCapture helper"
```

---

## Task 3: Pipeline span — `:default` path (TDD)

**Files:**
- Create: `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex` — wrap `pipeline_to(:default, …)` in `:telemetry.span/3`

- [ ] **Step 1: Write failing test**

Create `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`:

```elixir
defmodule StreamClosedCaptionerPhoenix.CaptionsPipelineTelemetryTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  import Mox
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline
  alias StreamClosedCaptionerPhoenix.TelemetryCapture

  setup :verify_on_exit!

  describe "[:scc, :captions, :pipeline, …] for :default path" do
    test "emits :stop with result: :ok and expected metadata on success" do
      TelemetryCapture.attach([
        [:scc, :captions, :pipeline, :start],
        [:scc, :captions, :pipeline, :stop]
      ])

      user = insert(:user)

      assert {:ok, _payload} =
               CaptionsPipeline.pipeline_to(:default, user, %{
                 "interim" => "Hello",
                 "final" => "World",
                 "session" => "abc123"
               })

      assert_receive {:telemetry, [:scc, :captions, :pipeline, :start], _, %{destination: :default}}

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :stop],
                      %{duration: duration},
                      %{destination: :default, result: :ok, user_id: uid, text_length: 5}}

      assert duration > 0
      assert uid == user.id
    end

    test "emits :stop with result: :error when stream settings are missing" do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :stop]])

      ghost_user = %StreamClosedCaptionerPhoenix.Accounts.User{id: 0}

      assert {:error, "Stream settings not found"} =
               CaptionsPipeline.pipeline_to(:default, ghost_user, %{
                 "interim" => "x",
                 "final" => "y",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :stop],
                      %{duration: _},
                      %{destination: :default, result: :error, error_reason: _}}
    end
  end
end
```

- [ ] **Step 2: Run test, verify it fails**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
Expected: both tests fail with `assert_receive` timeout (no event matched).

- [ ] **Step 3: Wrap `pipeline_to(:default, …)` in `:telemetry.span/3`**

In `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`, replace the `pipeline_to(:default, …)` clause:

```elixir
@trace :pipeline_to
def pipeline_to(:default, %User{} = user, message) do
  metadata = %{
    destination: :default,
    user_id: user.id,
    text_length: String.length(Map.get(message, "final", "")),
    pirate_mode: false,
    language: nil,
    result: nil,
    error_reason: nil
  }

  :telemetry.span([:scc, :captions, :pipeline], metadata, fn ->
    case do_pipeline_default(user, message) do
      {:ok, payload} = ok ->
        {ok, %{metadata | result: :ok, pirate_mode: payload_pirate?(payload, user)}}

      {:error, reason} = err ->
        {err, %{metadata | result: :error, error_reason: reason}}
    end
  end)
end

defp do_pipeline_default(%User{} = user, message) do
  with {:ok, stream_settings} <- Settings.get_stream_settings_by_user_id(user.id) do
    payload =
      CaptionsPayload.new(message)
      |> apply_censoring(stream_settings)
      |> apply_pirate_mode(stream_settings)

    {:ok, payload}
  else
    {:error, _} -> {:error, "Stream settings not found"}
  end
end

defp payload_pirate?(_payload, _user), do: false
```

Note: `payload_pirate?/2` is a placeholder that returns `false`. The `pirate_mode` metadata bool gets populated more meaningfully when we instrument settings access — out of scope here; leaving `false` until/unless a follow-up needs it.

- [ ] **Step 4: Run tests, verify both pass**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
Expected: both tests pass.

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`
Expected: existing pipeline tests still pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/captions_pipeline.ex test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs
git commit -m "feat(captions): emit :scc.captions.pipeline span for :default path"
```

---

## Task 4: Pipeline span — `:twitch` path + configurable translation timeout (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex` — `:twitch` clause
- Modify: `config/test.exs` — set `translation_task_timeout_ms: 50`

- [ ] **Step 1: Add failing tests for `:twitch`**

Append to `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs` inside the `describe` block (or in a new describe):

```elixir
  describe "[:scc, :captions, :pipeline, …] for :twitch path" do
    setup do
      Application.put_env(:stream_closed_captioner_phoenix, :translation_task_timeout_ms, 50)
      on_exit(fn ->
        Application.delete_env(:stream_closed_captioner_phoenix, :translation_task_timeout_ms)
      end)
      :ok
    end

    test "emits :stop with destination: :twitch on success" do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :stop]])

      user = insert(:user)

      assert {:ok, _} =
               CaptionsPipeline.pipeline_to(:twitch, user, %{
                 "interim" => "x",
                 "final" => "y",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :stop],
                      _measurements,
                      %{destination: :twitch, result: :ok, user_id: uid}}

      assert uid == user.id
    end

    test "emits translation timeout event when the translation Task is shut down" do
      TelemetryCapture.attach([[:scc, :captions, :translation, :timeout]])

      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 5000, user: nil),
          translate_languages: [build(:translate_language, language: "es")]
        )

      # Force the Azure mock to sleep longer than the configured 50ms timeout.
      # `Task.async` inherits Mox expectations via $callers (Mox >= 1.0).
      Mox.stub(Azure.MockCognitive, :translate, fn _from, _to, _text ->
        :timer.sleep(200)
        {:ok, %Azure.Cognitive.Translations{translations: %{"es" => "hola"}}}
      end)

      uid = user.id

      assert {:ok, _} =
               CaptionsPipeline.pipeline_to(:twitch, user, %{
                 "interim" => "x",
                 "final" => "Hello",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :translation, :timeout],
                      %{duration_ms: 50},
                      %{user_id: ^uid}},
                     1_000
    end
  end
```

(The duplicate `uid` reference in the timeout test is intentional to keep the binding in scope; clean as you implement.)

- [ ] **Step 2: Run tests, verify they fail**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
Expected: the two new tests fail (`:twitch` clause not wrapped yet, no timeout event emitted).

- [ ] **Step 3: Wrap `:twitch` clause + make timeout configurable + emit timeout event**

In `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`, replace `pipeline_to(:twitch, …)` and add a helper:

```elixir
@translation_timeout_default_ms 3_000

@trace :pipeline_to
def pipeline_to(:twitch, %User{} = user, message) do
  metadata = %{
    destination: :twitch,
    user_id: user.id,
    text_length: String.length(Map.get(message, "final", "")),
    pirate_mode: false,
    language: nil,
    result: nil,
    error_reason: nil
  }

  :telemetry.span([:scc, :captions, :pipeline], metadata, fn ->
    case do_pipeline_twitch(user, message) do
      {:ok, payload} = ok -> {ok, %{metadata | result: :ok}}
      {:error, reason} = err -> {err, %{metadata | result: :error, error_reason: reason}}
    end
  end)
end

defp do_pipeline_twitch(%User{} = user, message) do
  with {:ok, stream_settings} <- Settings.get_stream_settings_by_user_id(user.id) do
    censored =
      CaptionsPayload.new(message)
      |> apply_censoring(stream_settings)

    timeout_ms = translation_task_timeout_ms()
    task = Task.async(fn -> Translations.maybe_translate(censored, :final, user) end)

    translated =
      case Task.yield(task, timeout_ms) || Task.shutdown(task) do
        {:ok, result} ->
          result

        _ ->
          :telemetry.execute(
            [:scc, :captions, :translation, :timeout],
            %{duration_ms: timeout_ms},
            %{user_id: user.id}
          )

          Logger.warning("translation timed out",
            user_id: user.id,
            duration_ms: timeout_ms
          )

          censored
      end

    payload = apply_pirate_mode(translated, stream_settings)
    {:ok, payload}
  else
    {:error, _} -> {:error, "Stream settings not found"}
  end
end

defp translation_task_timeout_ms do
  Application.get_env(
    :stream_closed_captioner_phoenix,
    :translation_task_timeout_ms,
    @translation_timeout_default_ms
  )
end
```

- [ ] **Step 4: Update `config/test.exs`**

Append to `config/test.exs`:

```elixir
config :stream_closed_captioner_phoenix, translation_task_timeout_ms: 50
```

This shortens the default for any test that doesn't override.

- [ ] **Step 5: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/captions_pipeline.ex test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs config/test.exs
git commit -m "feat(captions): instrument :twitch pipeline + emit translation timeout"
```

---

## Task 5: Pipeline span — `:zoom` path (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex` — `:zoom` clause

- [ ] **Step 1: Add failing test**

Append a new `describe` block to the telemetry test file:

```elixir
  describe "[:scc, :captions, :pipeline, …] for :zoom path" do
    test "emits :stop with destination: :zoom and result: :error on invalid URL" do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :stop]])

      user = insert(:user)

      assert {:error, :invalid_zoom_url} =
               CaptionsPipeline.pipeline_to(:zoom, user, %{
                 "interim" => "x",
                 "final" => "y",
                 "session" => "abc",
                 "zoom" => %{"url" => "http://evil.example.com", "seq" => 1}
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :stop],
                      _measurements,
                      %{destination: :zoom, result: :error, error_reason: :invalid_zoom_url}}
    end
  end
```

- [ ] **Step 2: Run, verify failure**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
Expected: new test fails (no event emitted from `:zoom` clause).

- [ ] **Step 3: Wrap `:zoom` clause**

Replace `pipeline_to(:zoom, …)`:

```elixir
@trace :pipeline_to
def pipeline_to(:zoom, %User{} = user, message) do
  metadata = %{
    destination: :zoom,
    user_id: user.id,
    text_length: String.length(Map.get(message, "final", "")),
    pirate_mode: false,
    language: nil,
    result: nil,
    error_reason: nil
  }

  :telemetry.span([:scc, :captions, :pipeline], metadata, fn ->
    case do_pipeline_zoom(user, message) do
      {:ok, payload} = ok -> {ok, %{metadata | result: :ok}}
      {:error, reason} = err -> {err, %{metadata | result: :error, error_reason: reason}}
    end
  end)
end

defp do_pipeline_zoom(%User{} = user, message) do
  with {:ok, stream_settings} <- Settings.get_stream_settings_by_user_id(user.id) do
    params = %Zoom.Params{
      seq: get_in(message, ["zoom", "seq"]),
      lang: stream_settings.language
    }

    payload =
      CaptionsPayload.new(message)
      |> apply_users_blocklist_for(:final, stream_settings)
      |> maybe_additional_censoring_for(:final, stream_settings)
      |> maybe_pirate_mode_for(:final, stream_settings)

    zoom_text = Map.get(payload, :final)

    with {:ok, url} <- validate_zoom_url(get_in(message, ["zoom", "url"])) do
      case Zoom.send_captions_to(url, zoom_text, params) do
        {:ok, %HTTPoison.Response{status_code: 200}} ->
          {:ok, payload}

        {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
          Logger.warning("zoom delivery rejected", http_status: code, body: inspect(body))
          {:error, body}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.warning("zoom delivery http error", reason: inspect(reason))
          {:error, reason}
      end
    end
  else
    {:error, _} -> {:error, "Stream settings not found"}
  end
end
```

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/captions_pipeline.ex test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs
git commit -m "feat(captions): instrument :zoom pipeline path"
```

---

## Task 6: Censored event (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex` — `apply_users_blocklist_for/3` to emit count

- [ ] **Step 1: Add failing test**

```elixir
  describe "[:scc, :captions, :pipeline, :censored]" do
    test "emits :censored with blocked_count when blocklist matches" do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :censored]])

      user =
        insert(:user,
          stream_settings:
            build(:stream_settings, filter_profanity: true, blocklist: ["poopy"])
        )

      assert {:ok, _} =
               CaptionsPipeline.pipeline_to(:default, user, %{
                 "interim" => "Hello poopy head",
                 "final" => "Friend",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :censored],
                      %{blocked_count: count},
                      %{destination: :default, user_id: uid, key: :interim}}
                     when count > 0

      assert uid == user.id
    end
  end
```

- [ ] **Step 2: Run, verify failure**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
Expected: new test fails.

- [ ] **Step 3: Emit `:censored` event**

In `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`, replace `apply_users_blocklist_for/3` and thread destination/user through `apply_censoring/2`:

```elixir
defp apply_censoring(payload, %StreamSettings{} = stream_settings, destination, user_id) do
  payload
  |> apply_users_blocklist_for(:interim, stream_settings, destination, user_id)
  |> apply_users_blocklist_for(:final, stream_settings, destination, user_id)
  |> maybe_additional_censoring_for(:interim, stream_settings)
  |> maybe_additional_censoring_for(:final, stream_settings)
end

defp apply_users_blocklist_for(payload, key, stream_settings, destination, user_id) do
  before_text = Map.get(payload, key) || ""
  after_text = Profanity.censor_from_blocklist(stream_settings, before_text)
  blocked = count_blocked(before_text, after_text)

  if blocked > 0 do
    :telemetry.execute(
      [:scc, :captions, :pipeline, :censored],
      %{blocked_count: blocked},
      %{destination: destination, user_id: user_id, key: key}
    )
  end

  Map.put(payload, key, after_text)
end

defp count_blocked(before_text, after_text) do
  # Profanity.censor_from_blocklist replaces words with "*****" — count occurrences.
  before_words = String.split(before_text || "", ~r/\s+/, trim: true)
  after_words = String.split(after_text || "", ~r/\s+/, trim: true)
  Enum.count(Enum.zip(before_words, after_words), fn {b, a} -> b != a end)
end
```

Update the three call sites (`do_pipeline_default`, `do_pipeline_twitch`, `do_pipeline_zoom`) to pass `destination` and `user.id` through to `apply_censoring/4`. For Zoom (which inlined the censoring step), call `apply_users_blocklist_for(:final, stream_settings, :zoom, user.id)` explicitly with the new arity.

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/captions_pipeline.ex test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs
git commit -m "feat(captions): emit :censored event with blocked_count"
```

---

## Task 7: Pirate mode `:stop` event (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex` — wrap `maybe_pirate_mode_for/3`

- [ ] **Step 1: Add failing test**

```elixir
  describe "[:scc, :captions, :pirate_mode, :stop]" do
    test "emits :stop with result: :ok when pirate mode succeeds" do
      TelemetryCapture.attach([[:scc, :captions, :pirate_mode, :stop]])

      user =
        insert(:user, stream_settings: build(:stream_settings, pirate_mode: true))

      assert {:ok, _} =
               CaptionsPipeline.pipeline_to(:default, user, %{
                 "interim" => "Hello",
                 "final" => "Friend",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pirate_mode, :stop],
                      %{duration: _},
                      %{user_id: uid, key: :interim, result: :ok}}

      assert uid == user.id
    end
  end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
Expected: new test fails.

- [ ] **Step 3: Wrap pirate-mode helper**

Update `maybe_pirate_mode_for/3` to use `:telemetry.span/3`. Thread `user_id` through `apply_pirate_mode/2` by giving it an additional arg.

```elixir
defp apply_pirate_mode(payload, %StreamSettings{} = stream_settings, user_id) do
  payload
  |> maybe_pirate_mode_for(:interim, stream_settings, user_id)
  |> maybe_pirate_mode_for(:final, stream_settings, user_id)
end

defp maybe_pirate_mode_for(payload, key, %StreamSettings{pirate_mode: true}, user_id) do
  metadata = %{user_id: user_id, key: key, result: nil}

  :telemetry.span([:scc, :captions, :pirate_mode], metadata, fn ->
    case TalkLikeAX.translate(Map.get(payload, key)) do
      {:ok, text} ->
        {Map.put(payload, key, text), %{metadata | result: :ok}}

      {:error, reason} ->
        Logger.warning("pirate mode translation failed", reason: inspect(reason))
        {payload, %{metadata | result: :error}}
    end
  end)
end

defp maybe_pirate_mode_for(payload, _key, _stream_settings, _user_id), do: payload
```

Update both call sites (`apply_pirate_mode/2` becomes `apply_pirate_mode/3`) inside `do_pipeline_default` and `do_pipeline_twitch`, and the inline call in `do_pipeline_zoom` (`maybe_pirate_mode_for(:final, stream_settings, user.id)`).

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/captions_pipeline.ex test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs
git commit -m "feat(captions): instrument pirate mode"
```

---

## Task 8: Translations span + `bits_debit` (TDD)

**Files:**
- Create: `test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex` — wrap `maybe_translate/3` in span; emit `bits_debit`

- [ ] **Step 1: Write failing tests**

Create `test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`:

```elixir
defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.TranslationsTelemetryTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: false

  import Mox
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations
  alias StreamClosedCaptionerPhoenix.TelemetryCapture

  setup :verify_on_exit!

  setup do
    FunWithFlags.disable(:gemini_translations)
    on_exit(fn -> FunWithFlags.disable(:gemini_translations) end)
    :ok
  end

  test "emits :stop with result: :skipped_no_languages when user has none configured" do
    TelemetryCapture.attach([[:scc, :captions, :translation, :stop]])

    user = insert(:user, translate_languages: [])
    payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}

    Translations.maybe_translate(payload, :final, user)

    assert_receive {:telemetry,
                    [:scc, :captions, :translation, :stop],
                    _,
                    %{user_id: _, result: :skipped_no_languages, provider: :azure}}
  end

  test "emits :stop with result: :skipped_no_balance when balance < 500 and no active debit" do
    TelemetryCapture.attach([[:scc, :captions, :translation, :stop]])

    user =
      insert(:user,
        bits_balance: build(:bits_balance, balance: 0, user: nil),
        translate_languages: [build(:translate_language, language: "es")]
      )

    payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
    Translations.maybe_translate(payload, :final, user)

    assert_receive {:telemetry,
                    [:scc, :captions, :translation, :stop],
                    _,
                    %{result: :skipped_no_balance}}
  end

  test "emits :stop with result: :ok and :bits_debit when activation succeeds" do
    TelemetryCapture.attach([
      [:scc, :captions, :translation, :stop],
      [:scc, :captions, :translation, :bits_debit]
    ])

    user =
      insert(:user,
        bits_balance: build(:bits_balance, balance: 5000, user: nil),
        translate_languages: [build(:translate_language, language: "es")]
      )

    Mox.expect(Azure.MockCognitive, :translate, fn _from, _to, _text ->
      {:ok, %Azure.Cognitive.Translations{translations: %{"es" => "hola"}}}
    end)

    payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
    Translations.maybe_translate(payload, :final, user)

    assert_receive {:telemetry,
                    [:scc, :captions, :translation, :bits_debit],
                    %{count: 1},
                    %{user_id: _}}

    assert_receive {:telemetry,
                    [:scc, :captions, :translation, :stop],
                    %{duration: _},
                    %{result: :ok, provider: :azure, to_count: 1}}
  end
end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
Expected: all three tests fail.

- [ ] **Step 3: Wrap `maybe_translate/3` in span; emit `bits_debit`**

Replace `lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex` body (keep aliases and `use`):

```elixir
@trace :maybe_translate
def maybe_translate(payload, key, %User{} = user) do
  provider = if FunWithFlags.enabled?(:gemini_translations, for: user), do: :gemini, else: :azure
  text = Map.get(payload, key)

  metadata = %{
    user_id: user.id,
    provider: provider,
    from_lang: nil,
    to_langs: [],
    to_count: 0,
    result: nil,
    error_reason: nil
  }

  :telemetry.span([:scc, :captions, :translation], metadata, fn ->
    {payload_out, result_meta} = do_maybe_translate(payload, text, user, provider)
    {payload_out, Map.merge(metadata, result_meta)}
  end)
end

defp do_maybe_translate(payload, text, %User{} = user, provider) do
  cond do
    Bits.user_active_debit_exists?(user.id) ->
      perform_translation(payload, text, user, provider)

    true ->
      to_languages = Settings.get_formatted_translate_languages_by_user(user.id)
      bits_balance = Bits.get_bits_balance_for_user(user)

      cond do
        Enum.empty?(to_languages) ->
          {payload, %{result: :skipped_no_languages}}

        bits_balance.balance < 500 ->
          {payload, %{result: :skipped_no_balance}}

        true ->
          activate_then_translate(payload, text, user, provider)
      end
  end
end

defp activate_then_translate(payload, text, user, provider) do
  case Bits.activate_translations_for(user) do
    {:ok, _} ->
      :telemetry.execute(
        [:scc, :captions, :translation, :bits_debit],
        %{count: 1},
        %{user_id: user.id}
      )

      perform_translation(payload, text, user, provider)

    other ->
      {payload, %{result: :error, error_reason: inspect(other)}}
  end
end

defp perform_translation(payload, text, user, provider) do
  case get_translations(user, text, provider) do
    {:ok, %Translations{translations: translations}} ->
      {%{payload | translations: translations},
       %{result: :ok, to_count: map_size(translations)}}

    {:error, reason} ->
      Logger.warning("translation failed", user_id: user.id, reason: inspect(reason))
      {payload, %{result: :error, error_reason: inspect(reason)}}
  end
end

defp get_translations(%User{} = user, text, provider) do
  {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(user.id)
  from_language = stream_settings.language

  to_languages =
    Settings.get_formatted_translate_languages_by_user(user.id) |> Map.keys() |> Enum.sort()

  case provider do
    :gemini -> Gemini.perform_translations(from_language, to_languages, text)
    :azure -> Azure.perform_translations(from_language, to_languages, text)
  end
end
```

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs test/stream_closed_captioner_phoenix/captions_pipeline/translations_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs
git commit -m "feat(captions): instrument translations + emit bits_debit event"
```

---

## Task 9: Outbound — Azure span (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/services/azure.ex` — wrap `perform_translations/3`

- [ ] **Step 1: Add failing test**

Append to the translations telemetry test file:

```elixir
  test "emits [:scc, :outbound, :azure_translation, :stop] when Azure call succeeds" do
    TelemetryCapture.attach([[:scc, :outbound, :azure_translation, :stop]])

    Mox.expect(Azure.MockCognitive, :translate, fn _from, to, _text ->
      {:ok, %Azure.Cognitive.Translations{translations: Map.new(to, &{&1, "hola"})}}
    end)

    assert {:ok, _} = Azure.perform_translations("en", ["es"], "Hello")

    assert_receive {:telemetry,
                    [:scc, :outbound, :azure_translation, :stop],
                    %{duration: _},
                    %{from_lang: "en", to_count: 1, result: :ok}}
  end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
Expected: new test fails.

- [ ] **Step 3: Wrap `Azure.perform_translations/3`**

Replace `lib/stream_closed_captioner_phoenix/services/azure.ex`:

```elixir
defmodule Azure do
  use Nebulex.Caching

  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :azure_cognitive_client)

  @spec perform_translations(String.t(), [String.t()], String.t()) ::
          {:ok, Azure.Cognitive.Translations.t()} | {:error, term()}
  def perform_translations(from_language, to_languages, text) do
    metadata = %{
      from_lang: from_language,
      to_count: length(to_languages),
      result: nil,
      http_status: nil,
      error_reason: nil
    }

    :telemetry.span([:scc, :outbound, :azure_translation], metadata, fn ->
      case api_client().translate(from_language, to_languages, text) do
        {:ok, _} = ok -> {ok, %{metadata | result: :ok}}
        {:error, reason} = err -> {err, %{metadata | result: :error, error_reason: inspect(reason)}}
      end
    end)
  end
end
```

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/services/azure.ex test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs
git commit -m "feat(outbound): instrument Azure.perform_translations"
```

---

## Task 10: Outbound — Gemini span (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/services/gemini.ex`

- [ ] **Step 1: Add failing test**

Append to translations telemetry test file:

```elixir
  test "emits [:scc, :outbound, :gemini_translation, :stop] when Gemini call succeeds" do
    TelemetryCapture.attach([[:scc, :outbound, :gemini_translation, :stop]])

    Mox.expect(Gemini.MockCognitive, :translate, fn _from, _to, _text ->
      {:ok, %Azure.Cognitive.Translations{translations: %{"es" => "hola"}}}
    end)

    assert {:ok, _} = Gemini.perform_translations("en", ["es"], "Hello")

    assert_receive {:telemetry,
                    [:scc, :outbound, :gemini_translation, :stop],
                    %{duration: _},
                    %{from_lang: "en", to_count: 1, result: :ok}}
  end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
Expected: new test fails.

- [ ] **Step 3: Wrap `Gemini.perform_translations/3`**

Replace `lib/stream_closed_captioner_phoenix/services/gemini.ex`:

```elixir
defmodule Gemini do
  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :gemini_cognitive_client)

  @spec perform_translations(String.t(), [String.t()], String.t()) ::
          {:ok, Azure.Cognitive.Translations.t()} | {:error, term()}
  def perform_translations(from_language, to_languages, text) do
    metadata = %{
      from_lang: from_language,
      to_count: length(to_languages),
      result: nil,
      http_status: nil,
      error_reason: nil
    }

    :telemetry.span([:scc, :outbound, :gemini_translation], metadata, fn ->
      case api_client().translate(from_language, to_languages, text) do
        {:ok, _} = ok -> {ok, %{metadata | result: :ok}}
        {:error, reason} = err -> {err, %{metadata | result: :error, error_reason: inspect(reason)}}
      end
    end)
  end
end
```

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/services/gemini.ex test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs
git commit -m "feat(outbound): instrument Gemini.perform_translations"
```

---

## Task 11: Outbound — Zoom span (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/services/zoom.ex`

- [ ] **Step 1: Add failing test**

Append to the pipeline telemetry test file:

```elixir
  describe "[:scc, :outbound, :zoom_delivery, …]" do
    test "emits :stop with http_status and result on success" do
      TelemetryCapture.attach([[:scc, :outbound, :zoom_delivery, :stop]])

      # Bypass is already in deps (mix.exs: {:bypass, "~> 2.1.0"}).
      # `Zoom.send_captions_to/3` itself does NOT validate URL scheme —
      # that's done by the pipeline. So we can point it at localhost.
      bypass = Bypass.open()

      Bypass.expect(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "ok")
      end)

      url = "http://localhost:#{bypass.port}/?token=x"

      {:ok, %HTTPoison.Response{status_code: 200}} =
        Zoom.send_captions_to(url, "hello", %Zoom.Params{seq: 1, lang: "en"})

      assert_receive {:telemetry,
                      [:scc, :outbound, :zoom_delivery, :stop],
                      %{duration: _},
                      %{http_status: 200, result: :ok}}
    end
  end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
Expected: new test fails.

- [ ] **Step 3: Wrap `Zoom.send_captions_to/3`**

Replace `lib/stream_closed_captioner_phoenix/services/zoom.ex`:

```elixir
defmodule Zoom do
  alias NewRelic.Instrumented.HTTPoison

  def send_captions_to(url, text, %Zoom.Params{seq: seq, lang: lang}) do
    metadata = %{
      http_status: nil,
      result: nil,
      error_reason: nil,
      host: host_of(url)
    }

    body_bytes = byte_size(text)

    headers = [
      {"Accept", "*/*"},
      {"Content-Type", "text/plain"}
    ]

    full_url = url <> "&" <> URI.encode_query(%{seq: seq, lang: lang})

    :telemetry.span([:scc, :outbound, :zoom_delivery],
      Map.put(metadata, :body_bytes, body_bytes),
      fn ->
        case HTTPoison.post(full_url, text, headers) do
          {:ok, %HTTPoison.Response{status_code: status}} = ok ->
            {ok, %{metadata | http_status: status, result: result_for(status)}}

          {:error, %HTTPoison.Error{reason: reason}} = err ->
            {err, %{metadata | result: :error, error_reason: inspect(reason)}}
        end
      end
    )
  end

  defp host_of(url) do
    case URI.parse(url) do
      %URI{host: host} -> host
      _ -> nil
    end
  end

  defp result_for(status) when status in 200..299, do: :ok
  defp result_for(_), do: :error
end
```

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/services/zoom.ex test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs
git commit -m "feat(outbound): instrument Zoom.send_captions_to"
```

---

## Task 12: Channel join + leave events (TDD)

**Files:**
- Create: `test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex` — emit on join, add `terminate/2`

- [ ] **Step 1: Write failing tests**

Create `test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`:

```elixir
defmodule StreamClosedCaptionerPhoenixWeb.CaptionsChannelTelemetryTest do
  use StreamClosedCaptionerPhoenixWeb.ChannelCase

  import StreamClosedCaptionerPhoenix.Factory
  alias StreamClosedCaptionerPhoenix.TelemetryCapture

  test "join/3 emits [:scc, :captions, :channel, :join] with result: :ok" do
    TelemetryCapture.attach([[:scc, :captions, :channel, :join]])

    stream_settings = insert(:stream_settings, user: build(:bare_user))
    user = stream_settings.user

    {:ok, _, _socket} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: user})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{user.id}"
      )

    assert_receive {:telemetry,
                    [:scc, :captions, :channel, :join],
                    %{count: 1},
                    %{user_id: uid, result: :ok}}

    assert uid == user.id
  end

  test "join/3 emits [:scc, :captions, :channel, :join] with result: :unauthorized" do
    TelemetryCapture.attach([[:scc, :captions, :channel, :join]])

    authorized = insert(:user)
    intruder = insert(:user, stream_settings: nil)

    {:error, %{reason: "unauthorized"}} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: intruder})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{authorized.id}"
      )

    assert_receive {:telemetry,
                    [:scc, :captions, :channel, :join],
                    %{count: 1},
                    %{result: :unauthorized}}
  end

  test "terminate/2 emits [:scc, :captions, :channel, :leave]" do
    TelemetryCapture.attach([[:scc, :captions, :channel, :leave]])

    stream_settings = insert(:stream_settings, user: build(:bare_user))
    user = stream_settings.user

    {:ok, _, socket} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: user})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{user.id}"
      )

    Process.unlink(socket.channel_pid)
    close(socket)

    assert_receive {:telemetry,
                    [:scc, :captions, :channel, :leave],
                    %{count: 1},
                    %{user_id: uid}}

    assert uid == user.id
  end
end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
Expected: all three tests fail.

- [ ] **Step 3: Emit join + add terminate**

In `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`:

Replace `join/3`:

```elixir
@impl true
def join("captions:" <> user_id, _payload, socket) do
  user = socket.assigns.current_user

  if authorized?(socket, user_id) do
    :telemetry.execute(
      [:scc, :captions, :channel, :join],
      %{count: 1},
      %{user_id: user.id, result: :ok}
    )

    send(self(), :after_join)
    {:ok, socket}
  else
    :telemetry.execute(
      [:scc, :captions, :channel, :join],
      %{count: 1},
      %{user_id: user.id, result: :unauthorized}
    )

    {:error, %{reason: "unauthorized"}}
  end
end
```

Add `terminate/2` (after the last `handle_in` clause):

```elixir
@impl true
def terminate(reason, socket) do
  user_id = get_in(socket.assigns, [:current_user, Access.key(:id)])

  :telemetry.execute(
    [:scc, :captions, :channel, :leave],
    %{count: 1},
    %{user_id: user_id, reason: inspect(reason)}
  )

  :ok
end
```

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs test/stream_closed_captioner_phoenix_web/channels/captions_channel_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs
git commit -m "feat(channel): emit join/leave telemetry events"
```

---

## Task 13: Channel publish event + `client_send_age_ms` (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`

- [ ] **Step 1: Add failing tests**

Append to the channel telemetry test file:

```elixir
  describe "[:scc, :captions, :channel, :publish]" do
    setup do
      stream_settings = insert(:stream_settings, user: build(:bare_user))
      user = stream_settings.user

      {:ok, _, socket} =
        StreamClosedCaptionerPhoenixWeb.UserSocket
        |> socket("user_id", %{current_user: user})
        |> subscribe_and_join(
          StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
          "captions:#{user.id}"
        )

      %{socket: socket, user: user}
    end

    test "emits with destination: :default when no zoom/twitch flags", %{socket: socket} do
      TelemetryCapture.attach([[:scc, :captions, :channel, :publish]])

      push(socket, "publishFinal", %{
        "interim" => "hi",
        "final" => "there",
        "session" => "abc"
      })

      assert_receive {:telemetry,
                      [:scc, :captions, :channel, :publish],
                      %{count: 1},
                      %{destination: :default, event: "publishFinal"}},
                     1_000
    end

    test "emits with destination: :twitch and client_send_age_ms when sentOn is present",
         %{socket: socket} do
      TelemetryCapture.attach([[:scc, :captions, :channel, :publish]])

      sent_on = DateTime.utc_now() |> DateTime.add(-2, :second) |> DateTime.to_iso8601()

      push(socket, "publishFinal", %{
        "interim" => "hi",
        "final" => "there",
        "session" => "abc",
        "twitch" => %{"enabled" => true},
        "sentOn" => sent_on
      })

      assert_receive {:telemetry,
                      [:scc, :captions, :channel, :publish],
                      %{count: 1, client_send_age_ms: age},
                      %{destination: :twitch}},
                     1_000

      assert age >= 1_500
    end

    test "active does NOT trigger pipeline events", %{socket: socket} do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :stop]])
      push(socket, "active", %{})
      refute_receive {:telemetry, [:scc, :captions, :pipeline, :stop], _, _}, 200
    end
  end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
Expected: new tests fail.

- [ ] **Step 3: Emit publish event from each `handle_in/3` clause**

Add a helper inside `CaptionsChannel`:

```elixir
defp emit_publish(event, payload, socket, destination) do
  user = socket.assigns.current_user
  sent_on = Map.get(payload, "sentOn")
  age = time_to_complete(sent_on)

  measurements =
    case sent_on do
      nil -> %{count: 1}
      _ -> %{count: 1, client_send_age_ms: age}
    end

  metadata = %{
    user_id: user.id,
    destination: destination,
    event: event,
    zoom_enabled: get_in(payload, ["zoom", "enabled"]) == true,
    twitch_enabled: get_in(payload, ["twitch", "enabled"]) == true
  }

  :telemetry.execute([:scc, :captions, :channel, :publish], measurements, metadata)
end
```

Insert calls at the top of each `handle_in/3` clause:

- `handle_in("publishFinal", %{"zoom" => %{"enabled" => true}} = payload, socket)` → `emit_publish("publishFinal", payload, socket, :zoom)`
- `handle_in(publish_state, %{"twitch" => %{"enabled" => true}} = payload, socket)` → `emit_publish(publish_state, payload, socket, :twitch)`
- `handle_in("active", payload, socket)` → `emit_publish("active", payload, socket, :none)` (count only, no pipeline trigger)
- `handle_in(publish_state, payload, socket)` (default) → `emit_publish(publish_state, payload, socket, :default)`

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs test/stream_closed_captioner_phoenix_web/channels/captions_channel_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs
git commit -m "feat(channel): emit :publish event with client_send_age_ms"
```

---

## Task 14: Channel reply span + `twitch_publish` event (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`

- [ ] **Step 1: Add failing tests**

Append:

```elixir
  describe "[:scc, :captions, :channel, :reply, :stop] and twitch_publish" do
    setup do
      stream_settings = insert(:stream_settings, user: build(:bare_user))
      user = stream_settings.user

      {:ok, _, socket} =
        StreamClosedCaptionerPhoenixWeb.UserSocket
        |> socket("user_id", %{current_user: user})
        |> subscribe_and_join(
          StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
          "captions:#{user.id}"
        )

      %{socket: socket, user: user}
    end

    test "wraps handle_in in :reply :stop span", %{socket: socket} do
      TelemetryCapture.attach([[:scc, :captions, :channel, :reply, :stop]])

      push(socket, "publishFinal", %{
        "interim" => "hi",
        "final" => "there",
        "session" => "abc"
      })

      assert_receive {:telemetry,
                      [:scc, :captions, :channel, :reply, :stop],
                      %{duration: _},
                      %{destination: :default, event: "publishFinal", result: :ok}},
                     1_000
    end

    test "emits :twitch_publish after Absinthe publish on twitch path", %{
      socket: socket,
      user: user
    } do
      TelemetryCapture.attach([[:scc, :outbound, :twitch_publish, :stop]])

      push(socket, "publishFinal", %{
        "interim" => "hi",
        "final" => "there",
        "session" => "abc",
        "twitch" => %{"enabled" => true}
      })

      assert_receive {:telemetry,
                      [:scc, :outbound, :twitch_publish, :stop],
                      %{count: 1},
                      %{user_id: uid}},
                     1_000

      assert uid == user.id
    end
  end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
Expected: new tests fail.

- [ ] **Step 3: Wrap `handle_in/3` bodies in a span; emit `twitch_publish`**

Add a private helper that runs the body inside `:telemetry.span/3`:

```elixir
defp with_reply_span(event, destination, socket, fun) do
  metadata = %{
    user_id: socket.assigns.current_user.id,
    destination: destination,
    event: event,
    result: nil
  }

  :telemetry.span([:scc, :captions, :channel, :reply], metadata, fn ->
    {reply, socket_out, result} = fun.()
    {{reply, socket_out}, %{metadata | result: result}}
  end)
end
```

Refactor each `handle_in/3` clause to call `with_reply_span/4`. Example for the twitch path:

```elixir
@trace :handle_in
def handle_in(publish_state, %{"twitch" => %{"enabled" => true}} = payload, socket)
    when publish_state != "active" do
  emit_publish(publish_state, payload, socket, :twitch)

  with_reply_span(publish_state, :twitch, socket, fn ->
    NewRelic.start_transaction("Captions", "twitch")
    sent_on_time = Map.get(payload, "sentOn")
    user = socket.assigns.current_user

    UserTracker.update(self(), "active_channels", user.uid, %{
      last_publish: System.system_time(:second)
    })

    case safe_pipeline_to(:twitch, user, payload) do
      {:ok, sent_payload} ->
        Absinthe.Subscription.publish(
          StreamClosedCaptionerPhoenixWeb.Endpoint,
          sent_payload,
          new_twitch_caption: user.uid
        )

        :telemetry.execute(
          [:scc, :outbound, :twitch_publish, :stop],
          %{count: 1},
          %{user_id: user.id, twitch_uid: user.uid}
        )

        new_relic_track(:ok, user, sent_on_time)
        {{:reply, {:ok, sent_payload}, socket}, socket, :ok}

      {:error, reason} ->
        Logger.error("twitch pipeline failed",
          user_id: user.id, reason: inspect(reason), destination: :twitch)

        new_relic_track(:error, user, sent_on_time)
        {{:reply, {:error, "Issue sending captions."}, socket}, socket, :error}
    end
  end)
  |> elem(0)
end
```

Apply the analogous refactor (return a `{reply, socket_out, result}` triple, wrap in `with_reply_span`, take `elem(0)` at the end) to the Zoom, default, and `"active"` clauses. The `"active"` clause's result is `:ok` and destination is `:none`.

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs test/stream_closed_captioner_phoenix_web/channels/captions_channel_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs
git commit -m "feat(channel): wrap handle_in in reply span + emit twitch_publish"
```

---

## Task 15: Channel `Logger.metadata` setup (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex` — set Logger.metadata on join + per-handle_in

- [ ] **Step 1: Add failing test that inspects the channel process's Logger metadata**

`Logger.metadata/0` is stored in the process dictionary under `:"$logger_metadata$"`. We can read it from outside the channel process via `Process.info/2`.

Append to the channel telemetry test file:

```elixir
  describe "Logger metadata" do
    test "join sets user_id and twitch_uid in Logger.metadata" do
      stream_settings = insert(:stream_settings, user: build(:bare_user))
      user = stream_settings.user

      {:ok, _, socket} =
        StreamClosedCaptionerPhoenixWeb.UserSocket
        |> socket("user_id", %{current_user: user})
        |> subscribe_and_join(
          StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
          "captions:#{user.id}"
        )

      {:dictionary, dict} = Process.info(socket.channel_pid, :dictionary)
      metadata = Keyword.get(dict, :"$logger_metadata$", [])

      assert Keyword.get(metadata, :user_id) == user.id
      assert Keyword.get(metadata, :twitch_uid) == user.uid
    end
  end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
Expected: new test fails (`user_id` not in metadata).

- [ ] **Step 3: Set `Logger.metadata` in join and each handle_in**

In `CaptionsChannel.join/3`'s `if authorized?` branch, before `send(self(), :after_join)`:

```elixir
Logger.metadata(user_id: user.id, twitch_uid: user.uid)
```

At the top of each `handle_in/3` clause (after `emit_publish`), add:

```elixir
Logger.metadata(destination: <destination_atom>)
```

For the `"active"` clause use `Logger.metadata(destination: :none)`.

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs test/stream_closed_captioner_phoenix_web/channels/captions_channel_test.exs`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs
git commit -m "feat(channel): bind user_id and destination to Logger.metadata"
```

---

## Task 16: Structured Logger config

**Files:**
- Modify: `config/dev.exs`
- Modify: `config/runtime.exs`

- [ ] **Step 1: Update `config/dev.exs`**

Find the existing Logger config block in `config/dev.exs` and replace/add:

```elixir
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :twitch_uid, :destination, :provider, :http_status]
```

- [ ] **Step 2: Update `config/runtime.exs` for prod JSON logging**

Inside the existing `if config_env() == :prod do … end` block, add (near the top):

```elixir
config :logger, :default_handler,
  formatter: {LoggerJSON.Formatters.Basic, metadata: :all}

config :logger, level: :info
```

- [ ] **Step 3: Compile in dev and prod-like env**

Run: `mix compile`
Run: `MIX_ENV=test mix compile`
Expected: clean.

- [ ] **Step 4: Run full test suite**

Run: `mix test`
Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add config/dev.exs config/runtime.exs
git commit -m "chore(logger): structured metadata format for dev + JSON formatter in prod"
```

---

## Task 17: `LoggerHandler` module + attach at boot (TDD)

**Files:**
- Create: `test/stream_closed_captioner_phoenix/observability/logger_handler_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/observability/logger_handler.ex`
- Modify: `lib/stream_closed_captioner_phoenix/application.ex` — call `Observability.attach_logger_handlers/0`

- [ ] **Step 1: Write failing tests**

Create `test/stream_closed_captioner_phoenix/observability/logger_handler_test.exs`:

```elixir
defmodule StreamClosedCaptionerPhoenix.Observability.LoggerHandlerTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias StreamClosedCaptionerPhoenix.Observability.LoggerHandler

  setup do
    :ok = LoggerHandler.attach()
    on_exit(fn -> :telemetry.detach("scc-observability-error-logs") end)
    :ok
  end

  test "pipeline :stop with result: :error produces a structured Logger.error line" do
    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :pipeline, :stop],
          %{duration: 1_000_000},
          %{
            destination: :twitch,
            user_id: 42,
            result: :error,
            error_reason: :boom,
            text_length: 10,
            language: "en-US"
          }
        )
      end)

    assert log =~ "[error]"
    assert log =~ "caption pipeline returned error"
    assert log =~ "destination=twitch"
    assert log =~ "user_id=42"
  end

  test "pipeline :stop with result: :ok produces no log" do
    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :pipeline, :stop],
          %{duration: 1_000_000},
          %{destination: :default, result: :ok, user_id: 1, text_length: 5, language: nil}
        )
      end)

    refute log =~ "caption pipeline"
  end

  test "pipeline :exception event produces error log with formatted stacktrace" do
    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :pipeline, :exception],
          %{duration: 1_000_000},
          %{
            destination: :twitch,
            kind: :error,
            reason: %RuntimeError{message: "boom"},
            stacktrace: [{Mod, :fun, 0, [file: ~c"x.ex", line: 1]}],
            user_id: 99
          }
        )
      end)

    assert log =~ "[error]"
    assert log =~ "caption pipeline raised"
    assert log =~ "x.ex:1"
  end

  test "log line never contains azure_service_key value (PII guard)" do
    secret = "TOPSECRET-#{System.unique_integer()}"
    user = %StreamClosedCaptionerPhoenix.Accounts.User{id: 99, azure_service_key: secret}

    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :pipeline, :stop],
          %{duration: 1_000_000},
          %{
            destination: :twitch,
            user_id: user.id,
            user_struct: user,
            result: :error,
            error_reason: :boom,
            text_length: 5,
            language: "en"
          }
        )
      end)

    refute log =~ secret
  end

  test "translation :timeout produces a warning log" do
    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :translation, :timeout],
          %{duration_ms: 50},
          %{user_id: 1}
        )
      end)

    assert log =~ "[warning]"
    assert log =~ "translation timed out"
    assert log =~ "duration_ms=50"
  end
end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix/observability/logger_handler_test.exs`
Expected: most tests fail (`LoggerHandler.attach/0` is currently a no-op).

- [ ] **Step 3: Implement `LoggerHandler`**

Replace `lib/stream_closed_captioner_phoenix/observability/logger_handler.ex`:

```elixir
defmodule StreamClosedCaptionerPhoenix.Observability.LoggerHandler do
  @moduledoc """
  Telemetry → Logger bridge. Attached at boot via
  `StreamClosedCaptionerPhoenix.Observability.attach_logger_handlers/0`.

  Handler clauses extract scalar fields explicitly — they never
  `inspect` `%User{}` or `%StreamSettings{}` structs directly so that
  sensitive fields (e.g. `azure_service_key`) never appear in logs.
  """

  require Logger

  @handler_id "scc-observability-error-logs"

  @events [
    [:scc, :captions, :pipeline, :stop],
    [:scc, :captions, :pipeline, :exception],
    [:scc, :captions, :translation, :stop],
    [:scc, :captions, :translation, :exception],
    [:scc, :captions, :translation, :timeout],
    [:scc, :outbound, :zoom_delivery, :stop],
    [:scc, :outbound, :zoom_delivery, :exception],
    [:scc, :outbound, :azure_translation, :exception],
    [:scc, :outbound, :gemini_translation, :exception]
  ]

  def attach do
    :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle/4, nil)
    :ok
  end

  def handle([:scc, :captions, :pipeline, :stop], %{duration: d}, %{result: :error} = m, _) do
    Logger.error("caption pipeline returned error",
      duration_ms: native_to_ms(d),
      destination: m[:destination],
      error_reason: inspect(m[:error_reason]),
      user_id: m[:user_id],
      text_length: m[:text_length],
      language: m[:language]
    )
  end

  def handle([:scc, :captions, :pipeline, :stop], _, %{result: :ok}, _), do: :ok

  def handle([:scc, :captions, :pipeline, :exception], _, m, _) do
    Logger.error("caption pipeline raised",
      destination: m[:destination],
      kind: m[:kind],
      reason: Exception.format_banner(m[:kind], m[:reason]),
      stacktrace: Exception.format_stacktrace(m[:stacktrace]),
      user_id: m[:user_id]
    )
  end

  def handle([:scc, :captions, :translation, :stop], _, %{result: :error} = m, _) do
    Logger.warning("translation failed",
      user_id: m[:user_id],
      provider: m[:provider],
      error_reason: inspect(m[:error_reason])
    )
  end

  def handle([:scc, :captions, :translation, :stop], _, _, _), do: :ok

  def handle([:scc, :captions, :translation, :exception], _, m, _) do
    Logger.error("translation raised",
      provider: m[:provider],
      user_id: m[:user_id],
      reason: Exception.format_banner(m[:kind], m[:reason]),
      stacktrace: Exception.format_stacktrace(m[:stacktrace])
    )
  end

  def handle([:scc, :captions, :translation, :timeout], %{duration_ms: ms}, m, _) do
    Logger.warning("translation timed out", user_id: m[:user_id], duration_ms: ms)
  end

  def handle([:scc, :outbound, :zoom_delivery, :stop], _, %{result: :error} = m, _) do
    Logger.warning("zoom delivery rejected",
      user_id: m[:user_id],
      http_status: m[:http_status],
      error_reason: inspect(m[:error_reason]),
      host: m[:host]
    )
  end

  def handle([:scc, :outbound, :zoom_delivery, :stop], _, _, _), do: :ok

  def handle([:scc, :outbound, _service, :exception], _, m, _) do
    Logger.error("outbound translation raised",
      reason: Exception.format_banner(m[:kind], m[:reason]),
      stacktrace: Exception.format_stacktrace(m[:stacktrace])
    )
  end

  defp native_to_ms(duration), do: System.convert_time_unit(duration, :native, :millisecond)
end
```

- [ ] **Step 4: Wire `attach_logger_handlers/0` into the supervisor boot**

In `lib/stream_closed_captioner_phoenix/application.ex`, replace `start/2`'s body's tail:

```elixir
opts = [strategy: :one_for_one, name: StreamClosedCaptionerPhoenix.Supervisor]
result = Supervisor.start_link(children, opts)
StreamClosedCaptionerPhoenix.Observability.attach_logger_handlers()
result
```

- [ ] **Step 5: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/observability/logger_handler_test.exs`
Expected: all pass.

Run: `mix test`
Expected: full suite passes.

- [ ] **Step 6: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/observability/logger_handler.ex lib/stream_closed_captioner_phoenix/application.ex test/stream_closed_captioner_phoenix/observability/logger_handler_test.exs
git commit -m "feat(observability): LoggerHandler bridge + boot-time attach"
```

---

## Task 18: Rewrite remaining inline `Logger` calls to keyword-list form

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex`
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`

- [ ] **Step 1: Convert `pipeline.ex` URL-rejection logs**

In `validate_zoom_url/1` (or its replacement after earlier tasks), change:

```elixir
Logger.warning("Rejected non-HTTPS Zoom URL: #{inspect(uri.scheme)}")
```

to:

```elixir
Logger.warning("rejected zoom url",
  reason: :non_https_scheme,
  scheme: inspect(uri.scheme))
```

And similarly for the non-`.zoom.us` host case:

```elixir
Logger.warning("rejected zoom url",
  reason: :non_zoom_host,
  host: inspect(uri.host))
```

- [ ] **Step 2: Convert `translations.ex` Logger calls**

Where `Logger.warning("Translation failed for user #{user.id}: #{inspect(reason)}")` appears (now inside `perform_translation/4` after Task 8), confirm it reads:

```elixir
Logger.warning("translation failed",
  user_id: user.id,
  reason: inspect(reason))
```

If the wording is different, normalize.

- [ ] **Step 3: Confirm `captions_channel.ex` error logs are keyword-form**

The channel's `Logger.error` calls after Task 14 should already be keyword-form. Verify they read:

```elixir
Logger.error("twitch pipeline failed",
  user_id: user.id, reason: inspect(reason), destination: :twitch)
```

Repeat for zoom and default clauses (`destination: :zoom`, `destination: :default`).

- [ ] **Step 4: Run full test suite**

Run: `mix test`
Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/captions_pipeline.ex lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex
git commit -m "refactor(logging): convert inline Logger calls to structured keyword form"
```

---

## Task 19: Populate `Observability.Metrics` definitions (TDD)

**Files:**
- Create: `test/stream_closed_captioner_phoenix/observability/metrics_test.exs`
- Modify: `lib/stream_closed_captioner_phoenix/observability/metrics.ex`

- [ ] **Step 1: Write failing tests**

Create `test/stream_closed_captioner_phoenix/observability/metrics_test.exs`:

```elixir
defmodule StreamClosedCaptionerPhoenix.Observability.MetricsTest do
  use ExUnit.Case, async: true

  alias StreamClosedCaptionerPhoenix.Observability.Metrics

  @allowed_tags MapSet.new([:destination, :provider, :result, :http_status, :from_lang, :event, :key])

  test "event_metrics/0 returns a list of Telemetry.Metrics structs" do
    metrics = Metrics.event_metrics()
    assert is_list(metrics)
    assert length(metrics) >= 14

    for m <- metrics do
      assert m.__struct__ in [
               Telemetry.Metrics.Counter,
               Telemetry.Metrics.Distribution,
               Telemetry.Metrics.Sum,
               Telemetry.Metrics.LastValue,
               Telemetry.Metrics.Summary
             ]
    end
  end

  test "all metric tags are in the cardinality allowlist" do
    for m <- Metrics.event_metrics() ++ Metrics.polling_metrics() do
      for tag <- m.tags do
        assert tag in MapSet.to_list(@allowed_tags),
               "metric #{inspect(m.name)} uses disallowed tag #{inspect(tag)}"
      end
    end
  end

  test "metrics/0 returns the union of event, polling, and legacy" do
    union_size =
      length(Metrics.event_metrics()) +
        length(Metrics.polling_metrics()) +
        length(StreamClosedCaptionerPhoenix.Observability.Metrics.__legacy__())

    assert length(Metrics.metrics()) == union_size
  end

  test "active_channels gauge exists" do
    gauge =
      Metrics.polling_metrics()
      |> Enum.find(&match?(%Telemetry.Metrics.LastValue{name: [:scc, :captions, :active_channels, :count]}, &1))

    assert gauge
  end
end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix/observability/metrics_test.exs`
Expected: most tests fail (empty lists).

- [ ] **Step 3: Populate `Observability.Metrics`**

Replace `lib/stream_closed_captioner_phoenix/observability/metrics.ex`:

```elixir
defmodule StreamClosedCaptionerPhoenix.Observability.Metrics do
  @moduledoc "See docs/superpowers/specs/2026-05-11-captions-observability-design.md"

  import Telemetry.Metrics

  @fast_buckets [5, 10, 25, 50, 100, 250, 500, 1000]
  @slow_buckets [50, 100, 250, 500, 1000, 2500, 5000, 10_000]

  def metrics, do: event_metrics() ++ polling_metrics() ++ __legacy__()

  def event_metrics do
    [
      counter("scc.captions.channel.publish.count",
        event_name: [:scc, :captions, :channel, :publish],
        tags: [:destination, :event]),
      counter("scc.captions.channel.join.count",
        event_name: [:scc, :captions, :channel, :join],
        tags: [:result]),
      counter("scc.captions.channel.leave.count",
        event_name: [:scc, :captions, :channel, :leave]),
      counter("scc.captions.pipeline.stop.count",
        event_name: [:scc, :captions, :pipeline, :stop],
        tags: [:destination, :result]),
      counter("scc.captions.pipeline.exception.count",
        event_name: [:scc, :captions, :pipeline, :exception],
        tags: [:destination]),
      counter("scc.captions.translation.stop.count",
        event_name: [:scc, :captions, :translation, :stop],
        tags: [:provider, :result]),
      counter("scc.captions.translation.timeout.count",
        event_name: [:scc, :captions, :translation, :timeout]),
      counter("scc.captions.translation.bits_debit.count",
        event_name: [:scc, :captions, :translation, :bits_debit]),
      counter("scc.captions.pirate_mode.stop.count",
        event_name: [:scc, :captions, :pirate_mode, :stop],
        tags: [:result]),
      counter("scc.outbound.azure_translation.stop.count",
        event_name: [:scc, :outbound, :azure_translation, :stop],
        tags: [:result, :http_status]),
      counter("scc.outbound.gemini_translation.stop.count",
        event_name: [:scc, :outbound, :gemini_translation, :stop],
        tags: [:result, :http_status]),
      counter("scc.outbound.zoom_delivery.stop.count",
        event_name: [:scc, :outbound, :zoom_delivery, :stop],
        tags: [:result, :http_status]),
      counter("scc.outbound.twitch_publish.stop.count",
        event_name: [:scc, :outbound, :twitch_publish, :stop]),
      sum("scc.captions.pipeline.censored.blocked_count",
        event_name: [:scc, :captions, :pipeline, :censored],
        measurement: :blocked_count,
        tags: [:destination, :key]),
      distribution("scc.captions.pipeline.stop.duration",
        event_name: [:scc, :captions, :pipeline, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:destination, :result],
        reporter_options: [buckets: @fast_buckets]),
      distribution("scc.captions.translation.stop.duration",
        event_name: [:scc, :captions, :translation, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:provider, :result],
        reporter_options: [buckets: @slow_buckets]),
      distribution("scc.captions.pirate_mode.stop.duration",
        event_name: [:scc, :captions, :pirate_mode, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:result],
        reporter_options: [buckets: @fast_buckets]),
      distribution("scc.captions.channel.reply.stop.duration",
        event_name: [:scc, :captions, :channel, :reply, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:destination, :result],
        reporter_options: [buckets: @fast_buckets]),
      distribution("scc.outbound.azure_translation.stop.duration",
        event_name: [:scc, :outbound, :azure_translation, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:result],
        reporter_options: [buckets: @slow_buckets]),
      distribution("scc.outbound.gemini_translation.stop.duration",
        event_name: [:scc, :outbound, :gemini_translation, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:result],
        reporter_options: [buckets: @slow_buckets]),
      distribution("scc.outbound.zoom_delivery.stop.duration",
        event_name: [:scc, :outbound, :zoom_delivery, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:result, :http_status],
        reporter_options: [buckets: @slow_buckets]),
      distribution("scc.captions.channel.publish.client_send_age",
        event_name: [:scc, :captions, :channel, :publish],
        measurement: :client_send_age_ms,
        unit: :millisecond,
        tags: [:destination],
        reporter_options: [buckets: @slow_buckets],
        drop: fn measurements -> is_nil(Map.get(measurements, :client_send_age_ms)) end)
    ]
  end

  def polling_metrics do
    [
      last_value("scc.captions.active_channels.count",
        event_name: [:scc, :captions, :active_channels, :measure],
        measurement: :count)
    ]
  end

  @doc false
  def __legacy__ do
    [
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route], unit: {:native, :millisecond}),
      summary("stream_closed_captioner_phoenix.repo.query.total_time",
        unit: {:native, :millisecond}),
      summary("stream_closed_captioner_phoenix.repo.query.decode_time",
        unit: {:native, :millisecond}),
      summary("stream_closed_captioner_phoenix.repo.query.query_time",
        unit: {:native, :millisecond}),
      summary("stream_closed_captioner_phoenix.repo.query.queue_time",
        unit: {:native, :millisecond}),
      summary("stream_closed_captioner_phoenix.repo.query.idle_time",
        unit: {:native, :millisecond}),
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),
      counter("phoenix.socket_connected.count", tags: [:endpoint]),
      summary("phoenix.channel_handled_in.duration",
        unit: {:native, :millisecond}, tags: [:event])
    ]
  end
end
```

Note: the cardinality test's `@allowed_tags` set does NOT cover legacy metrics' tags (`:route`, `:endpoint`). If those legacy metrics blow the test, add `:route` and `:endpoint` to the allowlist constant in the test.

- [ ] **Step 4: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix/observability/metrics_test.exs`
Expected: all pass. If tag-allowlist test fails on `:route`/`:endpoint`, expand `@allowed_tags` accordingly.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/observability/metrics.ex test/stream_closed_captioner_phoenix/observability/metrics_test.exs
git commit -m "feat(observability): populate metric definitions"
```

---

## Task 20: `active_channels` gauge integration (TDD)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/observability/metrics_test.exs`

- [ ] **Step 1: Add failing test for `measure_active_channels/0`**

Append to `metrics_test.exs`:

```elixir
defmodule StreamClosedCaptionerPhoenix.ObservabilityTest do
  use StreamClosedCaptionerPhoenixWeb.ChannelCase

  import StreamClosedCaptionerPhoenix.Factory
  alias StreamClosedCaptionerPhoenix.Observability
  alias StreamClosedCaptionerPhoenix.TelemetryCapture

  test "measure_active_channels/0 emits the active_channels gauge event" do
    TelemetryCapture.attach([[:scc, :captions, :active_channels, :measure]])

    Observability.measure_active_channels()

    assert_receive {:telemetry,
                    [:scc, :captions, :active_channels, :measure],
                    %{count: _count},
                    %{}}
  end
end
```

- [ ] **Step 2: Run**

Run: `mix test test/stream_closed_captioner_phoenix/observability/metrics_test.exs`
Expected: passes immediately because `Observability.measure_active_channels/0` was implemented in Task 1.

- [ ] **Step 3: Commit (no implementation change — this task adds the assertion that the wiring works)**

```bash
git add test/stream_closed_captioner_phoenix/observability/metrics_test.exs
git commit -m "test(observability): cover measure_active_channels gauge emission"
```

---

## Task 21: `PromExPlugin` + `PromEx` module

**Files:**
- Create: `lib/stream_closed_captioner_phoenix/observability/prom_ex_plugin.ex`
- Create: `lib/stream_closed_captioner_phoenix/prom_ex.ex`
- Modify: `config/test.exs`

- [ ] **Step 1: Create the plugin**

Create `lib/stream_closed_captioner_phoenix/observability/prom_ex_plugin.ex`:

```elixir
defmodule StreamClosedCaptionerPhoenix.Observability.PromExPlugin do
  use PromEx.Plugin

  alias StreamClosedCaptionerPhoenix.Observability
  alias StreamClosedCaptionerPhoenix.Observability.Metrics

  @impl true
  def event_metrics(_opts) do
    Event.build(:scc_captions_event_metrics, Metrics.event_metrics())
  end

  @impl true
  def polling_metrics(_opts) do
    Polling.build(
      :scc_captions_polling_metrics,
      :timer.seconds(10),
      {Observability, :measure_active_channels, []},
      Metrics.polling_metrics()
    )
  end
end
```

- [ ] **Step 2: Create the PromEx module**

Create `lib/stream_closed_captioner_phoenix/prom_ex.ex`:

```elixir
defmodule StreamClosedCaptionerPhoenix.PromEx do
  use PromEx, otp_app: :stream_closed_captioner_phoenix

  alias PromEx.Plugins
  alias StreamClosedCaptionerPhoenix.Observability

  @impl true
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix,
       router: StreamClosedCaptionerPhoenixWeb.Router,
       endpoint: StreamClosedCaptionerPhoenixWeb.Endpoint},
      Plugins.Ecto,
      Observability.PromExPlugin
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"},
      {:stream_closed_captioner_phoenix, "captions_overview.json"},
      {:stream_closed_captioner_phoenix, "captions_latency.json"}
    ]
  end

  @impl true
  def dashboard_assigns do
    [datasource_id: "prometheus", default_selected_interval: "30s"]
  end
end
```

- [ ] **Step 3: Disable in test env**

Append to `config/test.exs`:

```elixir
config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.PromEx,
  disabled: true,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: :disabled
```

- [ ] **Step 4: Compile**

Run: `MIX_ENV=test mix compile --warnings-as-errors`
Expected: clean.

Run: `mix test`
Expected: full suite passes.

- [ ] **Step 5: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/observability/prom_ex_plugin.ex lib/stream_closed_captioner_phoenix/prom_ex.ex config/test.exs
git commit -m "feat(observability): PromEx module + custom captions plugin"
```

---

## Task 22: Add `PromEx` to the supervision tree

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix/application.ex`

- [ ] **Step 1: Add `StreamClosedCaptionerPhoenix.PromEx` as a child**

In `lib/stream_closed_captioner_phoenix/application.ex`, add `StreamClosedCaptionerPhoenix.PromEx` to the `children` list (after `Telemetry`, before `Endpoint` is fine):

```elixir
children = [
  {Cluster.Supervisor, [topologies, [name: StreamClosedCaptionerPhoenix.ClusterSupervisor]]},
  StreamClosedCaptionerPhoenix.Repo,
  StreamClosedCaptionerPhoenixWeb.Telemetry,
  StreamClosedCaptionerPhoenix.PromEx,
  {Phoenix.PubSub, name: StreamClosedCaptionerPhoenix.PubSub},
  StreamClosedCaptionerPhoenixWeb.Endpoint,
  {StreamClosedCaptionerPhoenixWeb.UserTracker,
   [
     name: StreamClosedCaptionerPhoenixWeb.UserTracker,
     pubsub_server: StreamClosedCaptionerPhoenix.PubSub
   ]},
  {Absinthe.Subscription, StreamClosedCaptionerPhoenixWeb.Endpoint},
  {StreamClosedCaptionerPhoenix.Cache, []},
  NewRelicOban.Telemetry.Oban,
  {Oban, oban_config()}
]
```

- [ ] **Step 2: Run full suite**

Run: `mix test`
Expected: pass.

Run: `iex -S mix` then exit — confirm the app boots without errors.
Expected: REPL prompt appears; no crash logs.

- [ ] **Step 3: Commit**

```bash
git add lib/stream_closed_captioner_phoenix/application.ex
git commit -m "chore(supervisor): add PromEx to application children"
```

---

## Task 23: `MetricsAuth` plug + `/metrics` route + runtime env var (TDD)

**Files:**
- Create: `test/stream_closed_captioner_phoenix_web/plugs/metrics_auth_test.exs`
- Create: `lib/stream_closed_captioner_phoenix_web/plugs/metrics_auth.ex`
- Modify: `lib/stream_closed_captioner_phoenix_web/router.ex`
- Modify: `config/runtime.exs`

- [ ] **Step 1: Write failing tests for the plug**

Create `test/stream_closed_captioner_phoenix_web/plugs/metrics_auth_test.exs`:

```elixir
defmodule StreamClosedCaptionerPhoenixWeb.Plugs.MetricsAuthTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: false

  alias StreamClosedCaptionerPhoenixWeb.Plugs.MetricsAuth

  setup do
    Application.put_env(:stream_closed_captioner_phoenix, :metrics_auth_token, "supersecret")
    on_exit(fn ->
      Application.delete_env(:stream_closed_captioner_phoenix, :metrics_auth_token)
    end)
    :ok
  end

  test "returns 401 when Authorization header is missing", %{conn: conn} do
    conn = MetricsAuth.call(conn, [])
    assert conn.status == 401
    assert conn.halted
  end

  test "returns 401 when token is wrong", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer wrong")
      |> MetricsAuth.call([])

    assert conn.status == 401
    assert conn.halted
  end

  test "passes through when token is correct", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer supersecret")
      |> MetricsAuth.call([])

    refute conn.halted
  end
end
```

- [ ] **Step 2: Verify failure**

Run: `mix test test/stream_closed_captioner_phoenix_web/plugs/metrics_auth_test.exs`
Expected: fails — `MetricsAuth` module doesn't exist.

- [ ] **Step 3: Implement the plug**

Create `lib/stream_closed_captioner_phoenix_web/plugs/metrics_auth.ex`:

```elixir
defmodule StreamClosedCaptionerPhoenixWeb.Plugs.MetricsAuth do
  @moduledoc "Bearer-token gate for /metrics."

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    expected = Application.fetch_env!(:stream_closed_captioner_phoenix, :metrics_auth_token)

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         true <- Plug.Crypto.secure_compare(token, expected) do
      conn
    else
      _ ->
        conn
        |> send_resp(401, "")
        |> halt()
    end
  end
end
```

- [ ] **Step 4: Add `/metrics` route**

In `lib/stream_closed_captioner_phoenix_web/router.ex`, add the pipeline and scope (place after existing pipeline definitions, outside other scopes):

```elixir
pipeline :metrics_scrape do
  plug :accepts, ["text/plain"]
  plug StreamClosedCaptionerPhoenixWeb.Plugs.MetricsAuth
end

scope "/" do
  pipe_through :metrics_scrape

  forward "/metrics", PromEx.Plug,
    prom_ex_module: StreamClosedCaptionerPhoenix.PromEx
end
```

- [ ] **Step 5: Read `METRICS_AUTH_TOKEN` in `config/runtime.exs`**

Inside the `if config_env() == :prod do` block in `config/runtime.exs`, add:

```elixir
metrics_auth_token =
  System.get_env("METRICS_AUTH_TOKEN") ||
    raise """
    environment variable METRICS_AUTH_TOKEN is missing.
    Generate one: mix phx.gen.secret 64
    """

config :stream_closed_captioner_phoenix, metrics_auth_token: metrics_auth_token
```

- [ ] **Step 6: Run tests**

Run: `mix test test/stream_closed_captioner_phoenix_web/plugs/metrics_auth_test.exs`
Expected: all pass.

Run: `mix test`
Expected: full suite passes.

- [ ] **Step 7: Commit**

```bash
git add lib/stream_closed_captioner_phoenix_web/plugs/metrics_auth.ex lib/stream_closed_captioner_phoenix_web/router.ex config/runtime.exs test/stream_closed_captioner_phoenix_web/plugs/metrics_auth_test.exs
git commit -m "feat(metrics): /metrics endpoint behind bearer-token auth"
```

---

## Task 24: LiveDashboard delegation

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix_web/telemetry.ex`

- [ ] **Step 1: Delegate `metrics/0` to `Observability.Metrics`**

Replace the `metrics/0` function body in `lib/stream_closed_captioner_phoenix_web/telemetry.ex`:

```elixir
def metrics do
  StreamClosedCaptionerPhoenix.Observability.Metrics.metrics()
end
```

Delete the now-duplicated metrics list (already migrated to `Observability.Metrics.__legacy__/0` in Task 19).

- [ ] **Step 2: Run full test suite**

Run: `mix test`
Expected: pass.

- [ ] **Step 3: Boot and verify LiveDashboard renders the metrics**

```bash
iex -S mix phx.server
```

Then in another terminal: open `http://localhost:4000/admin` with an authorized session and click the LiveDashboard Metrics tab. Confirm caption-flow metrics are listed.

(Manual verification only; not a test.)

- [ ] **Step 4: Commit**

```bash
git add lib/stream_closed_captioner_phoenix_web/telemetry.ex
git commit -m "refactor(telemetry): delegate LiveDashboard metrics to Observability.Metrics"
```

---

## Task 25: Grafana dashboard JSONs

**Files:**
- Create: `priv/grafana/dashboards/captions_overview.json`
- Create: `priv/grafana/dashboards/captions_latency.json`

- [ ] **Step 1: Create `captions_overview.json`**

Create `priv/grafana/dashboards/captions_overview.json` (Grafana 10 schema). Minimum viable dashboard:

```json
{
  "annotations": { "list": [] },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "panels": [
    {
      "type": "timeseries",
      "title": "Caption publishes/sec by destination",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
      "targets": [
        {
          "expr": "sum by (destination) (rate(scc_captions_channel_publish_count[1m]))",
          "legendFormat": "{{destination}}"
        }
      ]
    },
    {
      "type": "stat",
      "title": "Active channels",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 6, "x": 12, "y": 0 },
      "targets": [{ "expr": "scc_captions_active_channels_count" }]
    },
    {
      "type": "timeseries",
      "title": "Translation outcomes/min by result",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 },
      "targets": [
        {
          "expr": "sum by (result) (rate(scc_captions_translation_stop_count[1m]))",
          "legendFormat": "{{result}}"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Pipeline error rate by destination",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 },
      "targets": [
        {
          "expr": "sum by (destination) (rate(scc_captions_pipeline_stop_count{result=\"error\"}[5m])) / sum by (destination) (rate(scc_captions_pipeline_stop_count[5m]))",
          "legendFormat": "{{destination}}"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Zoom HTTP statuses",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 16 },
      "targets": [
        {
          "expr": "sum by (http_status) (rate(scc_outbound_zoom_delivery_stop_count[1m]))",
          "legendFormat": "{{http_status}}"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Channel joins / leaves per minute",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 16 },
      "targets": [
        {
          "expr": "sum(rate(scc_captions_channel_join_count[1m]))",
          "legendFormat": "joins"
        },
        {
          "expr": "sum(rate(scc_captions_channel_leave_count[1m]))",
          "legendFormat": "leaves"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Bits debits per minute",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 24 },
      "targets": [
        {
          "expr": "sum(rate(scc_captions_translation_bits_debit_count[1m]))",
          "legendFormat": "debits"
        }
      ]
    }
  ],
  "refresh": "30s",
  "schemaVersion": 38,
  "tags": ["captions", "scc"],
  "templating": { "list": [] },
  "time": { "from": "now-1h", "to": "now" },
  "timezone": "",
  "title": "Captions — Overview",
  "uid": "scc-captions-overview",
  "version": 1
}
```

- [ ] **Step 2: Create `captions_latency.json`**

Create `priv/grafana/dashboards/captions_latency.json`:

```json
{
  "annotations": { "list": [] },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "panels": [
    {
      "type": "timeseries",
      "title": "Pipeline p95 by destination",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum by (le, destination) (rate(scc_captions_pipeline_stop_duration_bucket[5m])))",
          "legendFormat": "{{destination}} p95"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Translation p50/p95/p99 by provider",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
      "targets": [
        {
          "expr": "histogram_quantile(0.50, sum by (le, provider) (rate(scc_captions_translation_stop_duration_bucket[5m])))",
          "legendFormat": "{{provider}} p50"
        },
        {
          "expr": "histogram_quantile(0.95, sum by (le, provider) (rate(scc_captions_translation_stop_duration_bucket[5m])))",
          "legendFormat": "{{provider}} p95"
        },
        {
          "expr": "histogram_quantile(0.99, sum by (le, provider) (rate(scc_captions_translation_stop_duration_bucket[5m])))",
          "legendFormat": "{{provider}} p99"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Zoom delivery p95",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 },
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum by (le) (rate(scc_outbound_zoom_delivery_stop_duration_bucket[5m])))",
          "legendFormat": "p95"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Client send-age p95 (staleness)",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 },
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum by (le, destination) (rate(scc_captions_channel_publish_client_send_age_bucket[5m])))",
          "legendFormat": "{{destination}}"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Pirate mode p95",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 16 },
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum by (le) (rate(scc_captions_pirate_mode_stop_duration_bucket[5m])))",
          "legendFormat": "p95"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Channel reply p95",
      "datasource": "${datasource_id}",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 16 },
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum by (le, destination) (rate(scc_captions_channel_reply_stop_duration_bucket[5m])))",
          "legendFormat": "{{destination}}"
        }
      ]
    }
  ],
  "refresh": "30s",
  "schemaVersion": 38,
  "tags": ["captions", "scc"],
  "templating": { "list": [] },
  "time": { "from": "now-1h", "to": "now" },
  "timezone": "",
  "title": "Captions — Latency",
  "uid": "scc-captions-latency",
  "version": 1
}
```

- [ ] **Step 3: Compile (sanity check that dashboards are reachable from Prom_Ex)**

Run: `MIX_ENV=dev mix compile`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add priv/grafana/dashboards/captions_overview.json priv/grafana/dashboards/captions_latency.json
git commit -m "feat(dashboards): add captions overview + latency Grafana dashboards"
```

---

## Task 26: Final docs + suite + lint + security

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Document the new env var in `CLAUDE.md`**

In the "Production / deploy" section's env-var paragraph, append `METRICS_AUTH_TOKEN` to the listed env vars. Find the line:

```
key ones: `SECRET_KEY_BASE`, `LIVE_SIGNING_SALT`, `ENCRYPTION_KEY`, `TWITCH_CLIENT_ID/SECRET`, `TWITCH_TOKEN_SECRET`, `AZURE_COGNITIVE_KEY`, `DEEPGRAM_TOKEN`, and either `DATABASE_URL` (with `USE_SSL=true`) or the `RDS_*` set.
```

Replace with:

```
key ones: `SECRET_KEY_BASE`, `LIVE_SIGNING_SALT`, `ENCRYPTION_KEY`, `TWITCH_CLIENT_ID/SECRET`, `TWITCH_TOKEN_SECRET`, `AZURE_COGNITIVE_KEY`, `DEEPGRAM_TOKEN`, `METRICS_AUTH_TOKEN`, and either `DATABASE_URL` (with `USE_SSL=true`) or the `RDS_*` set.
```

- [ ] **Step 2: Run the full pre-merge gauntlet**

Run, in order:

```bash
mix deps.get
mix compile --warnings-as-errors
mix test
mix lint
mix security
```

Expected: all clean. Fix any new warnings introduced by this work before commit (do not silence them).

- [ ] **Step 3: Commit final docs**

```bash
git add CLAUDE.md
git commit -m "docs: add METRICS_AUTH_TOKEN to env var list"
```

- [ ] **Step 4: Push branch (manual user action — do NOT push automatically)**

The branch `captions-observability` should be reviewed locally before pushing. When ready:

```bash
git push -u origin captions-observability
```

(Only run this with the user's explicit confirmation per repo conventions.)

---

## Done

All 26 tasks completed should produce:

- A single `:telemetry` emission layer covering caption flow + outbound deps
- Structured JSON logs in prod (length + scalar fields only — no raw caption text, no secret values)
- A `/metrics` endpoint behind bearer-token auth
- Two Grafana dashboards committed to `priv/grafana/dashboards/`
- `Observability.Metrics` as the single source of truth for both LiveDashboard and Prom_Ex
- Test coverage proving the right events fire with the right metadata
- New Relic integration untouched
