defmodule Twitch.Jwt do
  alias Twitch.Extension.{Token, Credentials}

  def get_credentials,
    do: %Credentials{
      client_id: System.get_env("TWITCH_CLIENT_ID"),
      token_secret: System.get_env("TWITCH_TOKEN_SECRET")
    }

  def sign_token_for(%Credentials{} = credentials, :standard, channel_id) do
    secret = credentials.token_secret |> Base.decode64!()
    signer = Joken.Signer.create("HS256", secret)

    claims = %{
      "role" => "external",
      "channel_id" => channel_id,
      "user_id" => "120750024"
    }

    token_with_claims = Token.generate_and_sign!(claims, signer)
    Map.put(credentials, :jwt_token, token_with_claims)
  end

  def sign_token_for(%Credentials{} = credentials, :pubsub, channel_id) do
    secret = credentials.token_secret |> Base.decode64!()
    signer = Joken.Signer.create("HS256", secret)

    claims = %{
      "role" => "external",
      "channel_id" => channel_id,
      "user_id" => "120750024",
      "pubsub_perms" => %{
        "send" => [
          "broadcast"
        ]
      }
    }

    token_with_claims = Token.generate_and_sign!(claims, signer)
    Map.put(credentials, :jwt_token, token_with_claims)
  end
end
