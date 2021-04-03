defmodule Twitch.Extension.Credentials do
  @type t :: %__MODULE__{
          client_id: String.t(),
          token_secret: String.t(),
          jwt_token: any
        }
  defstruct [:client_id, :token_secret, :jwt_token]
end
