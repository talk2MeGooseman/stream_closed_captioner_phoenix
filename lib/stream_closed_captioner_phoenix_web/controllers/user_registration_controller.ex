defmodule StreamClosedCaptionerPhoenixWeb.UserRegistrationController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenixWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, %{user: user}} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, _, %Ecto.Changeset{} = changeset, _} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    current_user = conn.assigns.current_user

    case Accounts.delete_user(current_user) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Account successfully deleted.")
        |> redirect(to: "/")

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end
end
