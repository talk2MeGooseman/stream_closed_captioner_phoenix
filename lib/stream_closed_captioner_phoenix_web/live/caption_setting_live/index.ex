defmodule StreamClosedCaptionerPhoenixWeb.CaptionSettingLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Accounts.CaptionSetting

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :captions_setings, list_captions_setings())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Caption setting")
    |> assign(:caption_setting, Accounts.get_caption_setting!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Caption setting")

    # |> assign(:caption_setting, %CaptionSetting{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Captions setings")
    |> assign(:caption_setting, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    caption_setting = Accounts.get_caption_setting!(id)
    {:ok, _} = Accounts.delete_caption_setting(caption_setting)

    {:noreply, assign(socket, :captions_setings, list_captions_setings())}
  end

  defp list_captions_setings do
    Accounts.list_captions_setings()
  end
end
