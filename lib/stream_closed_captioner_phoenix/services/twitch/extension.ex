defmodule Twitch.Extension do
  import Helpers

  require Logger

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

    url = encode_url_and_params("https://api.twitch.tv/extensions/message/" <> channel_id)

    case Req.post(url, [body: body, headers: headers] ++ req_options()) do
      {:ok, %{status: status, body: response_body}} ->
        {:ok, %{status: status, body: response_body}}

      {:error, exception} ->
        Logger.warning(
          "Twitch Extension send_pubsub_message_for request failed: #{inspect(exception)}"
        )

        {:error, %{reason: Map.get(exception, :reason, exception)}}
    end
  end
end
