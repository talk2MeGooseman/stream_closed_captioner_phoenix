defmodule StreamClosedCaptionerPhoenixWeb.Maintenance do
  @behaviour Plug

  alias StreamClosedCaptionerPhoenix.Accounts

  #  MyAppWeb.Maintenance.begin() and end it via MyAppWeb.Maintenance.finish().

  def begin, do: :persistent_term.put(__MODULE__, true)
  def finish, do: :persistent_term.erase(__MODULE__)

  @impl true
  def init(_), do: []

  @impl true
  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    if Accounts.is_admin?(user) do
      conn
    else
      case :persistent_term.get(__MODULE__, false) do
        false ->
          conn

        true ->
          conn
          |> Plug.Conn.send_resp(
            503,
            "Sorry! The site is currently under maintenance, please come back in a little bit."
          )
          |> Plug.Conn.halt()
      end
    end
  end
end
