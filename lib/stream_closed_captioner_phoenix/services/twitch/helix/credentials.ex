defmodule Twitch.Helix.Credentials do
  defstruct [:client_id, :client_secret, :access_token]

  @type t :: %__MODULE__{
          client_id: String.t(),
          client_secret: String.t(),
          access_token: String.t()
        }
end
