defmodule StreamClosedCaptionerPhoenix.AccountsOauthTest do
  import StreamClosedCaptionerPhoenix.Factory

  use StreamClosedCaptionerPhoenix.DataCase, async: false
  import StreamClosedCaptionerPhoenix.AuditHelpers
  import StreamClosedCaptionerPhoenix.AccountsFixtures

  alias StreamClosedCaptionerPhoenix.AccountsOauth

  setup do
    StreamClosedCaptionerPhoenix.Cache.delete_all()

    :ok
  end

  describe "find_or_register_user_with_oauth/2" do
    test "when no current user, creates a new user with settings" do
      attrs = %{
        "id" => "12345",
        "email" => "test@email.com",
        "display_name" => "talk2megooseman",
        "login" => "talk2megooseman",
        "profile_image_url" => "https://image.com",
        "description" => "hello world",
        "offline_image_url" => "https://image.com"
      }

      creds = %{
        :access_token => "12345",
        :refresh_token => "12345"
      }

      {:ok, data} =
        capture_audit_events(fn ->
          AccountsOauth.find_or_register_user_with_oauth(attrs, creds, nil)
        end)

      assert data.user.email == attrs["email"]
      assert data.user.uid == attrs["id"]
      assert data.user.provider == "twitch"
      assert data.user.access_token == "12345"

      assert StreamClosedCaptionerPhoenix.Settings.get_stream_settings_by_user_id!(data.user.id)
      assert_audit_event("oauth.account_registered")
    end

    test "when no current user, finds a user with matching information" do
      attrs = %{
        "id" => "12345",
        "email" => "test@email.com",
        "display_name" => "newusername",
        "login" => "newusername",
        "profile_image_url" => "https://image.com",
        "description" => "hello world",
        "offline_image_url" => "https://image.com"
      }

      creds = %{
        :token => "12345",
        :refresh_token => "12345"
      }

      insert(:user, uid: attrs["id"], provider: "twitch")

      {:ok, data} =
        capture_audit_events(fn ->
          AccountsOauth.find_or_register_user_with_oauth(attrs, creds, nil)
        end)

      assert data.user.uid == attrs["id"]
      refute data.user.email == attrs["email"]
      assert data.user.username == attrs["display_name"]
      assert data.user.description == attrs["description"]
      assert data.user.provider == "twitch"
      assert data.user.access_token == "12345"
      assert_audit_event("oauth.account_refreshed")
    end

    test "when current user, connects twitch account if not already connected else where" do
      attrs = %{
        "id" => "12345",
        "email" => "test@email.com",
        "display_name" => "newusername",
        "login" => "newusername",
        "profile_image_url" => "https://image.com",
        "description" => "hello world",
        "offline_image_url" => "https://image.com"
      }

      creds = %{
        :access_token => "12345",
        :refresh_token => "12345"
      }

      user = insert(:user, uid: nil, provider: nil)

      {:ok, data} =
        capture_audit_events(fn ->
          AccountsOauth.find_or_register_user_with_oauth(attrs, creds, user)
        end)

      assert data.user.uid == attrs["id"]
      refute data.user.email == attrs["email"]
      assert data.user.username == attrs["display_name"]
      assert data.user.description == attrs["description"]
      assert data.user.provider == "twitch"
      assert data.user.access_token == "12345"
      assert_audit_event("oauth.account_linked")
    end

    test "when current user, doesnt connect twitch accoutn if linked with another user" do
      attrs = %{
        "id" => "12345",
        "email" => "test@email.com",
        "display_name" => "newusername",
        "login" => "newusername",
        "profile_image_url" => "https://image.com",
        "description" => "hello world",
        "offline_image_url" => "https://image.com"
      }

      creds = %{
        :access_token => "12345",
        :refresh_token => "12345"
      }

      insert(:user, uid: attrs["id"], provider: "twitch")
      current_user = insert(:user, uid: nil, provider: nil)

      result =
        capture_audit_events(fn ->
          AccountsOauth.find_or_register_user_with_oauth(attrs, creds, current_user)
        end)

      assert {:error, _message} = result
      assert_audit_event("oauth.account_link_failed_already_linked")
    end

    test "when no current user, fails to register when uid conflicts with an existing user" do
      existing = insert(:user)

      attrs = %{
        "id" => existing.uid,
        "email" => unique_user_email(),
        "display_name" => "talk2megooseman",
        "login" => "talk2megooseman",
        "profile_image_url" => "https://image.com",
        "description" => "hello world",
        "offline_image_url" => "https://image.com"
      }

      creds = %{
        :access_token => "12345",
        :refresh_token => "12345"
      }

      result =
        capture_audit_events(fn ->
          AccountsOauth.find_or_register_user_with_oauth(attrs, creds, nil)
        end)

      assert {:error, _, _changeset, _} = result
      assert_audit_event("oauth.account_register_failed")
    end

    test "when current user, fails to link when required oauth fields are missing" do
      attrs = %{
        "id" => "12345",
        "email" => "test@email.com",
        "login" => "talk2megooseman",
        "profile_image_url" => "https://image.com",
        "description" => "hello world",
        "offline_image_url" => "https://image.com"
      }

      creds = %{
        :access_token => "12345",
        :refresh_token => "12345"
      }

      current_user = insert(:user, uid: nil, provider: nil)

      result =
        capture_audit_events(fn ->
          AccountsOauth.find_or_register_user_with_oauth(attrs, creds, current_user)
        end)

      assert {:error, _changeset} = result
      assert_audit_event("oauth.account_link_failed")
    end

    test "when no current user, fails to link when email matches a different existing account" do
      existing = insert(:user)

      attrs = %{
        "id" => "different-uid-12345",
        "email" => existing.email,
        "display_name" => "talk2megooseman",
        "login" => "talk2megooseman",
        "profile_image_url" => "https://image.com",
        "description" => "hello world",
        "offline_image_url" => "https://image.com"
      }

      creds = %{
        :access_token => "12345",
        :refresh_token => "12345"
      }

      result =
        capture_audit_events(fn ->
          AccountsOauth.find_or_register_user_with_oauth(attrs, creds, nil)
        end)

      assert {:error, _message} = result
      assert_audit_event("oauth.account_link_failed_email_conflict")
    end
  end
end
