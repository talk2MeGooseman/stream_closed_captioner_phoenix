defmodule StreamClosedCaptionerPhoenixWeb.UserSessionControllerTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase
  use Plug.Test

  import StreamClosedCaptionerPhoenix.AccountsFixtures
  import Ueberauth.Strategy.Helpers

  defmodule Creds do
    defstruct access_token: "success_token", refresh_token: "success"
  end

  setup do
    {:ok, user: user_fixture()}
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Login</h1>"
      assert response =~ "Forgot your password?</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(Routes.user_session_path(conn, :new))
      assert redirected_to(conn) == "/dashboard"
    end
  end

  describe "GET /auth/twitch/callback" do
    test "redirect users when Twitch user doesnt have an email", %{
      conn: conn
    } do
      conn =
        conn
        |> assign(:flash, %{})
        |> assign(:current_user, nil)
        |> assign(:ueberauth_auth, %{
          extra: %{
            raw_info: %{
              user: %{
                "data" => [
                  %{
                    "id" => "1047413243",
                    "login" => "bobypla",
                    "profile_image_url" =>
                      "https://static-cdn.jtvnw.net/jtv_user_pictures/ae6bd976-5906-4410-a4d9-784132e1b25c-profile_image-300x300.jpeg",
                    "description" => "Gosto de jogar jogos para passar o tempo."
                  }
                ]
              }
            }
          },
          credentials: %Creds{}
        })

      StreamClosedCaptionerPhoenixWeb.UserSessionController.callback(
        conn,
        %{}
      )
    end
  end

  describe "POST /users/log_in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_reference_live_app_web_user_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(user_return_to: "/foo/bar")
        |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Login</h1>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
