defmodule StreamClosedCaptionerPhoenixWeb.AdminHooks do
  import Phoenix.LiveView
  alias StreamClosedCaptionerPhoenix.Accounts

  def on_mount(:assign_current_user, _params, %{"user_token" => token}, socket) do
    {:cont, assign(socket, :current_user, Accounts.get_user_by_session_token(token))}
  end

  def on_mount(:assign_current_user, _params, _session, socket) do
    {:cont, assign(socket, :current_user, nil)}
  end
end
