defmodule StreamClosedCaptionerPhoenixWeb.CaptionSettingLive.Show do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  alias StreamClosedCaptionerPhoenix.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:caption_setting, Accounts.get_caption_setting!(id))}
  end

  defp page_title(:show), do: "Show Caption setting"
  defp page_title(:edit), do: "Edit Caption setting"
end
