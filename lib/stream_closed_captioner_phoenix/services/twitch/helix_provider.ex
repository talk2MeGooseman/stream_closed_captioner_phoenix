defmodule Twitch.HelixProvider do
  alias Twitch.Helix.{Credentials, Stream, Transaction}

  @callback get_streams(
              Credentials.t(),
              list(String.t()),
              String.t() | nil
            ) :: list(Stream.t())

  @callback get_transactions(Credentials.t()) :: list(Transaction.t())
end