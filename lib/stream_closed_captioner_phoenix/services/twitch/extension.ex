defmodule Twitch.Extension do
  import Helpers

  alias Twitch.ExtensionProvider
  alias Twitch.Extension.{Channel, Credentials}
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
  def get_live_channels(%Credentials{} = credentials, current_cursor \\ nil) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", credentials.client_id}
    ]

    data =
      encode_url_and_params(
        "https://api.twitch.tv/extensions/" <>
          credentials.client_id <> "/live_activated_channels",
        %{cursor: current_cursor}
      )
      |> HTTPoison.get!(headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()

    new_cursor = get_in(data, ["cursor"])

    if is_binary(new_cursor) && current_cursor != new_cursor do
      get_live_channels(credentials, new_cursor) ++
        Enum.map(get_in(data, ["channels"]), &Channel.new/1)
    else
      Enum.map(get_in(data, ["channels"]), &Channel.new/1)
    end
  end

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

  @impl ExtensionProvider
  def get_configuration_for(
        %Credentials{} = %{client_id: client_id, jwt_token: token},
        segment,
        channel_id
      ) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", client_id},
      {"Authorization", "Bearer #{token}"}
    ]

    ("https://api.twitch.tv/extensions/" <>
       client_id <> "/configurations/segments/" <> to_string(segment))
    |> encode_url_and_params(%{channel_id: channel_id})
    |> HTTPoison.get!(headers)
    |> Map.fetch!(:body)
    |> Jason.decode!()
  end

  @impl ExtensionProvider
  def set_configuration_for(
        %Credentials{} = %{client_id: client_id, jwt_token: token},
        segment,
        channel_id,
        data
      ) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", client_id},
      {"Authorization", "Bearer #{token}"}
    ]

    body =
      Jason.encode!(%{
        channel_id: channel_id,
        segment: to_string(segment),
        content: Jason.encode!(data)
      })

    ("https://api.twitch.tv/extensions/" <> client_id <> "/configurations")
    |> encode_url_and_params()
    |> HTTPoison.put(body, headers)
  end
end
