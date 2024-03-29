defmodule StreamClosedCaptionerPhoenixWeb.CaptionSettingsLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  alias StreamClosedCaptionerPhoenix.Settings

  @impl true
  def update(%{stream_settings: stream_settings} = assigns, socket) do
    changeset = Settings.change_stream_settings(stream_settings)
    language_selection = Settings.spoken_languages()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:language_selection, language_selection)}
  end

  @impl true
  def handle_event("validate", %{"stream_settings" => stream_settings_params}, socket) do
    changeset =
      socket.assigns.stream_settings
      |> Settings.change_stream_settings(stream_settings_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"stream_settings" => stream_settings_params}, socket) do
    case Settings.update_stream_settings(socket.assigns.stream_settings, stream_settings_params) do
      {:ok, _stream_settings} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stream settings updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
