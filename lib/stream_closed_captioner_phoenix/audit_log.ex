defmodule StreamClosedCaptionerPhoenix.AuditLog do
  @moduledoc """
  Emits lightweight security/audit events through Logger and Telemetry.
  """

  require Logger

  @telemetry_event [:stream_closed_captioner_phoenix, :audit_log]
  @redacted_keys ~w(
    access_token
    refresh_token
    token
    password
    current_password
    password_confirmation
    encrypted_password
    azure_service_key
  )

  @redacted_atom_keys Enum.map(@redacted_keys, &String.to_atom/1)

  def info(event, metadata \\ %{}) when is_binary(event) and is_map(metadata) do
    emit(:info, event, metadata)
  end

  def warn(event, metadata \\ %{}) when is_binary(event) and is_map(metadata) do
    emit(:warning, event, metadata)
  end

  defp emit(level, event, metadata) do
    safe_metadata =
      metadata
      |> redact_deep()
      |> Map.put(:event, event)
      |> Map.put(:level, level)

    Logger.log(level, fn -> "audit event=#{event} metadata=#{inspect(safe_metadata)}" end)

    :telemetry.execute(@telemetry_event, %{count: 1}, safe_metadata)

    :ok
  end

  defp redact_deep(map) when is_map(map) do
    map
    |> Map.drop(@redacted_atom_keys)
    |> Map.drop(@redacted_keys)
    |> Map.new(fn {k, v} -> {k, redact_deep(v)} end)
  end

  defp redact_deep(value), do: value
end
