defmodule StreamClosedCaptionerPhoenix.Observability.LoggerHandler do
  @moduledoc """
  Telemetry -> Logger bridge. Attached at boot via
  `StreamClosedCaptionerPhoenix.Observability.attach_logger_handlers/0`.
  Clauses are added in Task 17.
  """

  @spec attach() :: :ok
  def attach, do: :ok
end
