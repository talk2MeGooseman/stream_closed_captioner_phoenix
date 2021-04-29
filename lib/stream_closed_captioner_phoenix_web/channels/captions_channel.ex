defmodule StreamClosedCaptionerPhoenixWeb.CaptionsChannel do
  use StreamClosedCaptionerPhoenixWeb, :channel
  alias StreamClosedCaptionerPhoenixWeb.ActivePresence

  @impl true
  def join("captions:" <> user_id, _payload, socket) do
    if authorized?(socket, user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("publishFinal", %{"zoom" => %{"enabled" => false}} = payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("publishFinal", %{"zoom" => %{"enabled" => true}} = payload, socket) do
    user = socket.assigns.current_user

    case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:zoom, user, payload) do
      {:ok, sent_payload} -> {:reply, {:ok, sent_payload}, socket}
      {:error, _} -> {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  def handle_in("publishInterim", %{"twitch" => %{"enabled" => true}} = payload, socket) do
    user = socket.assigns.current_user

    case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:twitch, user, payload) do
      {:ok, sent_payload} ->
        send(self(), :after_send)
        {:reply, {:ok, sent_payload}, socket}

      {:error, _} ->
        {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  def handle_in("publishInterim", payload, socket) do
    user = socket.assigns.current_user

    case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:default, user, payload) do
      {:ok, sent_payload} -> {:reply, {:ok, sent_payload}, socket}
      {:error, _} -> {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  def handle_info(:after_send, socket) do
    {:ok, _} =
      ActivePresence.track(socket, socket.assigns.current_user.id, %{
        last_active: inspect(System.system_time(:second))
      })

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(socket, user_id) do
    user_id == to_string(socket.assigns.current_user.id)
  end
end
