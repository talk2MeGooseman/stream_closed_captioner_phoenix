defmodule Twitch.HttpHelpers do
  def auth_request_headers(token),
    do: content_header() ++ auth_header(token) ++ client_id_header()

  def content_header, do: [{"Content-Type", "application/json"}]
  def client_id, do: System.get_env("TWITCH_CLIENT_ID") || ""
  def client_id_header, do: [{"Client-Id", client_id()}]
  def extension_version, do: System.get_env("EXTENSION_VERSION") || "1.6.4"

  def webhook_transport,
    do: %{
      method: "webhook",
      callback:
        Application.get_env(:stream_closed_captioner_phoenix, :eventsub_callback_url) <>
          "/webhooks",
      secret: eventsub_secret()
    }

  def eventsub_secret, do: System.get_env("TWITCH_EVENTSUB_SECRET") || ""

  def client_secret,
    do: Application.get_env(:stream_closed_captioner_phoenix, :twitch_client_secret) || ""

  def token_secret, do: System.get_env("TWITCH_TOKEN_SECRET") || ""
  defp auth_header(token), do: [{"Authorization", "Bearer " <> token}]
end
