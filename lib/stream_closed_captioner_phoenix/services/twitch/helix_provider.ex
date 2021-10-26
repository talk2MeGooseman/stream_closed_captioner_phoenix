defmodule Twitch.HelixProvider do
  alias Twitch.Helix.{Credentials, Stream, Transaction}

  @callback get_streams(
              Credentials.t(),
              list(String.t()),
              String.t() | nil
            ) :: list(Stream.t())

  @callback get_transactions(Credentials.t()) :: list(Transaction.t())

  @callback get_users_active_extensions(Credentials.t()) :: map()

  @callback send_extension_chat_message(Twitch.Extension.Credentials.t(), String.t(), String.t()) ::
              tuple()
end
