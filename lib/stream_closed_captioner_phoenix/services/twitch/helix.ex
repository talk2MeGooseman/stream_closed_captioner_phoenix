defmodule Twitch.Helix do
  import Helpers

  require Logger

  alias NewRelic.Instrumented.HTTPoison
  alias Twitch.HelixProvider
  alias Twitch.Helix.{Credentials, Stream, Transaction, ExtensionChannel, EventSub}
  alias Twitch.HttpHelpers

  @behaviour Twitch.HelixProvider

  @impl HelixProvider
  def get_streams(
        %{access_token: access_token} = credentials,
        user_ids,
        cursor \\ nil
      ) do
    headers = HttpHelpers.auth_request_headers(access_token)

    user_tuple_list = Enum.map(user_ids, fn user_id -> {:user_id, user_id} end)

    case encode_url_and_params("https://api.twitch.tv/helix/streams", user_tuple_list)
         |> HTTPoison.get(headers) do
      {:ok, %{body: raw_body}} ->
        case Jason.decode(raw_body) do
          {:ok, data} ->
            new_cursor = get_in(data, ["pagination", "cursor"])

            if is_binary(new_cursor) && new_cursor != cursor do
              get_streams(credentials, user_ids, cursor) ++
                Enum.map(get_in(data, ["data"]), &Stream.new/1)
            else
              Enum.map(get_in(data, ["data"]) || [], &Stream.new/1)
            end

          {:error, reason} ->
            Logger.warning("Twitch Helix get_streams decode failed: #{inspect(reason)}")
            []
        end

      {:error, %{reason: reason}} ->
        Logger.warning("Twitch Helix get_streams request failed: #{inspect(reason)}")
        []
    end
  end

  @impl HelixProvider
  def get_transactions(%Credentials{} = %{client_id: client_id, access_token: access_token}) do
    headers = HttpHelpers.auth_request_headers(access_token)

    case encode_url_and_params("https://api.twitch.tv/helix/extensions/transactions", %{
           extension_id: client_id
         })
         |> HTTPoison.get(headers) do
      {:ok, %{body: raw_body}} ->
        case Jason.decode(raw_body) do
          {:ok, data} -> Enum.map(get_in(data, ["data"]) || [], &Transaction.new/1)
          {:error, _} -> []
        end

      {:error, %{reason: reason}} ->
        Logger.warning("Twitch Helix get_transactions request failed: #{inspect(reason)}")
        []
    end
  end

  @impl HelixProvider
  def get_users_active_extensions(%Credentials{} = %{access_token: access_token}) do
    headers = HttpHelpers.auth_request_headers(access_token)

    case encode_url_and_params("https://api.twitch.tv/helix/users/extensions")
         |> HTTPoison.get(headers) do
      {:ok, %{body: raw_body}} ->
        case Jason.decode(raw_body) do
          {:ok, data} -> Map.get(data, "data")
          {:error, _} -> nil
        end

      {:error, %{reason: reason}} ->
        Logger.warning(
          "Twitch Helix get_users_active_extensions request failed: #{inspect(reason)}"
        )

        nil
    end
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

    url =
      encode_url_and_params(
        "https://api.twitch.tv/helix/extensions/chat",
        %{broadcaster_id: broadcaster_id}
      )

    case HTTPoison.post(url, body, headers) do
      {:ok, %{body: raw_body}} ->
        raw_body

      {:error, %{reason: reason}} ->
        Logger.warning("Twitch Helix chat message request failed: #{inspect(reason)}")
        {:error, {:http, reason}}
    end
  end

  @impl HelixProvider
  def get_live_channels(
        %Credentials{} = %{access_token: access_token} = credentials,
        current_cursor \\ nil
      ) do
    headers = HttpHelpers.auth_request_headers(access_token)

    case encode_url_and_params(
           "https://api.twitch.tv/helix/extensions/live",
           %{
             first: 100,
             after: current_cursor,
             extension_id: Twitch.extension_id()
           }
         )
         |> HTTPoison.get(headers) do
      {:ok, %{body: raw_body}} ->
        case Jason.decode(raw_body) do
          {:ok, data} ->
            new_cursor = get_in(data, ["pagination"])

            if is_binary(new_cursor) && current_cursor != new_cursor do
              get_live_channels(credentials, new_cursor) ++
                Enum.map(get_in(data, ["channels"]) || [], &ExtensionChannel.new/1)
            else
              Enum.map(get_in(data, ["channels"]) || [], &ExtensionChannel.new/1)
            end

          {:error, reason} ->
            Logger.warning("Twitch Helix get_live_channels decode failed: #{inspect(reason)}")
            []
        end

      {:error, %{reason: reason}} ->
        Logger.warning("Twitch Helix get_live_channels request failed: #{inspect(reason)}")
        []
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

    case "https://api.twitch.tv/helix/extensions/configurations"
         |> encode_url_and_params(%{
           broadcaster_id: channel_id,
           extension_id: Twitch.extension_id(),
           segment: to_string(segment)
         })
         |> HTTPoison.get(headers) do
      {:ok, %{body: raw_body}} ->
        Jason.decode!(raw_body)

      {:error, %{reason: reason}} ->
        Logger.warning("Twitch Helix get_configuration_for request failed: #{inspect(reason)}")
        %{}
    end
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

    url = encode_url_and_params("https://api.twitch.tv/helix/eventsub/subscriptions")

    case HTTPoison.post(url, body, headers) do
      {:ok, %{body: raw_body}} ->
        case Jason.decode(raw_body) do
          {:ok, decoded} ->
            {:ok, decoded}

          {:error, reason} ->
            Logger.warning("Twitch EventSub subscribe response decode failed: #{inspect(reason)}")
            {:error, {:json_decode, reason}}
        end

      {:error, %{reason: reason}} ->
        Logger.warning("Twitch EventSub subscribe request failed: #{inspect(reason)}")
        {:error, {:http, reason}}
    end
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

    case encode_url_and_params("https://api.twitch.tv/helix/eventsub/subscriptions", params)
         |> HTTPoison.get(headers) do
      {:ok, %{body: raw_body}} ->
        case Jason.decode(raw_body) do
          {:ok, data} ->
            new_cursor = get_in(data, ["pagination", "cursor"])

            if is_binary(new_cursor) && new_cursor != cursor do
              get_eventsub_subscriptions(auth, type, new_cursor) ++
                Enum.map(get_in(data, ["data"]) || [], &EventSub.new/1)
            else
              Enum.map(get_in(data, ["data"]) || [], &EventSub.new/1)
            end

          {:error, reason} ->
            Logger.warning(
              "Twitch Helix get_eventsub_subscriptions decode failed: #{inspect(reason)}"
            )

            []
        end

      {:error, %{reason: reason}} ->
        Logger.warning(
          "Twitch Helix get_eventsub_subscriptions request failed: #{inspect(reason)}"
        )

        []
    end
  end

  @impl HelixProvider
  def delete_eventsub_subscription(
        %{access_token: access_token},
        id
      ) do
    headers = HttpHelpers.auth_request_headers(access_token)

    case encode_url_and_params("https://api.twitch.tv/helix/eventsub/subscriptions", %{id: id})
         |> HTTPoison.delete(headers) do
      {:ok, %{status_code: status_code}} ->
        status_code

      {:error, %{reason: reason}} ->
        Logger.warning(
          "Twitch Helix delete_eventsub_subscription request failed: #{inspect(reason)}"
        )

        nil
    end
  end
end
