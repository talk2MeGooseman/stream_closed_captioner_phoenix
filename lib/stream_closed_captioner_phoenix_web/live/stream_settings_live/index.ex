defmodule StreamClosedCaptionerPhoenixWeb.StreamSettingsLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  import StreamClosedCaptionerPhoenixWeb.LiveHelpers

  alias StreamClosedCaptionerPhoenix.{Repo, Settings}

  @impl true
  def mount(_params, session, socket) do
    current_user =
      session_current_user(session)
      |> Repo.preload(:stream_settings)

    changeset = Settings.change_stream_settings(current_user.stream_settings)

    socket = assign(socket, :current_user, current_user)
    socket = assign(socket, :changeset, changeset)
    socket = assign(socket, :live_socket_id, Map.get(session, "live_socket_id"))
    {:ok, assign(socket, :stream_settings, current_user.stream_settings)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, _, _params) do
    socket
    |> assign(:page_title, "Captions settings")
  end

  @impl true
  def handle_event(
        "remove_blocklist_word",
        %{"word" => word} = _params,
        socket
      ) do
    current_user =
      socket.assigns.current_user
      |> Repo.preload(:stream_settings, force: true)

    new_blocklist = List.delete(current_user.stream_settings.blocklist, word)

    params = %{"blocklist" => new_blocklist}

    case Settings.update_stream_settings(current_user.stream_settings, params) do
      {:ok, stream_settings} ->
        {:noreply,
         socket
         |> assign(:stream_settings, stream_settings)
         |> put_flash(:info, "Blocklist word removed successfully.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event(
        "add",
        %{"stream_settings" => %{"blocklist_word" => blocklist_word}},
        socket
      )
      when byte_size(blocklist_word) == 0 do
    {:noreply, assign(socket, :changeset, socket.changeset)}
  end

  def handle_event(
        "add",
        %{"stream_settings" => %{"blocklist_word" => blocklist_word}},
        socket
      ) do
    blocklist = socket.assigns.stream_settings.blocklist
    params = %{"blocklist" => [blocklist_word | blocklist]}

    case Settings.update_stream_settings(socket.assigns.stream_settings, params) do
      {:ok, stream_settings} ->
        {:noreply,
         socket
         |> assign(:stream_settings, stream_settings)
         |> put_flash(:info, "Blocklist word added successfully.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
