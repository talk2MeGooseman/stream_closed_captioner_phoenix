defmodule StreamClosedCaptionerPhoenixWeb.TranscirptsLive.Show do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket),
      do: StreamClosedCaptionerPhoenixWeb.Endpoint.subscribe("transcript:1")

    {:ok,
     socket
     |> assign(:interim, "")
     |> assign(:final, "")}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  def handle_info(%{payload: %{"interim" => interim, "final" => final}}, socket) do
    {:noreply,
     socket |> assign(:interim, interim) |> assign(:final, socket.assigns.final <> final)}
  end

  def handle_info(msg, socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Live Transcirpts"
end
