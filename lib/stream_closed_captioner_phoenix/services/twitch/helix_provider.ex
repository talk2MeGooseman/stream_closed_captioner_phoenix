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

  @callback get_live_channels(
              Credentials.t(),
              String.t() | nil
            ) :: [Channel.t()]

  @callback set_configuration_for(
              Twitch.Extension.Credentials.t(),
              atom(),
              String.t(),
              map()
            ) :: any

  @callback get_configuration_for(
              Twitch.Extension.Credentials.t(),
              atom(),
              String.t()
            ) :: {:ok, HTTPoison.Response.t()}
end
