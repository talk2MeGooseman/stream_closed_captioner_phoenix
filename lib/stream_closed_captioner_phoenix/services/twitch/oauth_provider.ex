defmodule Twitch.OauthProvider do
  @moduledoc """
  Behaviour for the Twitch OAuth client. Provides a seam for injecting a
  test double via application config without touching production code paths.
  """

  alias Twitch.Helix.Credentials

  @callback get_client_access_token() :: {:ok, Credentials.t()} | {:error, term()}
end
