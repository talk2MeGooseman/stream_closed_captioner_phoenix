defmodule StreamClosedCaptionerPhoenixWeb.CaptionsChannel do
  use StreamClosedCaptionerPhoenixWeb, :channel
  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  @impl true
  def join("captions:" <> user_id, _payload, socket) do
    if authorized?(socket, user_id) do
      send(self(), :after_join)

      if FunWithFlags.enabled?(:deepgram, for: socket.assigns.current_user) do
        {:ok, pid} = DeepgramWebsocket.start_link(%{user: socket.assigns.current_user})

        {:ok, assign(socket, :wss_pid, pid)}
      else
        {:ok, socket}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("publishFinal", %{"zoom" => %{"enabled" => true}} = payload, socket) do
    NewRelic.start_transaction("Captions", "zoom")
    user = socket.assigns.current_user

    case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:zoom, user, payload) do
      {:ok, sent_payload} ->
        NewRelic.stop_transaction()

        StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast_from!(
          self(),
          "transcript:1",
          "new_msg",
          payload
        )

        {:reply, {:ok, sent_payload}, socket}

      {:error, _} ->
        NewRelic.stop_transaction()
        {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  def handle_in(_publish_state, %{"twitch" => %{"enabled" => true}} = payload, socket) do
    NewRelic.start_transaction("Captions", "twitch")
    sent_on_time = Map.get(payload, "sentOn")
    user = socket.assigns.current_user

    case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:twitch, user, payload) do
      {:ok, sent_payload} ->
        Absinthe.Subscription.publish(StreamClosedCaptionerPhoenixWeb.Endpoint, sent_payload,
          new_twitch_caption: user.uid
        )

        StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast_from!(
          self(),
          "transcript:1",
          "new_msg",
          sent_payload
        )

        new_relic_track(:ok, user, sent_on_time)
        {:reply, {:ok, sent_payload}, socket}

      {:error, _} ->
        new_relic_track(:error, user, sent_on_time)
        {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  def handle_in("publishBlob", {:binary, chunk}, socket) do
    if socket.assigns.wss_pid do
      case WebSockex.send_frame(socket.assigns.wss_pid, {:binary, chunk}) do
        :ok ->
          dbg("Sent chunk to deepgram")
          {:noreply, socket}

        {:error, _} ->
          dbg("Error sending chunk to deepgram")
          {:noreply, socket}
      end
    end

    {:noreply, socket}
  end

  def handle_in("active", _payload, socket) do
    user = socket.assigns.current_user

    UserTracker.update(self(), "active_channels", user.uid, %{
      last_publish: System.system_time(:second)
    })

    {:reply, :ok, socket}
  end

  def handle_in(publish_state, payload, socket) when publish_state != "active" do
    user = socket.assigns.current_user

    case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:default, user, payload) do
      {:ok, sent_payload} ->
        StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast_from!(
          self(),
          "transcript:1",
          "new_msg",
          payload
        )

        {:reply, {:ok, sent_payload}, socket}

      {:error, _} ->
        {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    track_user(socket.assigns.current_user.uid)
    {:noreply, socket}
  end

  defp track_user(uid) when is_binary(uid) do
    if String.length(uid) > 0 do
      UserTracker.track(self(), "active_channels", uid, %{})
    end
  end

  defp track_user(nil), do: nil

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
