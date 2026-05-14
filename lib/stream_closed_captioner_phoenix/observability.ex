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
