defmodule Twitch do
  @moduledoc """
  Service to communicate to Twitch via Helix of Extension APIs
  """

  require Logger

  alias Twitch.{Extension, Helix, Jwt, Oauth}

  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :twitch_extension_client)

  @spec extension_live_channels :: list
  def extension_live_channels() do
    Jwt.get_credentials()
    |> api_client().get_live_channels()
  end

  def send_pubsub_message(_payload, channel_id) when is_nil(channel_id),
    do: {:error, "Missing Channel ID"}

  def send_pubsub_message(payload, channel_id) when is_map(payload) do
    Jwt.sign_token_for(:pubsub, channel_id)
    |> api_client().send_pubsub_message_for(channel_id, payload)
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
    |> api_client().get_configuration_for(Extension.broadcaster_segment(), channel_id)
  end

  @spec set_extension_broadcaster_configuration_for(binary, map) ::
          {:ok,
           HTTPoison.Response.t() | HTTPoison.AsyncResponse.t() | HTTPoison.MaybeRedirect.t()}
          | {:error, HTTPoison.Error.t()}
  def set_extension_broadcaster_configuration_for(channel_id, data) when is_map(data) do
    Jwt.sign_token_for(:standard, channel_id)
    |> api_client().set_configuration_for(Extension.broadcaster_segment(), channel_id, data)
  end

  @spec get_live_streams(list(binary())) :: list(Twitch.Helix.Stream.t())
  def get_live_streams([]), do: []

  def get_live_streams(user_ids) do
    chunked_user_ids = Enum.chunk_every(user_ids, 80)

    Enum.flat_map(chunked_user_ids, fn uids ->
      Oauth.get_client_access_token()
      |> Helix.get_streams(uids)
    end)
  end

  @spec get_extension_transactons() :: list
  def get_extension_transactons() do
    Oauth.get_client_access_token()
    |> Helix.get_transactions()
  end

  @doc """
  Get all active extensions and user channel has.

  # Examples
      iex(19)> StreamClosedCaptionerPhoenix.Accounts.user_has_extension_installed?(user)
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
    |> Helix.get_users_active_extensions()
  end
end
