defmodule Twitch.OauthProvider do
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias Twitch.Helix.Credentials

  @callback get_client_access_token() :: {:ok, Credentials.t()} | {:error, term()}

  @callback get_users_access_token(User.t()) :: Credentials.t() | {:error, term()}
end
