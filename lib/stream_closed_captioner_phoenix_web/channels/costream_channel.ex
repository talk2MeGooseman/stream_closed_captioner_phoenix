defmodule StreamClosedCaptionerPhoenixWeb.CostreamChannel do
  @moduledoc """
  Channel for co-streamer guest captions. Topic: `costream:HOST_USER_ID`.

  Two roles may join:

    * **guest** — a socket authenticated by a costream link token whose guest
      record belongs to the host. May publish captions.
    * **host** — the host's own user socket, read-only. Mute/kick originate
      from the host UI as `Endpoint.broadcast/3` control events
      (`guest_muted` / `guest_kicked`), intercepted below so they reach the
      matching guest's channel process on any node.

  Guest publishes are rate limited per guest, censored with the host's
  settings (`CaptionsPipeline` `:costream` path — no translations, no pirate
  mode), and gated on the host actively captioning plus the costream kill
  switch. Successful publishes fan out to the Twitch extension
  (`new_costream_caption`), the OBS overlay PubSub topic, and the host's
  monitor topic.
  """
  use StreamClosedCaptionerPhoenixWeb, :channel
  require Logger

  alias StreamClosedCaptionerPhoenix.Costream
  alias StreamClosedCaptionerPhoenix.RateLimit
  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  # Generous enough for a speech recognizer emitting interim results several
  # times a second, tight enough that a scripted link-holder can't flood
  # every viewer's extension.
  @rate_limit_scale_ms 1_000
  @rate_limit_max_hits 15

  # How often guests are told whether the host is actively captioning.
  @host_status_interval_ms 30_000

  intercept(["guest_muted", "guest_kicked"])

  @impl true
  def join("costream:" <> host_id, _payload, socket) do
    case role(socket, host_id) do
      {:guest, guest} ->
        send(self(), :after_join)

        socket =
          socket
          |> assign(:costream_guest, guest)
          |> assign(:host, guest.user)
          |> assign(:muted, guest.muted)

        {:ok, %{name: guest.name, muted: guest.muted}, socket}

      :host ->
        {:ok, socket}

      :unauthorized ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("publish", payload, %{assigns: %{costream_guest: guest, host: host}} = socket) do
    cond do
      socket.assigns.muted ->
        {:reply, {:error, %{reason: "muted"}}, socket}

      rate_limited?(guest) ->
        {:reply, {:error, %{reason: "rate_limited"}}, socket}

      not UserTracker.channel_active?(host.uid) ->
        {:reply, {:error, %{reason: "host_offline"}}, socket}

      not Costream.feature_enabled?(host) ->
        {:reply, {:error, %{reason: "disabled"}}, socket}

      true ->
        publish_captions(guest, host, payload, socket)
    end
  end

  def handle_in("publish", _payload, socket) do
    {:reply, {:error, %{reason: "unauthorized"}}, socket}
  end

  @impl true
  def handle_out("guest_muted", %{guest_id: guest_id, muted: muted}, socket) do
    case socket.assigns[:costream_guest] do
      %{id: ^guest_id} ->
        push(socket, "muted", %{muted: muted})
        {:noreply, assign(socket, :muted, muted)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_out("guest_kicked", %{guest_id: guest_id}, socket) do
    case socket.assigns[:costream_guest] do
      %{id: ^guest_id} ->
        push(socket, "kicked", %{})
        {:stop, :normal, socket}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    guest = socket.assigns.costream_guest
    host = socket.assigns.host

    UserTracker.track(self(), Costream.presence_topic(host.id), to_string(guest.id), %{
      name: guest.name
    })

    broadcast_monitor(host.id, {:costream_guest_joined, %{guest_id: guest.id, name: guest.name}})
    push_host_status(socket)

    {:noreply, socket}
  end

  def handle_info(:host_status, socket) do
    push_host_status(socket)
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    with %{costream_guest: guest, host: host} <- socket.assigns do
      broadcast_monitor(host.id, {:costream_guest_left, %{guest_id: guest.id}})
    end

    :ok
  end

  # Guest authorization re-reads the DB record on join so a revoked guest
  # can't rejoin on a socket that authenticated before the revocation.
  defp role(socket, host_id) do
    cond do
      guest = socket.assigns[:costream_guest] ->
        case Costream.get_active_guest(guest.id) do
          {:ok, %{user_id: user_id} = fresh} ->
            if to_string(user_id) == host_id, do: {:guest, fresh}, else: :unauthorized

          {:error, _} ->
            :unauthorized
        end

      user = socket.assigns[:current_user] ->
        if to_string(user.id) == host_id, do: :host, else: :unauthorized

      true ->
        :unauthorized
    end
  end

  # One settings fetch per publish serves both the kill-switch check and the
  # censoring pass — this is the hot path (up to 15/sec × 4 guests).
  defp publish_captions(guest, host, payload, socket) do
    case StreamClosedCaptionerPhoenix.Settings.get_stream_settings_by_user_id(host.id) do
      {:ok, %{costream_enabled: false}} ->
        {:reply, {:error, %{reason: "disabled"}}, socket}

      {:ok, stream_settings} ->
        censor_and_fan_out(guest, host, stream_settings, payload, socket)

      {:error, _} ->
        {:reply, {:error, %{reason: "pipeline_failed"}}, socket}
    end
  end

  defp censor_and_fan_out(guest, host, stream_settings, payload, socket) do
    case safe_censor(host, stream_settings, payload) do
      {:ok, censored} ->
        caption = %{
          guest_id: guest.id,
          name: guest.name,
          interim: censored.interim,
          final: censored.final
        }

        Absinthe.Subscription.publish(StreamClosedCaptionerPhoenixWeb.Endpoint, caption,
          new_costream_caption: host.uid
        )

        Phoenix.PubSub.broadcast(
          StreamClosedCaptionerPhoenix.PubSub,
          "caption_source:#{host.id}",
          {:costream_caption_payload, caption}
        )

        broadcast_monitor(host.id, {:costream_caption, caption})

        {:reply, {:ok, caption}, socket}

      {:error, reason} ->
        Logger.error(
          "Costream pipeline failed for guest #{guest.id} (host #{host.id}): #{inspect(reason)}"
        )

        {:reply, {:error, %{reason: "pipeline_failed"}}, socket}
    end
  end

  defp safe_censor(host, stream_settings, payload) do
    {:ok, StreamClosedCaptionerPhoenix.CaptionsPipeline.censor_only(payload, stream_settings)}
  rescue
    e ->
      Logger.error(
        "Costream pipeline raised for host #{host.id}: #{Exception.format(:error, e, __STACKTRACE__)}"
      )

      {:error, :exception}
  end

  defp rate_limited?(guest) do
    case RateLimit.hit(
           "costream_publish:#{guest.id}",
           @rate_limit_scale_ms,
           @rate_limit_max_hits
         ) do
      {:allow, _count} -> false
      {:deny, _timeout} -> true
    end
  end

  defp push_host_status(socket) do
    push(socket, "host_status", %{
      active: UserTracker.channel_active?(socket.assigns.host.uid)
    })

    Process.send_after(self(), :host_status, @host_status_interval_ms)
  end

  defp broadcast_monitor(host_user_id, message) do
    Phoenix.PubSub.broadcast(
      StreamClosedCaptionerPhoenix.PubSub,
      Costream.monitor_topic(host_user_id),
      message
    )
  end
end
