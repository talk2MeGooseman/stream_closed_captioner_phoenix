defmodule StreamClosedCaptionerPhoenix.AuditHelpers do
  @moduledoc """
  Shared test helpers for capturing and asserting telemetry-based audit events.
  """

  import ExUnit.Assertions

  @audit_event [:stream_closed_captioner_phoenix, :audit_log]

  @doc """
  Attaches a temporary telemetry handler, runs `fun`, then detaches.
  Captured audit events are sent to the calling process as
  `{:audit_event, measurements, metadata}` messages.
  """
  def capture_audit_events(fun) do
    parent = self()
    handler_id = "audit-log-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach(
        handler_id,
        @audit_event,
        fn _event, measurements, metadata, _config ->
          send(parent, {:audit_event, measurements, metadata})
        end,
        nil
      )

    try do
      fun.()
    after
      :telemetry.detach(handler_id)
    end
  end

  @doc """
  Asserts that an audit event with the given `event_name` was received.
  """
  def assert_audit_event(event_name) do
    assert_receive {:audit_event, _measurements, %{event: ^event_name}}
  end
end
