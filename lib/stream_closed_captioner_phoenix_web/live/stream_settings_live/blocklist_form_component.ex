defmodule StreamClosedCaptionerPhoenixWeb.StreamSettingsLive.BlocklistFormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  alias StreamClosedCaptionerPhoenix.Settings

  @impl true
  def update(%{stream_settings: stream_settings} = assigns, socket) do
    changeset = Settings.change_stream_settings(stream_settings)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "add",
        %{"stream_settings" => %{"blocklist_word" => blocklist_word}},
        socket
      )
      when byte_size(blocklist_word) == 0 do
    {:noreply, assign(socket, :changeset, socket.assigns.changeset)}
  end

  def handle_event(
        "add",
        %{"stream_settings" => %{"blocklist_word" => blocklist_word}},
        socket
      ) do
    blocklist = socket.assigns.stream_settings.blocklist || []
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
