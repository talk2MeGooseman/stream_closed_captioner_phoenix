defmodule StreamClosedCaptionerPhoenixWeb.DashboardLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  import StreamClosedCaptionerPhoenixWeb.LiveHelpers

  alias StreamClosedCaptionerPhoenix.{Accounts, Repo, Settings}

  @impl true
  def mount(_params, session, socket) do
    current_user =
      session_current_user(session)
      |> Repo.preload(:stream_settings)

    twitch_enabled = current_user.provider === "twitch" && is_binary(current_user.uid)

    socket = assign(socket, :twitch_enabled, twitch_enabled)
    socket = assign(socket, :zoom_enabled, false)
    socket = assign(socket, :current_user, current_user)
    socket = assign(socket, :live_socket_id, Map.get(session, "live_socket_id"))
    {:ok, assign(socket, :stream_settings, current_user.stream_settings)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :settings, _params) do
    socket
    |> assign(:page_title, "Caption Settings")
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Dashboard")
  end
end
