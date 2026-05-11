defmodule StreamClosedCaptionerPhoenix.Observability.Metrics do
  @moduledoc """
  Single source of truth for the `Telemetry.Metrics` list consumed by
  both LiveDashboard (`metrics/0`) and Prom_Ex (`event_metrics/0` +
  `polling_metrics/0`).
  """

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics, do: event_metrics() ++ polling_metrics() ++ legacy_metrics()

  @spec event_metrics() :: [Telemetry.Metrics.t()]
  def event_metrics, do: []

  @spec polling_metrics() :: [Telemetry.Metrics.t()]
  def polling_metrics, do: []

  defp legacy_metrics, do: []
end
