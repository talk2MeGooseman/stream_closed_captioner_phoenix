defmodule Twitch.Oauth do
  import Helpers

  require Logger

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.AccountsOauth
  alias Twitch.Helix.Credentials
  alias Twitch.Parser

  @behaviour Twitch.OauthProvider

  # Base URL for Twitch's identity service. Overridable in tests (e.g. to a
  # Bypass server) via `config :stream_closed_captioner_phoenix, :twitch_id_endpoint`.
  defp id_endpoint,
    do:
      Application.get_env(
        :stream_closed_captioner_phoenix,
        :twitch_id_endpoint,
        "https://id.twitch.tv"
      )

  @impl Twitch.OauthProvider
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

    url = encode_url_and_params("#{id_endpoint()}/oauth2/token", params)

    case Req.post(url, [body: "", headers: headers] ++ req_options()) do
      {:ok, %{status: status, body: raw_body}} when status in 200..299 ->
        case Jason.decode(raw_body) do
          {:ok, data} ->
            access_token = get_in(data, ["access_token"])
            {:ok, Map.put(credentials, :access_token, access_token)}

          {:error, reason} ->
            Logger.warning("Twitch OAuth: Failed to decode token response: #{inspect(reason)}")
            {:error, {:json_decode, reason}}
        end

      {:ok, %{status: status, body: body}} ->
        Logger.warning(
          "Twitch OAuth: Token request returned HTTP #{status}: #{inspect(String.slice(body, 0, 200))}"
        )

        {:error, {:http_status, status}}

      {:error, %{reason: reason}} ->
        Logger.warning("Twitch OAuth: HTTP request failed: #{inspect(reason)}")
        {:error, {:http, reason}}
    end
  end

  @impl Twitch.OauthProvider
  def get_users_access_token(%User{} = user) do
    case validate_token(user.access_token) do
      {:ok, _} ->
        build_credentials(user.access_token)

      _ ->
        refresh_and_persist(user)
    end
  end

  # Twitch user access tokens expire (~4 hours). When validation fails, exchange
  # the stored refresh token for a fresh pair, persist it, and use the new token.
  # Only give up (forcing re-login) when there's no refresh token or the refresh
  # itself is rejected.
  defp refresh_and_persist(%User{refresh_token: refresh_token} = user)
       when is_binary(refresh_token) do
    case refresh_users_access_token(refresh_token) do
      {:ok, %{access_token: new_access_token} = tokens}
      when is_binary(new_access_token) and byte_size(new_access_token) > 0 ->
        # Persist the refreshed pair. If the DB write fails we deliberately log a
        # FIXED, token-free message (a failed changeset carries the token in its
        # changes — never inspect/log it) and still proceed with the freshly
        # refreshed in-memory token so the current request can succeed.
        case AccountsOauth.update_user_oauth_tokens(user, %{
               access_token: new_access_token,
               refresh_token: tokens[:refresh_token] || refresh_token
             }) do
          {:ok, _user} ->
            :ok

          # Intentionally defensive: a DB persist failure on an otherwise-valid
          # token is hard to trigger without a real constraint, so this branch is
          # not unit-covered. Don't re-introduce a blank-token seam to test it —
          # blank tokens are now rejected by the guard above before reaching here.
          {:error, _changeset} ->
            Logger.warning("Failed to persist refreshed Twitch tokens for user #{user.id}")
        end

        build_credentials(new_access_token)

      {:error, reason} ->
        Logger.warning(
          "Twitch OAuth: Token refresh failed for user #{user.id}: #{inspect(reason)}"
        )

        {:error, :token_expired}

      _ ->
        Logger.warning("Twitch OAuth: Token refresh returned no access token for user #{user.id}")
        {:error, :token_expired}
    end
  end

  defp refresh_and_persist(%User{} = user) do
    Logger.warning(
      "Twitch OAuth: Token validation failed for user #{user.id} and no refresh token is available"
    )

    {:error, :token_expired}
  end

  @doc """
  Exchanges a Twitch refresh token for a fresh access/refresh token pair.

  Returns `{:ok, %{access_token: ..., refresh_token: ...}}` on success. The
  `refresh_token` in the response may be `nil` if Twitch did not rotate it.
  """
  @spec refresh_users_access_token(binary()) ::
          {:ok, %{access_token: binary() | nil, refresh_token: binary() | nil}} | {:error, term()}
  def refresh_users_access_token(refresh_token) do
    credentials = get_credentials()

    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", credentials.client_id}
    ]

    params = %{
      client_id: credentials.client_id,
      client_secret: credentials.client_secret,
      grant_type: "refresh_token",
      refresh_token: refresh_token
    }

    url = encode_url_and_params("#{id_endpoint()}/oauth2/token", params)

    case Req.post(url, [body: "", headers: headers] ++ req_options()) do
      {:ok, %{status: status, body: raw_body}} when status in 200..299 ->
        case Jason.decode(raw_body) do
          {:ok, data} ->
            {:ok,
             %{
               access_token: Map.get(data, "access_token"),
               refresh_token: Map.get(data, "refresh_token")
             }}

          {:error, reason} ->
            Logger.warning("Twitch OAuth: Failed to decode refresh response: #{inspect(reason)}")
            {:error, {:json_decode, reason}}
        end

      {:ok, %{status: status, body: body}} ->
        Logger.warning(
          "Twitch OAuth: Refresh request returned HTTP #{status}: #{inspect(String.slice(body, 0, 200))}"
        )

        {:error, {:http_status, status}}

      {:error, %{reason: reason}} ->
        Logger.warning("Twitch OAuth: Refresh HTTP request failed: #{inspect(reason)}")
        {:error, {:http, reason}}
    end
  end

  defp build_credentials(access_token) do
    Map.put(get_credentials(), :access_token, access_token)
  end

  defp validate_token(access_token) do
    headers = [
      {"Authorization", "OAuth #{access_token}"}
    ]

    encode_url_and_params("#{id_endpoint()}/oauth2/validate")
    |> Req.get([headers: headers] ++ req_options())
    |> Parser.parse()
  end

  defp get_credentials,
    do: %Credentials{
      client_id: Application.get_env(:stream_closed_captioner_phoenix, :twitch_client_id),
      client_secret: Application.get_env(:stream_closed_captioner_phoenix, :twitch_client_secret)
    }
end
