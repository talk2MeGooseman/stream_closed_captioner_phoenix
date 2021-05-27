defmodule StreamClosedCaptionerPhoenixWeb.CaptionsChannel do
  use StreamClosedCaptionerPhoenixWeb, :channel
  alias StreamClosedCaptionerPhoenixWeb.ActivePresence

  @impl true
  def join("captions:" <> user_id, _payload, socket) do
    if authorized?(socket, user_id) do
      send(self(), :after_join)
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
    NewRelic.start_transaction("Captions", "zoom")
    user = socket.assigns.current_user

    case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:zoom, user, payload) do
      {:ok, sent_payload} ->
        NewRelic.stop_transaction()
        {:reply, {:ok, sent_payload}, socket}

      {:error, _} ->
        NewRelic.stop_transaction()
        {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  def handle_in("publishInterim", %{"twitch" => %{"enabled" => true}} = payload, socket) do
    ref = socket_ref(socket)

    Task.start_link(fn ->
      NewRelic.start_transaction("Captions", "twitch")
      sent_on_time = Map.get(payload, "sentOn")
      user = socket.assigns.current_user

      case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:twitch, user, payload) do
        {:ok, sent_payload} ->
          send(self(), :after_publish)
          NewRelic.add_attributes(total_time_to_send: time_to_complete(sent_on_time))
          NewRelic.stop_transaction()
          Phoenix.Channel.reply(ref, {:ok, sent_payload})

        {:error, _} ->
          NewRelic.add_attributes(total_time_to_send: time_to_complete(sent_on_time))
          NewRelic.add_attributes(errored: true)
          NewRelic.stop_transaction()
          Phoenix.Channel.reply(ref, {:error, "Issue sending captions."})
      end
    end)

    {:noreply, socket}
  end

  def handle_in("publishInterim", payload, socket) do
    user = socket.assigns.current_user

    case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:default, user, payload) do
      {:ok, sent_payload} -> {:reply, {:ok, sent_payload}, socket}
      {:error, _} -> {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      ActivePresence.track(self(), "active_channels", socket.assigns.current_user.id, %{})

    {:noreply, socket}
  end

  def handle_info(:after_publish, socket) do
    {:ok, _} =
      ActivePresence.update(self(), "active_channels", socket.assigns.current_user.id, %{
        last_publish: System.system_time(:second)
      })

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(socket, user_id) do
    user_id == to_string(socket.assigns.current_user.id)
  end

  defp time_to_complete(nil), do: 0

  defp time_to_complete(sent_on) do
    parsed_sent_on = Timex.parse!(sent_on, "{ISO:Extended}")
    current_time = Timex.now()

    DateTime.diff(current_time, parsed_sent_on)
  end
end
