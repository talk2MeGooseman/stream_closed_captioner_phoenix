defmodule Twitch do
  @moduledoc """
  Service to communicate to Twitch via Helix of Extension APIs
  """

  alias Twitch.{Extension, Helix, Jwt, Oauth}

  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :twitch_extension_client)

  @spec extension_live_channels :: list
  def extension_live_channels() do
    Jwt.get_credentials()
    |> api_client().get_live_channels()
  end

  def send_pubsub_message(payload, channel_id) when is_map(payload) do
    Jwt.sign_token_for(:pubsub, channel_id)
    |> api_client().send_pubsub_message_for(channel_id, payload)
  end

  @spec get_extension_broadcaster_configuration_for(binary) :: any
  def get_extension_broadcaster_configuration_for(channel_id) do
    Jwt.sign_token_for(:standard, channel_id)
    |> api_client().get_configuration_for(Extension.broadcaster_segment(), channel_id)
  end

  @spec set_extension_broadcaster_configuration_for(binary, map) :: {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t | HTTPoison.MaybeRedirect.t} | {:error, HTTPoison.Error.t}
  def set_extension_broadcaster_configuration_for(channel_id, data) when is_map(data) do
    Jwt.sign_token_for(:standard, channel_id)
    |> api_client().set_configuration_for(Extension.broadcaster_segment(), channel_id, data)
  end

  @spec get_live_streams(list(binary())) :: list
  def get_live_streams(user_ids) do
    Oauth.get_client_access_token()
    |> Helix.get_streams(user_ids)
  end

  @spec get_extension_transactons() :: list
  def get_extension_transactons() do
    Oauth.get_client_access_token()
    |> Helix.get_transactions()
  end
end
