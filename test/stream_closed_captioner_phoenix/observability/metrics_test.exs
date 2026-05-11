defmodule StreamClosedCaptionerPhoenix.Observability.MetricsTest do
  use ExUnit.Case, async: true

  alias StreamClosedCaptionerPhoenix.Observability.Metrics

  @allowed_tags MapSet.new([
                  :destination, :provider, :result, :http_status,
                  :from_lang, :event, :key,
                  # Allow these legacy tags from Phoenix/Ecto metrics
                  :route, :endpoint
                ])

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
    for m <- Metrics.event_metrics() ++ Metrics.polling_metrics() ++ Metrics.metrics() do
      for tag <- m.tags do
        assert tag in MapSet.to_list(@allowed_tags),
               "metric #{inspect(m.name)} uses disallowed tag #{inspect(tag)}"
      end
    end
  end

  test "active_channels gauge exists" do
    gauge =
      Metrics.polling_metrics()
      |> Enum.find(
        &match?(%Telemetry.Metrics.LastValue{name: [:scc, :captions, :active_channels, :count]}, &1)
      )

    assert gauge
  end
end
