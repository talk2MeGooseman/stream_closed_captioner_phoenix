defmodule Twitch.OauthProvider do
  alias Twitch.Helix.Credentials

  @callback get_client_access_token() :: {:ok, Credentials.t()} | {:error, term()}
end
