defmodule Twitch.ExtensionProvider do
  alias Twitch.Extension.{Channel, Credentials}

  @callback send_pubsub_message_for(
              Credentials.t(),
              String.t(),
              Twitch.Extension.CaptionsPayload.t()
            ) ::
              {:error, HTTPoison.Error.t()}
              | {:ok, HTTPoison.Response.t()}
end
