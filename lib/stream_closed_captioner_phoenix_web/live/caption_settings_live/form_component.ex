defmodule StreamClosedCaptionerPhoenixWeb.CaptionSettingsLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  alias StreamClosedCaptionerPhoenix.Settings

  @impl true
  def update(%{stream_settings: stream_settings} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, Settings.change_stream_settings(stream_settings))
     |> assign(:language_selection, Settings.spoken_languages())
     |> assign(:saved, true)}
  end

  @impl true
  def handle_event("validate", %{"stream_settings" => stream_settings_params}, socket) do
    changeset =
      socket.assigns.stream_settings
      |> Settings.change_stream_settings(stream_settings_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:saved, changeset.changes == %{})}
  end

  def handle_event("save", %{"stream_settings" => stream_settings_params}, socket) do
    case Settings.update_stream_settings(socket.assigns.stream_settings, stream_settings_params) do
      {:ok, stream_settings} ->
        # Let the parent LiveView own the refreshed settings + flash so the
        # whole page (blocklist, translation) stays in sync after a save.
        send(self(), {:caption_settings_saved, stream_settings})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(:changeset, changeset) |> assign(:saved, false)}
    end
  end

  @doc "A label + description row with a toggle switch bound to a boolean field."
  attr :f, :any, required: true
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :desc, :string, default: nil

  def toggle_row(assigns) do
    ~H"""
    <div class="row">
      <div class="row__txt">
        <label for={input_id(@f, @field)}>{@label}</label>
        <div :if={@desc} class="desc">{@desc}</div>
      </div>
      <div class="row__ctl">
        <label class="switch">
          {checkbox(@f, @field, class: "switch__input")}
          <span class="switch__track" aria-hidden="true"></span>
        </label>
      </div>
    </div>
    """
  end
end
