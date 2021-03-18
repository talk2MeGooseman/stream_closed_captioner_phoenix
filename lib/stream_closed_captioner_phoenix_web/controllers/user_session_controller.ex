defmodule StreamClosedCaptionerPhoenixWeb.UserSessionController do
  use StreamClosedCaptionerPhoenixWeb, :controller
  plug Ueberauth

  alias Ueberauth.Strategy.Helpers

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.AccountsOauth
  alias StreamClosedCaptionerPhoenixWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    current_user = conn.assigns.current_user
    %{extra: %{ raw_info: %{ user: user }}} = auth
    [user_info] = user["data"]

    case AccountsOauth.find_or_register_user_with_oauth(user_info, current_user) do
      {:ok, %{user: user}} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> UserAuth.log_in_user(user, %{"remember_me" => "true"})
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end
end
