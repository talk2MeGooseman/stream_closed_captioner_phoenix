defmodule StreamClosedCaptionerPhoenix.AccountsOauthTest do
  import StreamClosedCaptionerPhoenix.Factory

  use StreamClosedCaptionerPhoenix.DataCase, async: true

  alias StreamClosedCaptionerPhoenix.AccountsOauth

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
        "access_token" => "12345",
        "refresh_token" => "12345"
      }

      {:ok, data} = AccountsOauth.find_or_register_user_with_oauth(attrs, creds, nil)

      assert data.user.email == attrs["email"]
      assert data.user.uid == attrs["id"]
      assert data.user.provider == "twitch"
      assert data.user.access_token == "12345"

      assert StreamClosedCaptionerPhoenix.Settings.get_stream_settings_by_user_id!(data.user.id)
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
        "access_token" => "12345",
        "refresh_token" => "12345"
      }

      insert(:user, uid: attrs["id"], provider: "twitch")

      {:ok, data} = AccountsOauth.find_or_register_user_with_oauth(attrs, creds, nil)

      assert data.user.uid == attrs["id"]
      refute data.user.email == attrs["email"]
      assert data.user.username == attrs["display_name"]
      assert data.user.description == attrs["description"]
      assert data.user.provider == "twitch"
      assert data.user.access_token == "12345"
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
        "access_token" => "12345",
        "refresh_token" => "12345"
      }

      user = insert(:user, uid: nil, provider: nil)

      {:ok, data} = AccountsOauth.find_or_register_user_with_oauth(attrs, creds, user)

      assert data.user.uid == attrs["id"]
      refute data.user.email == attrs["email"]
      assert data.user.username == attrs["display_name"]
      assert data.user.description == attrs["description"]
      assert data.user.provider == "twitch"
      assert data.user.access_token == "12345"
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
        "access_token" => "12345",
        "refresh_token" => "12345"
      }

      insert(:user, uid: attrs["id"], provider: "twitch")
      current_user = insert(:user, uid: nil, provider: nil)

      assert {:error, _message} =
               AccountsOauth.find_or_register_user_with_oauth(attrs, creds, current_user)
    end
  end
end
