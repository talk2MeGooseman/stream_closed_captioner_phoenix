# Captions Observability — Design

**Date:** 2026-05-11
**Branch:** TBD (created at implementation time)
**Status:** Approved (pending user spec review)

## Motivation

Today the caption pipeline relies on `new_relic_agent` decorators and ad-hoc `Logger.error("...#{user.id}...")` calls. That's enough to know "something is broken" but not enough to:

- Establish performance baselines for the pipeline, translations, Zoom delivery, and end-to-end client→publish latency
- Diagnose live incidents by querying structured fields (`user_id`, `destination`, `provider`, `result`, `http_status`)
- Detect regressions over time via versioned alert thresholds

This spec adds a single `:telemetry`-based emission layer that feeds three consumers (structured JSON logs, Phoenix LiveDashboard, Prometheus via Prom_Ex), with Grafana dashboards stored as JSON in the repo.

The existing New Relic integration stays in place untouched as a SaaS backstop.

## Goals

1. Performance baselines (p50/p95/p99) for caption pipeline, translations, pirate mode, channel reply, and outbound HTTP (Azure, Gemini, Zoom).
2. Incident-diagnosis logs: every error log line in prod is a JSON object queryable by `user_id`, `destination`, `provider`, `result`, `http_status`, `request_id`.
3. Dashboards-as-code: caption-overview and caption-latency dashboards committed under `priv/grafana/dashboards/`.
4. In-app live pulse view via Phoenix LiveDashboard, reusing the same metrics definitions.
5. Test coverage that proves the right events fire with the right metadata for each code path.

## Non-goals

- Standing up Prometheus or Grafana infrastructure (deferred follow-up; the app side is complete and dormant until that work happens).
- Extending or replacing New Relic instrumentation. Existing `@trace` decorators and `NewRelic.start_transaction` calls remain.
- Tracing (OpenTelemetry/Jaeger/Tempo).
- Instrumentation outside the caption flow + its outbound dependencies. Out of scope: Oban jobs, GraphQL resolvers, cache, auth, billing, admin.
- Billing-grade per-caption audit records.
- Logging raw caption text. Length and language only.
- Latency assertions or benchmark suites in `mix test`. Performance regressions are caught in prod via Prometheus alerts (future work).

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  EMISSION (single layer)                                            │
│  • CaptionsChannel  • CaptionsPipeline  • Translations              │
│  • Azure / Gemini / Zoom outbound calls                             │
│  Each calls :telemetry.span/3 or :telemetry.execute/3 with one      │
│  canonical event name and structured metadata.                      │
└─────────────────────────┬───────────────────────────────────────────┘
                          │ :telemetry events
        ┌─────────────────┼─────────────────────────┐
        ▼                 ▼                         ▼
┌──────────────┐   ┌──────────────────┐   ┌───────────────────────┐
│  Logger      │   │  Telemetry.      │   │  Prom_Ex              │
│  (JSON)      │   │  Metrics list    │   │  /metrics endpoint    │
│  attached    │   │  ─── shared ───  │   │  + custom plugin      │
│  via handler │   │  feeds two:      │   │  + dashboards in repo │
└──────────────┘   │   - LiveDashboard│   └───────────────────────┘
                   │   - Prom_Ex      │
                   └──────────────────┘
```

**New modules** under `lib/stream_closed_captioner_phoenix/observability/`:

- `Observability` — public helpers: `attach_logger_handlers/0` (called at boot), `measure_active_channels/0` (called by Prom_Ex polling).
- `Observability.Metrics` — single source of truth for the `Telemetry.Metrics` list. Three functions: `event_metrics/0`, `polling_metrics/0`, `metrics/0` (the union, used by LiveDashboard).
- `Observability.PromExPlugin` — `PromEx.Plugin` that registers event and polling metrics from `Observability.Metrics`.
- `Observability.LoggerHandler` — `:telemetry` handler that emits structured `Logger` lines for `:stop` events with `result: :error`, all `:exception` events, and translation `:timeout` events.

**Endpoint**: `/metrics` mounted in the router behind `StreamClosedCaptionerPhoenixWeb.Plugs.MetricsAuth` (bearer-token check against `METRICS_AUTH_TOKEN` env var). Not behind `:admin_protected` — Prometheus scrapes with a service token, not a Twitch UID.

**Supervisor**: `StreamClosedCaptionerPhoenix.PromEx` added as a child of `Application.start/2`. The existing `StreamClosedCaptionerPhoenixWeb.Telemetry` supervisor stays (hosts `telemetry_poller`), but its `metrics/0` delegates to `Observability.Metrics.metrics/0`.

**Dashboards-as-code**: `priv/grafana/dashboards/captions_overview.json` and `captions_latency.json`, hand-authored. Prom_Ex's built-in plugin dashboards (BEAM, Phoenix, Ecto, Application) ship alongside.

**New Relic stays untouched.** Existing decorators (`@trace :pipeline_to`, `@trace :maybe_translate`, `@trace :handle_in`) and the `NewRelic.start_transaction("Captions", "twitch"|"zoom")` calls remain in `CaptionsChannel`. `NewRelicOban.Telemetry.Oban` stays in the supervisor.

## Key decisions

1. **Single :telemetry emission layer**, multiple consumers. No per-tool emission code.
2. **Caption text is never logged.** Only `text_length` (int) in event metadata. No hashing — drops the `caption_text_fingerprint` helper that was considered.
3. **`user_id` is in metadata, never a Prometheus label.** Cardinality protection. `user_id` is queryable in logs and traces only.
4. **Prom_Ex over OpenTelemetry.** New Relic already provides trace UI for non-caption flows; spans would duplicate.
5. **Bearer-token auth on `/metrics`.** Token-based rotation is simpler than IP allowlists across Coolify's network.
6. **Logger.error call sites are kept** (rewritten to structured keyword form) in addition to the telemetry handler — duplicate log lines per error accepted. Single-source consolidation deferred.
7. **`logger_json`** chosen over a hand-rolled formatter. One dep is cheaper than maintaining the encoder.
8. **Tests assert event emission and structure**, not latency. Perf regression detection is a prod-metrics concern, not a CI concern.

## Events emitted

Namespace prefix: `[:scc, :captions, ...]` for caption-flow events, `[:scc, :outbound, ...]` for external HTTP. All spans follow the `:start` / `:stop` / `:exception` convention so `:telemetry.span/3` is the emission primitive.

### Caption pipeline

| Event | Emitter | Measurements | Metadata |
|---|---|---|---|
| `[:scc, :captions, :pipeline, :start \| :stop \| :exception]` | `CaptionsPipeline.pipeline_to/3` wrapped in `:telemetry.span/3` | `duration` | `destination` (`:default`/`:twitch`/`:zoom`), `user_id`, `language`, `text_length`, `pirate_mode`, `result` (`:ok`/`:error`), `error_reason` |
| `[:scc, :captions, :pipeline, :censored]` | `apply_censoring/2` | `blocked_count` | `destination`, `user_id`, `key` (`:interim`/`:final`) |

### Translations

| Event | Emitter | Measurements | Metadata |
|---|---|---|---|
| `[:scc, :captions, :translation, :start \| :stop \| :exception]` | `Translations.maybe_translate/3` wrapped in `:telemetry.span/3` | `duration` | `user_id`, `provider` (`:azure`/`:gemini`), `from_lang`, `to_langs` (sorted), `to_count`, `result` (`:ok`/`:error`/`:skipped_no_balance`/`:skipped_no_languages`/`:timeout`), `error_reason` |
| `[:scc, :captions, :translation, :timeout]` | The `Task.shutdown` branch in `pipeline_to(:twitch, …)` | `duration_ms` (configured timeout) | `user_id` |
| `[:scc, :captions, :translation, :bits_debit]` | `activate_translations_for/3` on success | `count = 1` | `user_id` |

### Pirate mode

| Event | Emitter | Measurements | Metadata |
|---|---|---|---|
| `[:scc, :captions, :pirate_mode, :stop]` | `maybe_pirate_mode_for/3` | `duration` | `user_id`, `key`, `result` (`:ok`/`:error`) |

### Channel

| Event | Emitter | Measurements | Metadata |
|---|---|---|---|
| `[:scc, :captions, :channel, :join]` | `CaptionsChannel.join/3` | `count = 1` | `user_id`, `result` (`:ok`/`:unauthorized`) |
| `[:scc, :captions, :channel, :leave]` | `CaptionsChannel.terminate/2` (added) | `count = 1` | `user_id`, `reason` |
| `[:scc, :captions, :channel, :publish]` | Top of each `handle_in/3` clause | `count = 1`, `client_send_age_ms` (when `sentOn` present) | `user_id`, `destination`, `event` (string), `zoom_enabled`, `twitch_enabled` |
| `[:scc, :captions, :channel, :reply, :stop]` | `handle_in/3` body wrapped in `:telemetry.span/3` | `duration` | `user_id`, `destination`, `event`, `result` |

### Outbound

| Event | Emitter | Measurements | Metadata |
|---|---|---|---|
| `[:scc, :outbound, :azure_translation, :start \| :stop \| :exception]` | `Azure.perform_translations/3` (wrap) | `duration` | `from_lang`, `to_count`, `result`, `http_status`, `error_reason` |
| `[:scc, :outbound, :gemini_translation, :start \| :stop \| :exception]` | `Gemini.perform_translations/3` (wrap) | `duration` | same shape as Azure |
| `[:scc, :outbound, :zoom_delivery, :start \| :stop \| :exception]` | `Zoom.send_captions_to/3` (wrap inside Zoom pipeline) | `duration`, `body_bytes` | `user_id`, `http_status`, `result`, `error_reason`, `host` |
| `[:scc, :outbound, :twitch_publish, :stop]` | After `Absinthe.Subscription.publish/3` | `count = 1` | `user_id`, `twitch_uid` |

### Periodic

| Event | Emitter | Measurements | Metadata |
|---|---|---|---|
| `[:scc, :captions, :active_channels, :measure]` | `Observability.measure_active_channels/0` (Prom_Ex polling, 10s) | `count` | none |

### Conventions

- All durations come from `:telemetry.span/3` in `:native` units.
- `result` is always an atom.
- `error_reason` is `nil` on success, `Exception.message/1` on `:exception`, raw error term on `{:error, _}`.
- `:telemetry.span/3` re-raises after emitting `:exception`.

## Metrics

All metrics live in `Observability.Metrics`. Bucket sets:

- `@fast_buckets [5, 10, 25, 50, 100, 250, 500, 1000]` ms — sync work
- `@slow_buckets [50, 100, 250, 500, 1000, 2500, 5000, 10_000]` ms — outbound HTTP + translation

### Counters

- `scc.captions.channel.publish.count` — tags `[:destination, :event]`
- `scc.captions.channel.join.count` — tags `[:result]`
- `scc.captions.channel.leave.count`
- `scc.captions.pipeline.stop.count` — tags `[:destination, :result]`
- `scc.captions.pipeline.exception.count` — tags `[:destination]`
- `scc.captions.translation.stop.count` — tags `[:provider, :result]`
- `scc.captions.translation.timeout.count`
- `scc.captions.translation.bits_debit.count`
- `scc.captions.pirate_mode.stop.count` — tags `[:result]`
- `scc.outbound.azure_translation.stop.count` — tags `[:result, :http_status]`
- `scc.outbound.gemini_translation.stop.count` — tags `[:result, :http_status]`
- `scc.outbound.zoom_delivery.stop.count` — tags `[:result, :http_status]`
- `scc.outbound.twitch_publish.stop.count`

### Sums

- `scc.captions.pipeline.censored.blocked_count` — measurement `:blocked_count`, tags `[:destination, :key]`

### Distributions

- `scc.captions.pipeline.stop.duration` — `@fast_buckets`, tags `[:destination, :result]`
- `scc.captions.translation.stop.duration` — `@slow_buckets`, tags `[:provider, :result]`
- `scc.captions.pirate_mode.stop.duration` — `@fast_buckets`, tags `[:result]`
- `scc.captions.channel.reply.stop.duration` — `@fast_buckets`, tags `[:destination, :result]`
- `scc.outbound.azure_translation.stop.duration` — `@slow_buckets`, tags `[:result]`
- `scc.outbound.gemini_translation.stop.duration` — `@slow_buckets`, tags `[:result]`
- `scc.outbound.zoom_delivery.stop.duration` — `@slow_buckets`, tags `[:result, :http_status]`
- `scc.captions.channel.publish.client_send_age` — measurement `:client_send_age_ms`, `@slow_buckets`, tags `[:destination]`, dropped when `nil`

### Gauges

- `scc.captions.active_channels.count` — `last_value`, from `[:scc, :captions, :active_channels, :measure]`

Cardinality allowlist for tags: `[:destination, :provider, :result, :http_status, :from_lang, :event, :key]`. Enforced by a unit test (`metrics_test.exs`).

## Structured logging

### Dep + config

Add `{:logger_json, "~> 6.0"}`.

```elixir
# config/dev.exs
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :destination, :provider]

# config/runtime.exs (prod only)
if config_env() == :prod do
  config :logger, :default_handler,
    formatter: {LoggerJSON.Formatters.Basic, metadata: :all}

  config :logger, level: :info
end
```

### Default metadata sources

1. `Plug.RequestId` (already in endpoint) — `request_id` per HTTP request.
2. `Plug.Logger` (already present) — `method`, `status`, `path`.
3. New: `CaptionsChannel.join/3` calls `Logger.metadata(user_id: ..., twitch_uid: ...)` after authorization.
4. New: each `handle_in/3` clause adds `Logger.metadata(destination: ...)` at entry.

### Telemetry → Logger bridge

`Observability.LoggerHandler` attaches at boot via `Observability.attach_logger_handlers/0` (called from `Application.start/2` after the supervisor returns). Handler clauses:

- `[:scc, :captions, :pipeline, :stop]` with `result: :error` → `Logger.error("caption pipeline returned error", ...)`.
- `[:scc, :captions, :pipeline, :stop]` with `result: :ok` → no log (success path silent).
- `[:scc, :captions, :pipeline, :exception]` → `Logger.error` including formatted stacktrace.
- `[:scc, :captions, :translation, :stop]` with `result: :error` → `Logger.warning("translation failed", ...)`.
- `[:scc, :captions, :translation, :timeout]` → `Logger.warning("translation timed out", duration_ms: ...)`.
- `[:scc, :outbound, :zoom_delivery, :stop]` with HTTP 4xx/5xx → `Logger.warning("zoom delivery rejected", http_status: ..., user_id: ...)`.
- `[:scc, :outbound, :*, :exception]` → `Logger.error` with stacktrace.

### Rewritten call-site logs (kept)

Existing `Logger.error("Twitch pipeline failed for user #{user.id}: #{inspect(reason)}")` calls are **kept** but rewritten to structured keyword form:

```elixir
Logger.error("twitch pipeline failed",
  user_id: user.id,
  reason: inspect(reason),
  destination: :twitch)
```

This produces duplicate log lines per error (handler also logs) — accepted for now per design discussion. Single-source consolidation is a follow-up.

Other `Logger.warning` / `Logger.debug` calls in `CaptionsPipeline` and `Zoom` paths are similarly rewritten to keyword-list metadata form. Debug-level logs in the Zoom HTTP path become `Logger.info` with structured fields, since their content is now also covered by the `zoom_delivery` event.

### PII guardrails

- Handler clauses never `inspect` `%User{}` or `%StreamSettings{}` directly. Extract specific scalar fields.
- Unit test (`logger_handler_test.exs`) feeds a synthetic event with a `%User{azure_service_key: "TOPSECRET"}` and asserts `"TOPSECRET"` does not appear in captured log output.

### Log levels

- `:info` — lifecycle (not per-publish; successful publishes are metric counters only).
- `:warning` — recoverable degradations (pirate mode failure, translation timeout, Zoom 4xx).
- `:error` — `:exception` events and `result: :error` on pipeline / translation / zoom_delivery.

## Prom_Ex + `/metrics` endpoint

### Dep

```elixir
{:prom_ex, "~> 1.10"},
```

### `StreamClosedCaptionerPhoenix.PromEx`

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
      {Plugins.Phoenix, router: StreamClosedCaptionerPhoenixWeb.Router,
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

`PromEx.Plugins.Oban` intentionally omitted (out of scope).

### Custom plugin

```elixir
defmodule StreamClosedCaptionerPhoenix.Observability.PromExPlugin do
  use PromEx.Plugin
  alias StreamClosedCaptionerPhoenix.Observability

  @impl true
  def event_metrics(_opts) do
    Event.build(:scc_captions_event_metrics, Observability.Metrics.event_metrics())
  end

  @impl true
  def polling_metrics(_opts) do
    Polling.build(
      :scc_captions_polling_metrics,
      :timer.seconds(10),
      {Observability, :measure_active_channels, []},
      Observability.Metrics.polling_metrics()
    )
  end
end
```

### Endpoint + auth

```elixir
# router.ex
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

```elixir
defmodule StreamClosedCaptionerPhoenixWeb.Plugs.MetricsAuth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    expected = Application.fetch_env!(:stream_closed_captioner_phoenix, :metrics_auth_token)

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         true <- Plug.Crypto.secure_compare(token, expected) do
      conn
    else
      _ -> conn |> send_resp(401, "") |> halt()
    end
  end
end
```

New env var: `METRICS_AUTH_TOKEN` (required in prod, read in `config/runtime.exs`). Documented alongside the existing env-var list in CLAUDE.md.

### Disabled in test

```elixir
# config/test.exs
config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.PromEx,
  disabled: true,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: :disabled
```

`:telemetry` events still fire (handlers attached for tests still work); no Prom_Ex registry or `/metrics` plug runs.

### Dashboards-as-code

```
priv/grafana/dashboards/
├── captions_overview.json     # hand-authored
└── captions_latency.json      # hand-authored
```

`captions_overview.json` panels:
- Caption publishes/sec stacked by `destination`
- Channel join/leave rate
- Active channels gauge (single stat + time series)
- Pipeline error rate by destination
- Translation outcomes per minute, stacked by `result`
- Top Zoom HTTP status codes
- Bits debits per minute

`captions_latency.json` panels:
- Pipeline p50/p95/p99 by destination
- Translation p50/p95/p99 by provider
- Zoom delivery p95
- Client-send-age p95 (most actionable for incident triage)
- Pirate mode p95
- Channel reply p95

Authored as Grafana 10 JSON. Source of truth is the JSON file; Grafana renders.

## LiveDashboard wiring

`StreamClosedCaptionerPhoenixWeb.Telemetry.metrics/0` becomes:

```elixir
def metrics do
  StreamClosedCaptionerPhoenix.Observability.Metrics.metrics()
end
```

`Observability.Metrics.metrics/0` returns `event_metrics() ++ polling_metrics() ++ legacy_phoenix_ecto_vm_metrics()` — the existing Phoenix/Ecto/VM/channel summaries move from `StreamClosedCaptionerPhoenixWeb.Telemetry` into `Observability.Metrics` so both LiveDashboard and Prom_Ex read from a single source.

LiveDashboard route stays under the `:admin_protected` pipeline (`/admin`). No new pages — LiveDashboard renders the metrics list automatically.

LiveDashboard does not show persistent history (in-memory ring buffer only) or cross-node aggregation (single-node view).

## Testing

### Telemetry-capture helper

```elixir
# test/support/telemetry_capture.ex
defmodule StreamClosedCaptionerPhoenix.TelemetryCapture do
  def attach(events) when is_list(events) do
    ref = make_ref()
    pid = self()
    id = "test-capture-#{inspect(ref)}"

    :telemetry.attach_many(id, events,
      fn name, measurements, metadata, _config ->
        send(pid, {:telemetry, name, measurements, metadata})
      end, nil)

    ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(id) end)
    :ok
  end
end
```

`:telemetry` handlers run synchronously inside the emitting process, so `assert_receive` is deterministic.

### Test files

| File | Coverage |
|---|---|
| `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs` | Pipeline events for `:default`, `:twitch`, `:zoom` paths: `:stop` with `result: :ok` and `:error`; `:exception`; censored event with `blocked_count > 0`; zoom_delivery event with `http_status`. |
| `test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs` | Azure success, Gemini success (FunWithFlags gate), `:skipped_no_balance`, `:skipped_no_languages`, error path, `bits_debit` event on activation. |
| `test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs` | `join` ok/unauthorized; `publishFinal` (Zoom and Twitch paths); `active` does NOT trigger pipeline; `client_send_age_ms` populated when `sentOn` present; channel reply span. |
| `test/stream_closed_captioner_phoenix/observability/logger_handler_test.exs` | Pipeline error → structured log line with `destination`/`user_id`/`error_reason`/`duration_ms`; `:exception` includes formatted stacktrace; `result: :ok` produces no log; PII guard test asserts `azure_service_key` value never appears in log output. |
| `test/stream_closed_captioner_phoenix/observability/metrics_test.exs` | Every metric's `event_name` exists in an emitter module; every tag is in the cardinality allowlist; metrics list contains only `Telemetry.Metrics` structs. |
| `test/stream_closed_captioner_phoenix_web/plugs/metrics_auth_test.exs` | Missing header → 401; wrong token → 401; correct token → pass through. |

### Out of test scope

- Prometheus scrape format (Prom_Ex's own test suite).
- Grafana dashboard JSON validation.
- LiveDashboard rendering (Phoenix library).
- Latency thresholds. Perf regressions are caught in prod, not in CI.

### Product-code change driven by tests

The 3-second translation timeout in `pipeline_to(:twitch, …)` becomes configurable:

```elixir
@translation_task_timeout_ms Application.compile_env(
  :stream_closed_captioner_phoenix, :translation_task_timeout_ms, 3_000)
```

Tests set it to 50ms via app config so the `Task.shutdown` branch can be exercised without sleeping 3s.

## Files added / modified

**Added:**
- `lib/stream_closed_captioner_phoenix/observability.ex`
- `lib/stream_closed_captioner_phoenix/observability/metrics.ex`
- `lib/stream_closed_captioner_phoenix/observability/prom_ex_plugin.ex`
- `lib/stream_closed_captioner_phoenix/observability/logger_handler.ex`
- `lib/stream_closed_captioner_phoenix/prom_ex.ex`
- `lib/stream_closed_captioner_phoenix_web/plugs/metrics_auth.ex`
- `priv/grafana/dashboards/captions_overview.json`
- `priv/grafana/dashboards/captions_latency.json`
- `test/support/telemetry_capture.ex`
- `test/stream_closed_captioner_phoenix/captions_pipeline_telemetry_test.exs`
- `test/stream_closed_captioner_phoenix/captions_pipeline/translations_telemetry_test.exs`
- `test/stream_closed_captioner_phoenix_web/channels/captions_channel_telemetry_test.exs`
- `test/stream_closed_captioner_phoenix/observability/logger_handler_test.exs`
- `test/stream_closed_captioner_phoenix/observability/metrics_test.exs`
- `test/stream_closed_captioner_phoenix_web/plugs/metrics_auth_test.exs`

**Modified:**
- `mix.exs` — add `prom_ex` and `logger_json`
- `config/dev.exs` — Logger format with metadata
- `config/test.exs` — disable Prom_Ex
- `config/runtime.exs` — JSON Logger formatter in prod; read `METRICS_AUTH_TOKEN`
- `lib/stream_closed_captioner_phoenix/application.ex` — add `PromEx` child; call `Observability.attach_logger_handlers/0`
- `lib/stream_closed_captioner_phoenix_web/telemetry.ex` — delegate `metrics/0` to `Observability.Metrics.metrics/0`
- `lib/stream_closed_captioner_phoenix/captions_pipeline.ex` — wrap `pipeline_to/3` in `:telemetry.span/3`; emit censored, pirate-mode, translation-timeout events; wrap `Zoom.send_captions_to/3` call; make timeout configurable; rewrite Logger calls to structured form
- `lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex` — wrap `maybe_translate/3` in `:telemetry.span/3`; emit `bits_debit` event; rewrite Logger calls
- `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex` — set Logger metadata on join + in each handle_in; emit `:channel, :publish` event with `client_send_age_ms`; wrap `handle_in/3` body in `:telemetry.span/3`; emit `twitch_publish` event after Absinthe publish; emit `:channel, :leave` from `terminate/2`; rewrite Logger calls
- `lib/stream_closed_captioner_phoenix/services/azure.ex` — wrap `perform_translations/3` with `:telemetry.span/3`
- `lib/stream_closed_captioner_phoenix/services/gemini.ex` — wrap `perform_translations/3` with `:telemetry.span/3`
- `lib/stream_closed_captioner_phoenix/services/zoom.ex` — wrap `send_captions_to/3` with `:telemetry.span/3`
- `lib/stream_closed_captioner_phoenix_web/router.ex` — add `:metrics_scrape` pipeline and `/metrics` forward
- `CLAUDE.md` — add `METRICS_AUTH_TOKEN` to env-var list

## Future work (out of this spec)

- Stand up Prometheus and Grafana in Coolify (or use Grafana Cloud).
- Define Prometheus alert rules for translation timeout rate, pipeline error rate, p95 latency thresholds.
- Add `PromEx.Plugins.Oban` plugin when Oban observability becomes a priority.
- Consider `OpenTelemetry` SDK + OTLP exporter if New Relic is ever removed.
- Consolidate to single-source error logging (remove call-site `Logger.error` lines and rely only on the telemetry handler).
- Benchee-based benchmark suite if perf gates in CI become a requirement.
