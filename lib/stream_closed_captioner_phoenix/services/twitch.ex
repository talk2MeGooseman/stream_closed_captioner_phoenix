defmodule Twitch do
  @moduledoc """
  Service to communicate to Twitch via Helix of Extension APIs
  """
  use Nebulex.Caching

  @extension_id "h1ekceo16erc49snp0sine3k9ccbh9"

  require Logger

  alias Twitch.{Extension, Jwt, Oauth}

  @doc """
  Get the extension's id
  """
  def extension_id, do: @extension_id

  @spec ext_api_client :: Twitch.ExtensionProvider
  def ext_api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :twitch_extension_client)

  @spec helix_api_client :: Twitch.HelixProvider
  def helix_api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :twitch_helix_client)

  @spec extension_live_channels :: list
  def extension_live_channels() do
    Oauth.get_client_access_token()
    |> helix_api_client().get_live_channels()
  end

  def send_pubsub_message(_payload, channel_id) when is_nil(channel_id),
    do: {:error, "Missing Channel ID"}

  def send_pubsub_message(payload, channel_id) when is_map(payload) do
    Jwt.sign_token_for(:pubsub, channel_id)
    |> ext_api_client().send_pubsub_message_for(channel_id, payload)
    |> case do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok, payload}

      {:ok, %HTTPoison.Response{status_code: 400, body: _body}} ->
        Logger.debug("Request was rejected")
        {:error, "Request was rejected"}

      {:ok, %HTTPoison.Response{status_code: 500, body: _body}} ->
        Logger.debug("Twitch doing Twitch stuff")
        {:error, "500, Twitch throwing errors for some reason."}

      {:ok, %HTTPoison.Response{status_code: 502, body: _body}} ->
        Logger.debug("Twitch doing Twitch stuff")
        {:error, "502, cant reach Twitch atm."}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.debug("Request was error")
        {:error, reason}
    end
  end

  @spec get_extension_broadcaster_configuration_for(binary) :: any
  def get_extension_broadcaster_configuration_for(channel_id) do
    Jwt.sign_token_for(:standard, channel_id)
    |> ext_api_client().get_configuration_for(Extension.broadcaster_segment(), channel_id)
  end

  @spec set_extension_broadcaster_configuration_for(binary, map) ::
          {:ok,
           HTTPoison.Response.t() | HTTPoison.AsyncResponse.t() | HTTPoison.MaybeRedirect.t()}
          | {:error, HTTPoison.Error.t()}
  def set_extension_broadcaster_configuration_for(channel_id, data) when is_map(data) do
    Jwt.sign_token_for(:standard, channel_id)
    |> helix_api_client().set_configuration_for(Extension.broadcaster_segment(), channel_id, data)
  end

  @doc """
  Get the live streams for a list of user ids

  Twitch API only allows 100 user ids per request, so we chunk the list
  and make multiple requests.

  # Examples
      iex(18)> Twitch.get_live_streams(["123", "456"])
      [
        %Twitch.Helix.Stream{
          game_id: "509658",
          game_name: "Just Chatting",
          id: "123",
          language: "en",
          started_at: "2020-05-01T00:00:00Z",
          thumbnail_url: "https://static-cdn.jtvnw.net/previews-ttv/live_user_123-{width}x{height}.jpg",
          title: "Just chatting",
          type: "live",
          user_id: "123",
          user_login: "123",
          user_name: "123",
          viewer_count: 123
        },
        %Twitch.Helix.Stream{
          game_id: "509658",
          game_name: "Just Chatting",
          id: "456",
          language: "en",
          started_at: "2020-05-01T00:00:00Z",
          thumbnail_url: "https://static-cdn.jtvnw.net/previews-ttv/live_user_456-{width}x{height}.jpg",
          title: "Just chatting",
          type: "live",
          user_id: "456",
          user_login: "456",
          user_name: "456",
          viewer_count: 456
        }
      ]
  """
  @spec get_live_streams(list(binary())) :: list(Twitch.Helix.Stream.t())
  def get_live_streams([]), do: []

  # @decorate cacheable(
  #             cache: Cache,
  #             key: "twitch:live_streams",
  #             ttl: 300_000
  #           )
  def get_live_streams(user_ids) do
    chunked_user_ids = Enum.chunk_every(user_ids, 80)

    Enum.flat_map(chunked_user_ids, fn uids ->
      Oauth.get_client_access_token()
      |> helix_api_client().get_streams(uids)
    end)
    |> Enum.sort_by(& &1.user_id, :desc)
    |> Enum.dedup_by(fn stream -> stream.user_id end)
    |> Enum.sort_by(& &1.viewer_count, :desc)
  end

  @spec get_extension_transactons() :: list
  def get_extension_transactons() do
    Oauth.get_client_access_token()
    |> helix_api_client().get_transactions()
  end

  @doc """
  Get all active extensions and user channel has.

  # Examples
      iex(19)> Twitch.get_users_active_extensions(user)
      %{
        "component" => %{
          "1" => %{
            "active" => true,
            "id" => "d4uvtfdr04uq6raoenvj7m86gdk16v",
            "name" => "Prime Subscription and Loot Reminder",
            "version" => "2.2.41",
            "x" => 0,
            "y" => 0
          },
          "2" => %{"active" => false}
        },
        "overlay" => %{
          "1" => %{
            "active" => true,
            "id" => "h1ekceo16erc49snp0sine3k9ccbh9",
            "name" => "Stream Closed Captioner",
            "version" => "1.6.1"
          }
        },
        "panel" => %{
          "1" => %{"active" => false},
          "2" => %{
            "active" => true,
            "id" => "d4t75sazjvk9cc84h30mgkyg7evbvz",
            "name" => "Stream Team",
            "version" => "1.1.1"
          },
          "3" => %{
            "active" => true,
            "id" => "uaw3vx1k0ttq74u9b2zfvt768eebh1",
            "name" => "StreamElements Leaderboards",
            "version" => "0.4.1"
          }
        }
      }

  """
  def get_users_active_extensions(user) do
    Oauth.get_users_access_token(user)
    |> helix_api_client().get_users_active_extensions()
  end

  def send_extension_chat_message(channel_id, message) do
    Jwt.sign_token_for(:standard, channel_id)
    |> helix_api_client().send_extension_chat_message(channel_id, message)
  end

  def event_subscribe(type, broadcaster_id) do
    Oauth.get_client_access_token()
    |> helix_api_client().eventsub_subscribe("webhook", type, "1", %{
      broadcaster_user_id: broadcaster_id
    })
  end

  @spec event_subscribe(String.t()) :: any
  def event_subscribe("extension.bits_transaction.create" = type) do
    Oauth.get_client_access_token()
    |> helix_api_client().eventsub_subscribe(
      "webhook",
      type,
      "1",
      %{
        extension_client_id: Twitch.HttpHelpers.client_id()
      }
    )
  end

  @spec get_event_subscriptions(String.t()) :: any
  def get_event_subscriptions(type) do
    Oauth.get_client_access_token()
    |> helix_api_client().get_eventsub_subscriptions(type)
  end

  @spec delete_event_subscription(String.t()) :: any
  def delete_event_subscription(id) do
    Oauth.get_client_access_token()
    |> helix_api_client().delete_eventsub_subscription(id)
  end
end
