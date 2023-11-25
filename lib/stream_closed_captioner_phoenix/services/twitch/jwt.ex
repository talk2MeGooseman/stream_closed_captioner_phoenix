defmodule Twitch.Jwt do
  alias Twitch.Extension.Credentials
  alias Twitch.Extension.Token

  def get_credentials,
    do: %Credentials{
      client_id: System.get_env("TWITCH_CLIENT_ID") || "",
      token_secret: Application.get_env(:stream_closed_captioner_phoenix, :twitch_token_secret)
    }

  def verify_and_validate(token) do
    credentials = get_credentials()
    signer = create_signer(credentials)

    Token.verify_and_validate(token, signer)
  end

  @spec sign_token_for(:pubsub | :standard, String.t()) :: %Twitch.Extension.Credentials{
          client_id: binary,
          token_secret: binary,
          jwt_token: term()
        }
  def sign_token_for(:standard, channel_id) do
    credentials = get_credentials()
    signer = create_signer(credentials)

    claims = %{
      "role" => "external",
      "channel_id" => channel_id,
      "user_id" => "120750024"
    }

    token_with_claims = Token.generate_and_sign!(claims, signer)
    Map.put(credentials, :jwt_token, token_with_claims)
  end

  def sign_token_for(:pubsub, channel_id) do
    credentials = get_credentials()
    signer = create_signer(credentials)

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

  defp create_signer(credentials) do
    secret = credentials.token_secret |> Base.decode64!()
    Joken.Signer.create("HS256", secret)
  end
end
