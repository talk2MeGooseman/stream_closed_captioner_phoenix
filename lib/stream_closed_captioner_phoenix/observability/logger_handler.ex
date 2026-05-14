defmodule StreamClosedCaptionerPhoenix.Observability.LoggerHandler do
  @moduledoc """
  Telemetry → Logger bridge. Attached at boot via
  `StreamClosedCaptionerPhoenix.Observability.attach_logger_handlers/0`.

  Handler clauses extract scalar fields explicitly — they never
  `inspect` `%User{}` or `%StreamSettings{}` structs directly so that
  sensitive fields (e.g. `access_token`, `refresh_token`) never appear in logs.
  """

  require Logger

  @handler_id "scc-observability-error-logs"

  @events [
    [:scc, :captions, :pipeline, :stop],
    [:scc, :captions, :pipeline, :exception],
    [:scc, :captions, :translation, :stop],
    [:scc, :captions, :translation, :exception],
    [:scc, :captions, :translation, :timeout],
    [:scc, :outbound, :zoom_delivery, :stop],
    [:scc, :outbound, :zoom_delivery, :exception],
    [:scc, :outbound, :azure_translation, :exception],
    [:scc, :outbound, :gemini_translation, :exception]
  ]

  def attach do
    # Detach first in case attach is called twice (defensive — boot-time attach
    # plus test setups that may re-attach).
    :telemetry.detach(@handler_id)
    :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle/4, nil)
    :ok
  end

  def handle([:scc, :captions, :pipeline, :stop], %{duration: d}, %{result: :error} = m, _) do
    Logger.error("caption pipeline returned error",
      duration_ms: native_to_ms(d),
      destination: m[:destination],
      error_reason: inspect(m[:error_reason]),
      user_id: m[:user_id],
      text_length: m[:text_length],
      language: m[:language]
    )
  end

  def handle([:scc, :captions, :pipeline, :stop], _, %{result: :ok}, _), do: :ok

  def handle([:scc, :captions, :pipeline, :exception], _, m, _) do
    Logger.error("caption pipeline raised",
      destination: m[:destination],
      kind: m[:kind],
      reason: Exception.format_banner(m[:kind], m[:reason]),
      stacktrace: Exception.format_stacktrace(m[:stacktrace]),
      user_id: m[:user_id]
    )
  end

  def handle([:scc, :captions, :translation, :stop], _, %{result: :error} = m, _) do
    Logger.warning("translation failed",
      user_id: m[:user_id],
      provider: m[:provider],
      error_reason: inspect(m[:error_reason])
    )
  end

  def handle([:scc, :captions, :translation, :stop], _, _, _), do: :ok

  def handle([:scc, :captions, :translation, :exception], _, m, _) do
    Logger.error("translation raised",
      provider: m[:provider],
      user_id: m[:user_id],
      reason: Exception.format_banner(m[:kind], m[:reason]),
      stacktrace: Exception.format_stacktrace(m[:stacktrace])
    )
  end

  def handle([:scc, :captions, :translation, :timeout], %{duration_ms: ms}, m, _) do
    Logger.warning("translation timed out", user_id: m[:user_id], duration_ms: ms)
  end

  def handle([:scc, :outbound, :zoom_delivery, :stop], _, %{result: :error} = m, _) do
    Logger.warning("zoom delivery rejected",
      user_id: m[:user_id],
      http_status: m[:http_status],
      error_reason: inspect(m[:error_reason]),
      host: m[:host]
    )
  end

  def handle([:scc, :outbound, :zoom_delivery, :stop], _, _, _), do: :ok

  def handle([:scc, :outbound, _service, :exception], _, m, _) do
    Logger.error("outbound translation raised",
      reason: Exception.format_banner(m[:kind], m[:reason]),
      stacktrace: Exception.format_stacktrace(m[:stacktrace])
    )
  end

  defp native_to_ms(duration), do: System.convert_time_unit(duration, :native, :millisecond)
end
