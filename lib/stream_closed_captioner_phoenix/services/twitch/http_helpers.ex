defmodule Twitch.HttpHelpers do
  def auth_request_headers(token), do: content_header() ++ auth_header(token) ++ client_id_header()
  def content_header, do: [{"Content-Type", "application/json"}]
  def client_id, do: System.get_env("TWITCH_CLIENT_ID") || ""
  def client_id_header, do: [{"Client-Id", client_id()}]
  def extension_version, do: System.get_env("EXTENSION_VERSION") || "1.6.4"

  defp client_secret, do: System.get_env("TWITCH_CLIENT_SECRET") || ""
  defp token_secret, do: System.get_env("TWITCH_TOKEN_SECRET") || ""
  defp auth_header(token), do: [{"Authorization", "Bearer " <> token}]
end
