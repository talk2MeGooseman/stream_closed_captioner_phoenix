defmodule Twitch.Extension do
  import Helpers

  alias Twitch.Extension.{Channel, Credentials}

  @broadcaster :broadcaster
  @spec broadcaster_segment :: :broadcaster
  def broadcaster_segment, do: @broadcaster

  @global :global
  @spec global_segment :: :global
  def global_segment, do: @global

  @developer :developer
  @spec developer_segment :: :developer
  def developer_segment, do: @developer

  @spec get_live_channels(
          %Twitch.Extension.Credentials{
            :client_id => String.t()
          },
          String.t() | nil
        ) :: list
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

  @spec send_pubsub_message_for(
          %Twitch.Extension.Credentials{
            :client_id => any,
            :jwt_token => any
          },
          String.t(),
          Twitch.Extension.CaptionsPayload.t()
        ) ::
          {:error, HTTPoison.Error.t()}
          | {:ok,
             %{
               :__struct__ =>
                 HTTPoison.AsyncResponse | HTTPoison.MaybeRedirect | HTTPoison.Response,
               optional(:body) => any,
               optional(:headers) => list,
               optional(:id) => reference,
               optional(:redirect_url) => any,
               optional(:request) => HTTPoison.Request.t(),
               optional(:request_url) => any,
               optional(:status_code) => integer
             }}
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

  @spec get_configuration_for(
          %Twitch.Extension.Credentials{
            :client_id => String.t(),
            :jwt_token => term()
          },
          atom(),
          String.t()
        ) :: any
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
