defmodule StreamClosedCaptionerPhoenixWeb.CaptionsChannel do
  use StreamClosedCaptionerPhoenixWeb, :channel
  use NewRelic.Tracer
  require Logger
  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  @impl true
  def join("captions:" <> user_id, _payload, socket) do
    user = socket.assigns.current_user

    if authorized?(socket, user_id) do
      :telemetry.execute(
        [:scc, :captions, :channel, :join],
        %{count: 1},
        %{user_id: user.id, result: :ok}
      )

      send(self(), :after_join)
      {:ok, socket}
    else
      :telemetry.execute(
        [:scc, :captions, :channel, :join],
        %{count: 1},
        %{user_id: user.id, result: :unauthorized}
      )

      {:error, %{reason: "unauthorized"}}
    end
  end

  @trace :handle_in
  def handle_in("publishFinal", %{"zoom" => %{"enabled" => true}} = payload, socket) do
    emit_publish("publishFinal", payload, socket, :zoom)
    NewRelic.start_transaction("Captions", "zoom")
    user = socket.assigns.current_user

    case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:zoom, user, payload) do
      {:ok, sent_payload} ->
        NewRelic.stop_transaction()

        {:reply, {:ok, sent_payload}, socket}

      {:error, reason} ->
        Logger.error("Zoom pipeline failed for user #{user.id}: #{inspect(reason)}")
        NewRelic.stop_transaction()
        {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  @trace :handle_in
  def handle_in(publish_state, %{"twitch" => %{"enabled" => true}} = payload, socket) do
    emit_publish(publish_state, payload, socket, :twitch)
    NewRelic.start_transaction("Captions", "twitch")
    sent_on_time = Map.get(payload, "sentOn")
    user = socket.assigns.current_user

    UserTracker.update(self(), "active_channels", user.uid, %{
      last_publish: System.system_time(:second)
    })

    case safe_pipeline_to(:twitch, user, payload) do
      {:ok, sent_payload} ->
        Absinthe.Subscription.publish(StreamClosedCaptionerPhoenixWeb.Endpoint, sent_payload,
          new_twitch_caption: user.uid
        )

        new_relic_track(:ok, user, sent_on_time)
        {:reply, {:ok, sent_payload}, socket}

      {:error, reason} ->
        Logger.error("Twitch pipeline failed for user #{user.id}: #{inspect(reason)}")
        new_relic_track(:error, user, sent_on_time)
        {:reply, {:error, "Issue sending captions."}, socket}
    end
  end

  def handle_in("active", payload, socket) do
    emit_publish("active", payload, socket, :none)
    user = socket.assigns.current_user

    UserTracker.update(self(), "active_channels", user.uid, %{
      last_publish: System.system_time(:second)
    })

    {:reply, :ok, socket}
  end

  def handle_in(publish_state, payload, socket) when publish_state != "active" do
    emit_publish(publish_state, payload, socket, :default)
    user = socket.assigns.current_user

    case safe_pipeline_to(:default, user, payload) do
      {:ok, sent_payload} ->
        {:reply, {:ok, sent_payload}, socket}

      {:error, reason} ->
        Logger.error("Default pipeline failed for user #{user.id}: #{inspect(reason)}")
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
    case Timex.parse(sent_on, "{ISO:Extended}") do
      {:ok, parsed} -> DateTime.diff(Timex.now(), parsed, :millisecond)
      {:error, _} -> 0
    end
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

  defp safe_pipeline_to(destination, user, payload) do
    StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(destination, user, payload)
  rescue
    e ->
      Logger.error(
        "Pipeline raised exception for user #{user.id}: #{Exception.format(:error, e, __STACKTRACE__)}"
      )

      {:error, :exception}
  end

  defp emit_publish(event, payload, socket, destination) do
    user = socket.assigns.current_user
    sent_on = Map.get(payload, "sentOn")
    age = time_to_complete(sent_on)

    measurements =
      case sent_on do
        nil -> %{count: 1}
        _ -> %{count: 1, client_send_age_ms: age}
      end

    metadata = %{
      user_id: user.id,
      destination: destination,
      event: event,
      zoom_enabled: get_in(payload, ["zoom", "enabled"]) == true,
      twitch_enabled: get_in(payload, ["twitch", "enabled"]) == true
    }

    :telemetry.execute([:scc, :captions, :channel, :publish], measurements, metadata)
  end

  @impl true
  def terminate(reason, socket) do
    user_id = get_in(socket.assigns, [:current_user, Access.key(:id)])

    :telemetry.execute(
      [:scc, :captions, :channel, :leave],
      %{count: 1},
      %{user_id: user_id, reason: inspect(reason)}
    )

    :ok
  end
end
