defmodule StreamClosedCaptionerPhoenixWeb.CaptionsChannel do
  use StreamClosedCaptionerPhoenixWeb, :channel

  @impl true
  def join("captions:" <> user_id, _payload, socket) do
    if authorized?(socket, user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("publish", payload, socket) do
    user = socket.assigns.current_user
    StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:twitch, user, payload)
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (captions:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(socket, user_id) do
    user_id == to_string(socket.assigns.current_user.id)
  end
end
