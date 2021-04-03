defmodule StreamClosedCaptionerPhoenixWeb.UserRegistrationControllerTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  import StreamClosedCaptionerPhoenix.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Sign Up"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/dashboard"
    end
  end

  describe "POST /users/register" do
    # @tag :capture_log

    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      html_response(conn, 200)
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "6 plz"}
        })

      response = html_response(conn, 200)
      assert response =~ "Sign Up"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 6 character"
    end
  end

  describe "DELETE /users/register" do
    setup :register_and_log_in_user

    test "renders registration page", %{conn: conn} do
      new_conn = delete(conn, Routes.user_registration_path(conn, :delete))

      assert redirected_to(new_conn) =~ "/"
      assert get_flash(new_conn, :info) =~ "Account successfully deleted."
    end
  end
end
