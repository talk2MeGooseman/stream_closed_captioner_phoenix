defmodule Twitch.ExtensionProvider do
  alias Twitch.Extension.{Channel, Credentials}

  @callback get_live_channels(
              %Twitch.Extension.Credentials{
                :client_id => String.t()
              },
              String.t() | nil
            ) :: [Channel.t()]

  @callback send_pubsub_message_for(
              Credentials.t(),
              String.t(),
              Twitch.Extension.CaptionsPayload.t()
            ) ::
              {:error, HTTPoison.Error.t()}
              | {:ok, HTTPoison.Response.t()}

  @callback get_configuration_for(
              Credentials.t(),
              atom(),
              String.t()
            ) :: {:ok, HTTPoison.Response.t()}

  @callback set_configuration_for(
              Credentials.t(),
              atom(),
              String.t(),
              map()
            ) :: any
end
