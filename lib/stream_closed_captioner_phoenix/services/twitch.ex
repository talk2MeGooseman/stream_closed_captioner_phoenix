defmodule Twitch do
  @moduledoc """
  Service to communicate to Twitch via Helix of Extension APIs
  """

  alias Twitch.{Extension, Helix, Jwt, Oauth}

  @spec extension_live_channels :: list
  def extension_live_channels() do
    Jwt.get_credentials()
    |> Extension.get_live_channels()
  end

  def send_pubsub_message(channel_id, message) when is_map(message) do
    Jwt.sign_token_for(:pubsub, channel_id)
    |> Extension.send_pubsub_message_for(channel_id, message)
  end

  def get_extension_broadcaster_configuration_for(channel_id) do
    Jwt.sign_token_for(:standard, channel_id)
    |> Extension.get_configuration_for(Extension.broadcaster_segment(), channel_id)
  end

  @spec set_extension_broadcaster_configuration_for(binary, map) :: %{
          :__struct__ => HTTPoison.AsyncResponse | HTTPoison.MaybeRedirect | HTTPoison.Response,
          optional(:body) => any,
          optional(:headers) => list,
          optional(:id) => reference,
          optional(:redirect_url) => any,
          optional(:request) => HTTPoison.Request.t(),
          optional(:request_url) => any,
          optional(:status_code) => integer
        }
  def set_extension_broadcaster_configuration_for(channel_id, data) when is_map(data) do
    Jwt.sign_token_for(:standard, channel_id)
    |> Extension.set_configuration_for(Extension.broadcaster_segment(), channel_id, data)
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
