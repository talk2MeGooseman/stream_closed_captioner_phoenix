defmodule Twitch.ExtensionProvider do
  alias Twitch.Extension.Credentials

  @callback send_pubsub_message_for(
              Credentials.t(),
              String.t(),
              Twitch.Extension.CaptionsPayload.t()
            ) ::
              {:ok, %{status: non_neg_integer(), body: binary()}} | {:error, term()}
end
