defmodule Twitch.Oauth do
  import Helpers

  require Logger

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias Twitch.Helix.Credentials
  alias Twitch.Parser
  alias NewRelic.Instrumented.HTTPoison

  def get_client_access_token() do
    credentials = get_credentials()

    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", credentials.client_id}
    ]

    params = %{
      client_id: credentials.client_id,
      client_secret: credentials.client_secret,
      grant_type: "client_credentials",
      scope: ""
    }

    url = encode_url_and_params("https://id.twitch.tv/oauth2/token", params)

    case HTTPoison.post(url, "", headers) do
      {:ok, %{status_code: status, body: raw_body}} when status in 200..299 ->
        case Jason.decode(raw_body) do
          {:ok, data} ->
            access_token = get_in(data, ["access_token"])
            {:ok, Map.put(credentials, :access_token, access_token)}

          {:error, reason} ->
            Logger.warning("Twitch OAuth: Failed to decode token response: #{inspect(reason)}")
            {:error, {:json_decode, reason}}
        end

      {:ok, %{status_code: status, body: body}} ->
        Logger.warning("Twitch OAuth: Token request returned HTTP #{status}: #{inspect(String.slice(body, 0, 200))}")
        {:error, {:http_status, status}}

      {:error, %{reason: reason}} ->
        Logger.warning("Twitch OAuth: HTTP request failed: #{inspect(reason)}")
        {:error, {:http, reason}}
    end
  end

  def get_users_access_token(%User{} = user) do
    credentials = get_credentials()

    case validate_token(user.access_token) do
      {:ok, _} ->
        Map.put(credentials, :access_token, user.access_token)

      {:error, _body, _status} ->
        Logger.warning("Twitch OAuth: Token validation failed for user #{user.id}")
        {:error, :token_expired}

      {:error, _} ->
        Logger.warning("Twitch OAuth: Token validation failed for user #{user.id}")
        {:error, :token_expired}
    end
  end

  defp validate_token(access_token) do
    headers = [
      {"Authorization", "OAuth #{access_token}"}
    ]

    encode_url_and_params("https://id.twitch.tv/oauth2/validate")
    |> HTTPoison.get(headers)
    |> Parser.parse()
  end

  defp get_credentials,
    do: %Credentials{
      client_id: Application.get_env(:stream_closed_captioner_phoenix, :twitch_client_id),
      client_secret: Application.get_env(:stream_closed_captioner_phoenix, :twitch_client_secret)
    }
end
