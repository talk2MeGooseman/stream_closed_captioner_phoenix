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

          Absinthe.Subscription.publish(StreamClosedCaptionerPhoenixWeb.Endpoint, sent_payload,
            new_twitch_caption: user.uid
          )

          new_relic_track(:ok, user, sent_on_time)
          Phoenix.Channel.reply(ref, {:ok, sent_payload})

        {:error, _} ->
          new_relic_track(:error, user, sent_on_time)
          Phoenix.Channel.reply(ref, {:error, %{message: "Issue sending captions."}})
      end
    end)

    ActivePresence.update(self(), "active_channels", socket.assigns.current_user.uid, %{
      last_publish: System.system_time(:second)
    })

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
      ActivePresence.track(self(), "active_channels", socket.assigns.current_user.uid, %{})

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

    DateTime.diff(current_time, parsed_sent_on, :millisecond)
  end

  defp new_relic_track(:ok, user, sent_on) do
    NewRelic.add_attributes(twitch_uid: user.uid)
    NewRelic.add_attributes(total_time_to_send_ms: time_to_complete(sent_on))
    NewRelic.stop_transaction()
  end

  defp new_relic_track(:error, user, sent_on) do
    NewRelic.add_attributes(errored: true)
    new_relic_track(:ok, user, sent_on)
  end
end
