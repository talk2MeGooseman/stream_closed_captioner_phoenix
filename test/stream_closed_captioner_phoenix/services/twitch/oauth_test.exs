defmodule Twitch.OauthTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: false

  import ExUnit.CaptureLog
  import StreamClosedCaptionerPhoenix.AccountsFixtures

  alias StreamClosedCaptionerPhoenix.Repo
  alias Twitch.Helix.Credentials
  alias Twitch.Oauth

  # Points Twitch identity calls (`/oauth2/validate`, `/oauth2/token`) at a local
  # Bypass server so we can exercise the real HTTP request shapes without hitting
  # api production Twitch.
  setup do
    bypass = Bypass.open()

    Application.put_env(
      :stream_closed_captioner_phoenix,
      :twitch_id_endpoint,
      "http://localhost:#{bypass.port}"
    )

    on_exit(fn ->
      Application.delete_env(:stream_closed_captioner_phoenix, :twitch_id_endpoint)
    end)

    {:ok, bypass: bypass}
  end

  defp user_with_tokens(access_token, refresh_token) do
    {:ok, user} =
      user_fixture()
      |> Ecto.Changeset.change(%{access_token: access_token, refresh_token: refresh_token})
      |> Repo.update()

    user
  end

  describe "get_users_access_token/1 when the stored token is still valid" do
    test "returns credentials with the existing token without refreshing", %{bypass: bypass} do
      user = user_with_tokens("valid_token", "refresh_token")

      Bypass.expect(bypass, fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/oauth2/validate"} ->
            Plug.Conn.resp(
              conn,
              200,
              Jason.encode!(%{"client_id" => "abc", "expires_in" => 9999})
            )

          {"POST", "/oauth2/token"} ->
            flunk("token refresh endpoint must not be called for a valid token")
        end
      end)

      assert %Credentials{access_token: "valid_token"} = Oauth.get_users_access_token(user)

      assert Repo.reload(user).access_token == "valid_token"
    end
  end

  describe "get_users_access_token/1 when the stored token is expired" do
    test "refreshes via the refresh token, persists the new tokens, and returns credentials", %{
      bypass: bypass
    } do
      user = user_with_tokens("expired_token", "refresh_token")

      Bypass.expect(bypass, fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/oauth2/validate"} ->
            Plug.Conn.resp(conn, 401, Jason.encode!(%{"message" => "invalid access token"}))

          {"POST", "/oauth2/token"} ->
            assert conn.query_params["grant_type"] == "refresh_token"
            assert conn.query_params["refresh_token"] == "refresh_token"

            Plug.Conn.resp(
              conn,
              200,
              Jason.encode!(%{
                "access_token" => "fresh_token",
                "refresh_token" => "rotated_refresh_token"
              })
            )
        end
      end)

      assert %Credentials{access_token: "fresh_token"} = Oauth.get_users_access_token(user)

      reloaded = Repo.reload(user)
      assert reloaded.access_token == "fresh_token"
      assert reloaded.refresh_token == "rotated_refresh_token"
    end

    test "returns {:error, :token_expired} and leaves tokens untouched when refresh fails", %{
      bypass: bypass
    } do
      user = user_with_tokens("expired_token", "bad_refresh_token")

      Bypass.expect(bypass, fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/oauth2/validate"} ->
            Plug.Conn.resp(conn, 401, Jason.encode!(%{"message" => "invalid access token"}))

          {"POST", "/oauth2/token"} ->
            Plug.Conn.resp(conn, 400, Jason.encode!(%{"message" => "Invalid refresh token"}))
        end
      end)

      assert {:error, :token_expired} = Oauth.get_users_access_token(user)

      reloaded = Repo.reload(user)
      assert reloaded.access_token == "expired_token"
      assert reloaded.refresh_token == "bad_refresh_token"
    end

    test "still returns the freshly-refreshed credentials (and logs sanitized) when the DB persist fails",
         %{bypass: bypass} do
      # Seam: the refresh endpoint returns an empty access_token. The upstream
      # `is_binary/1` guard passes (it is a binary), but `cast/3` coerces "" to
      # nil so `oauth_token_changeset`'s `validate_required([:access_token])`
      # makes the persist return `{:error, changeset}` without any DB raise.
      # This is the only clean seam to drive the persistence path to an error,
      # since `AccountsOauth` is called directly with no behaviour/Mox injection.
      user = user_with_tokens("expired_token", "refresh_token")

      Bypass.expect(bypass, fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/oauth2/validate"} ->
            Plug.Conn.resp(conn, 401, Jason.encode!(%{"message" => "invalid access token"}))

          {"POST", "/oauth2/token"} ->
            Plug.Conn.resp(
              conn,
              200,
              Jason.encode!(%{
                "access_token" => "",
                "refresh_token" => "rotated_refresh_token"
              })
            )
        end
      end)

      log =
        capture_log(fn ->
          # The current request still proceeds with the freshly-refreshed
          # in-memory token rather than blowing up on a failed DB write.
          assert %Credentials{access_token: ""} = Oauth.get_users_access_token(user)
        end)

      assert log =~ "Failed to persist refreshed Twitch tokens for user #{user.id}"
      # The sanitized log must NOT leak the rotated token value.
      refute log =~ "rotated_refresh_token"

      # The DB write was rejected, so the stored tokens are unchanged.
      reloaded = Repo.reload(user)
      assert reloaded.access_token == "expired_token"
      assert reloaded.refresh_token == "refresh_token"
    end

    test "returns {:error, :token_expired} without calling Twitch when no refresh token exists",
         %{
           bypass: bypass
         } do
      user = user_with_tokens("expired_token", nil)

      Bypass.expect(bypass, fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/oauth2/validate"} ->
            Plug.Conn.resp(conn, 401, Jason.encode!(%{"message" => "invalid access token"}))

          {"POST", "/oauth2/token"} ->
            flunk("token refresh must not be attempted without a refresh token")
        end
      end)

      assert {:error, :token_expired} = Oauth.get_users_access_token(user)
    end
  end
end
