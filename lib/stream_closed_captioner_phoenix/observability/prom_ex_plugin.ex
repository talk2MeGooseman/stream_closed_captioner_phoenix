defmodule StreamClosedCaptionerPhoenix.Observability.PromExPlugin do
  @moduledoc """
  Custom Prom_Ex plugin exposing caption-flow events and the
  active-channels polling gauge.
  """

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
