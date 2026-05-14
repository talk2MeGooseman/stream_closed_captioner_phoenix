defmodule StreamClosedCaptionerPhoenix.ObservabilityTest do
  use StreamClosedCaptionerPhoenixWeb.ChannelCase

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
