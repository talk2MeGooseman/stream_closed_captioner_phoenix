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
