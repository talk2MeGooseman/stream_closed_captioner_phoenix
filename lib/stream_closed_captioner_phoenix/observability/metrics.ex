defmodule StreamClosedCaptionerPhoenix.Observability.Metrics do
  @moduledoc """
  Single source of truth for the `Telemetry.Metrics` list consumed by
  both LiveDashboard (`metrics/0`) and Prom_Ex (`event_metrics/0` +
  `polling_metrics/0`).
  """

  import Telemetry.Metrics

  @fast_buckets [5, 10, 25, 50, 100, 250, 500, 1000]
  @slow_buckets [50, 100, 250, 500, 1000, 2500, 5000, 10_000]

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics, do: event_metrics() ++ polling_metrics() ++ __legacy__()

  @spec event_metrics() :: [Telemetry.Metrics.t()]
  def event_metrics, do: event_counters() ++ event_distributions()

  defp event_counters do
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
        tags: [:destination, :key])
    ]
  end

  defp event_distributions do
    [
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

  @spec polling_metrics() :: [Telemetry.Metrics.t()]
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
