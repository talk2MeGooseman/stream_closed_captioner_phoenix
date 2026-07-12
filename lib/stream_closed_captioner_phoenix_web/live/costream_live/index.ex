defmodule StreamClosedCaptionerPhoenixWeb.CostreamLive.Index do
  @moduledoc """
  Host dashboard for co-streamer captions: create/revoke per-guest links,
  watch each connected guest's live caption text, mute/kick guests, and flip
  the kill switch that silences all guest captions at once.

  Live activity arrives over the costream monitor PubSub topic (published by
  `CostreamChannel`); mute/kick are pushed back to guest channel processes
  via `Endpoint.broadcast/3` control events.
  """
  use StreamClosedCaptionerPhoenixWeb, :live_view

  import StreamClosedCaptionerPhoenixWeb.LiveHelpers

  alias StreamClosedCaptionerPhoenix.{Costream, Repo, Settings}
  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  @impl true
  def mount(_params, session, socket) do
    current_user =
      session_current_user(session)
      |> Repo.preload(:stream_settings)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        StreamClosedCaptionerPhoenix.PubSub,
        Costream.monitor_topic(current_user.id)
      )
    end

    connected_ids =
      Costream.presence_topic(current_user.id)
      |> UserTracker.list()
      |> MapSet.new(fn {guest_id, _meta} -> guest_id end)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Co-stream Captions")
     |> assign(:feature_enabled, Costream.feature_enabled?(current_user))
     |> assign(:costream_enabled, current_user.stream_settings.costream_enabled)
     |> assign(:guests, Costream.list_active_guests(current_user))
     |> assign(:connected_ids, connected_ids)
     |> assign(:live_text, %{})
     |> assign(:new_guest_name, "")}
  end

  @impl true
  def handle_event("create_guest", %{"name" => name}, socket) do
    case Costream.create_guest(socket.assigns.current_user, %{name: name}) do
      {:ok, _guest} ->
        {:noreply, refresh_guests(socket) |> assign(:new_guest_name, "")}

      {:error, :guest_limit_reached} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "You can have at most #{Costream.max_active_guests()} active guests. Revoke one first."
         )}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "Guest name can't be blank.")}
    end
  end

  def handle_event("toggle_mute", %{"id" => id}, socket) do
    with {:ok, guest} <- Costream.get_guest_for(socket.assigns.current_user, id),
         {:ok, updated} <- Costream.set_guest_muted(guest, !guest.muted) do
      broadcast_control(socket, "guest_muted", %{guest_id: updated.id, muted: updated.muted})
      {:noreply, refresh_guests(socket)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("revoke", %{"id" => id}, socket) do
    with {:ok, guest} <- Costream.get_guest_for(socket.assigns.current_user, id),
         {:ok, revoked} <- Costream.revoke_guest(guest) do
      broadcast_control(socket, "guest_kicked", %{guest_id: revoked.id})
      {:noreply, refresh_guests(socket)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("clear_flash", %{"key" => key}, socket) do
    {:noreply, clear_flash(socket, key)}
  end

  def handle_event("toggle_kill_switch", _params, socket) do
    stream_settings = socket.assigns.current_user.stream_settings
    enabled = !socket.assigns.costream_enabled

    case Settings.update_stream_settings(stream_settings, %{costream_enabled: enabled}) do
      {:ok, updated} ->
        current_user = %{socket.assigns.current_user | stream_settings: updated}

        {:noreply,
         socket
         |> assign(:current_user, current_user)
         |> assign(:costream_enabled, updated.costream_enabled)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update the setting.")}
    end
  end

  @impl true
  def handle_info({:costream_guest_joined, %{guest_id: guest_id}}, socket) do
    {:noreply, update(socket, :connected_ids, &MapSet.put(&1, to_string(guest_id)))}
  end

  def handle_info({:costream_guest_left, %{guest_id: guest_id}}, socket) do
    {:noreply, update(socket, :connected_ids, &MapSet.delete(&1, to_string(guest_id)))}
  end

  def handle_info({:costream_caption, caption}, socket) do
    live_text =
      Map.update(
        socket.assigns.live_text,
        caption.guest_id,
        %{interim: caption.interim, final: caption.final},
        fn current ->
          %{
            interim: caption.interim,
            final: if(caption.final == "", do: current.final, else: caption.final)
          }
        end
      )

    {:noreply, assign(socket, :live_text, live_text)}
  end

  defp refresh_guests(socket) do
    assign(socket, :guests, Costream.list_active_guests(socket.assigns.current_user))
  end

  defp broadcast_control(socket, event, payload) do
    StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
      Costream.channel_topic(socket.assigns.current_user.id),
      event,
      payload
    )
  end

  defp guest_url(guest) do
    url(~p"/costream/#{Costream.guest_token(guest)}")
  end

  defp guest_connected?(connected_ids, guest),
    do: MapSet.member?(connected_ids, to_string(guest.id))
end
