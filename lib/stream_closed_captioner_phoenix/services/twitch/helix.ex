defmodule Twitch.Helix do
  import Helpers

  alias NewRelic.Instrumented.HTTPoison
  alias Twitch.HelixProvider
  alias Twitch.Helix.{Credentials, Stream, Transaction, ExtensionChannel, EventSub}
  alias Twitch.HttpHelpers

  @behaviour Twitch.HelixProvider

  @impl HelixProvider
  def get_streams(
        credentials = %{access_token: access_token},
        user_ids,
        cursor \\ nil
      ) do
    headers = HttpHelpers.auth_request_headers(access_token)

    user_tuple_list = Enum.map(user_ids, fn user_id -> {:user_id, user_id} end)

    data =
      encode_url_and_params("https://api.twitch.tv/helix/streams", user_tuple_list)
      |> HTTPoison.get!(headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()

    new_cursor = get_in(data, ["pagination", "cursor"])

    if is_binary(new_cursor) && new_cursor != cursor do
      get_streams(credentials, user_ids, cursor) ++
        Enum.map(get_in(data, ["data"]), &Stream.new/1)
    else
      Enum.map(get_in(data, ["data"]), &Stream.new/1)
    end
  end

  @impl HelixProvider
  def get_transactions(%Credentials{} = %{client_id: client_id, access_token: access_token}) do
    headers = HttpHelpers.auth_request_headers(access_token)

    data =
      encode_url_and_params("https://api.twitch.tv/helix/extensions/transactions", %{
        extension_id: client_id
      })
      |> HTTPoison.get!(headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()

    Enum.map(get_in(data, ["data"]), &Transaction.new/1)
  end

  @impl HelixProvider
  def get_users_active_extensions(%Credentials{} = %{access_token: access_token}) do
    headers = HttpHelpers.auth_request_headers(access_token)

    encode_url_and_params("https://api.twitch.tv/helix/users/extensions")
    |> HTTPoison.get!(headers)
    |> Map.fetch!(:body)
    |> Jason.decode!()
    |> Map.get("data")
  end

  @impl HelixProvider
  def send_extension_chat_message(
        %{jwt_token: token},
        broadcaster_id,
        message
      ) do
    headers = HttpHelpers.auth_request_headers(token)

    body =
      Jason.encode!(%{
        text: message,
        extension_id: HttpHelpers.client_id(),
        extension_version: HttpHelpers.extension_version()
      })

    encode_url_and_params(
      "https://api.twitch.tv/helix/extensions/chat",
      %{broadcaster_id: broadcaster_id}
    )
    |> HTTPoison.post!(body, headers)
    |> Map.fetch!(:body)
  end

  @impl HelixProvider
  def get_live_channels(
        %Credentials{} = %{access_token: access_token} = credentials,
        current_cursor \\ nil
      ) do
    headers = HttpHelpers.auth_request_headers(access_token)

    data =
      encode_url_and_params(
        "https://api.twitch.tv/helix/extensions/live",
        %{
          first: 100,
          after: current_cursor,
          extension_id: Twitch.extension_id()
        }
      )
      |> HTTPoison.get!(headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()

    new_cursor = get_in(data, ["pagination"])

    if is_binary(new_cursor) && current_cursor != new_cursor do
      get_live_channels(credentials, new_cursor) ++
        Enum.map(get_in(data, ["channels"]), &ExtensionChannel.new/1)
    else
      Enum.map(get_in(data, ["channels"]), &ExtensionChannel.new/1)
    end
  end

  @impl HelixProvider
  def set_configuration_for(
        %{jwt_token: token},
        segment,
        channel_id,
        data
      ) do
    headers = HttpHelpers.auth_request_headers(token)

    body =
      Jason.encode!(%{
        extension_id: Twitch.extension_id(),
        broadcaster_id: channel_id,
        segment: to_string(segment),
        content: Jason.encode!(data)
      })

    "https://api.twitch.tv/helix/extensions/configurations"
    |> encode_url_and_params()
    |> HTTPoison.put(body, headers)
  end

  @impl HelixProvider
  def get_configuration_for(
        %{jwt_token: token},
        segment,
        channel_id
      ) do
    headers = HttpHelpers.auth_request_headers(token)

    "https://api.twitch.tv/helix/extensions/configurations"
    |> encode_url_and_params(%{
      broadcaster_id: channel_id,
      extension_id: Twitch.extension_id(),
      segment: to_string(segment)
    })
    |> HTTPoison.get!(headers)
    |> Map.fetch!(:body)
    |> Jason.decode!()
  end

  @impl HelixProvider
  def eventsub_subscribe(
        %{access_token: access_token},
        "webhook",
        type,
        version,
        condition
      ) do
    headers = HttpHelpers.auth_request_headers(access_token)
    transport = Twitch.HttpHelpers.webhook_transport()

    body =
      Jason.encode!(%{
        type: type,
        version: version,
        condition: condition,
        transport: transport
      })

    encode_url_and_params("https://api.twitch.tv/helix/eventsub/subscriptions")
    |> HTTPoison.post!(body, headers)
    |> Map.fetch!(:body)
    |> Jason.decode!()
  end

  @impl HelixProvider
  def get_eventsub_subscriptions(
        %{access_token: access_token} = auth,
        type,
        cursor \\ nil
      ) do
    headers = HttpHelpers.auth_request_headers(access_token)

    params =
      if cursor do
        %{
          enabled: true,
          type: type,
          after: cursor
        }
      else
        %{
          enabled: true,
          type: type
        }
      end

    data =
      encode_url_and_params("https://api.twitch.tv/helix/eventsub/subscriptions", params)
      |> HTTPoison.get!(headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()

    new_cursor = get_in(data, ["pagination", "cursor"])

    if is_binary(new_cursor) && new_cursor != cursor do
      get_eventsub_subscriptions(auth, type, new_cursor) ++
        Enum.map(get_in(data, ["data"]), &EventSub.new/1)
    else
      Enum.map(get_in(data, ["data"]), &EventSub.new/1)
    end
  end

  @impl HelixProvider
  def delete_eventsub_subscription(
        %{access_token: access_token},
        id
      ) do
    headers = HttpHelpers.auth_request_headers(access_token)

    encode_url_and_params("https://api.twitch.tv/helix/eventsub/subscriptions", %{id: id})
    |> HTTPoison.delete!(headers)
    |> Map.fetch!(:status_code)
  end
end
