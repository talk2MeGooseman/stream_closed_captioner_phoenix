defmodule Twitch.Extension do
  import Helpers

  alias NewRelic.Instrumented.HTTPoison
  alias Twitch.ExtensionProvider
  alias Twitch.Extension.Credentials
  @behaviour ExtensionProvider

  @broadcaster :broadcaster
  @spec broadcaster_segment :: :broadcaster
  def broadcaster_segment, do: @broadcaster

  @global :global
  @spec global_segment :: :global
  def global_segment, do: @global

  @developer :developer
  @spec developer_segment :: :developer
  def developer_segment, do: @developer

  @impl ExtensionProvider
  def send_pubsub_message_for(
        %Credentials{} = %{client_id: client_id, jwt_token: token},
        channel_id,
        message
      ) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", client_id},
      {"Authorization", "Bearer #{token}"}
    ]

    body =
      Jason.encode!(%{
        message: Jason.encode!(message),
        content_type: "application/json",
        targets: ["broadcast"]
      })

    encode_url_and_params("https://api.twitch.tv/extensions/message/" <> channel_id)
    |> HTTPoison.post(body, headers)
  end
end
