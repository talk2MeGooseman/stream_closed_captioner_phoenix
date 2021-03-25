defmodule StreamClosedCaptionerPhoenixWeb.DashboardLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  import StreamClosedCaptionerPhoenixWeb.LiveHelpers

  alias StreamClosedCaptionerPhoenix.{Accounts, Repo, Settings}
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

  @impl true
  def mount(_params, session, socket) do
    current_user =
      session_current_user(session)
      |> Repo.preload(:stream_settings)

    {:ok, assign(socket, :stream_settings, current_user.stream_settings)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :settings, _params) do
    socket
    |> assign(:page_title, "Edit Stream settings")
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Stream settings")
  end
end
