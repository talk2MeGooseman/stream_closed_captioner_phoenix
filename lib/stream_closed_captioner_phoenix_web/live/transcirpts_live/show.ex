defmodule StreamClosedCaptionerPhoenixWeb.TranscirptsLive.Show do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket),
      do: StreamClosedCaptionerPhoenixWeb.Endpoint.subscribe("transcript:1")

    {:ok,
     socket
     |> assign(:interim, "")
     |> assign(:final_list, [])}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :page_title, page_title(socket.assigns.live_action))}
  end

  def handle_info(%{payload: %{"interim" => interim_text, "final" => ""}}, socket) do
    {:noreply, assign(socket, :interim, interim_text)}
  end

  def handle_info(%{payload: %{"interim" => _, "final" => final_text}}, socket) do
    new_final_list = socket.assigns.final_list ++ [final_text]

    {:noreply,
     socket
     |> assign(:interim, "")
     |> assign(:final_list, new_final_list)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Live Transcription"
end
