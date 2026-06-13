defmodule StreamClosedCaptionerPhoenixWeb.Admin.StreamSettingsLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component
  alias StreamClosedCaptionerPhoenix.Admin

  @impl true
  def update(%{record: record} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(changeset: Admin.change_stream_settings(record))}
  end

  @impl true
  def handle_event("validate", %{"stream_settings" => params}, socket) do
    cs =
      Admin.change_stream_settings(socket.assigns.record, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: cs)}
  end

  def handle_event("save", %{"stream_settings" => params}, socket) do
    result =
      if socket.assigns.action == :new do
        Admin.create_stream_settings(params)
      else
        Admin.update_stream_settings(socket.assigns.record, params)
      end

    case result do
      {:ok, record} ->
        send(self(), {:saved, record})
        {:noreply, socket |> put_flash(:info, "Saved.") |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, changeset: cs)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">
        {if @action == :new, do: "New Stream Settings", else: "Edit Stream Settings"}
      </h2>
      <.form
        :let={f}
        for={@changeset}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <%= if @action == :new do %>
            <.input field={f[:user_id]} type="number" label="User ID" />
          <% end %>
          <.input field={f[:language]} type="text" label="Language" />
          <.input field={f[:caption_delay]} type="number" label="Caption Delay" />
          <div class="grid grid-cols-2 gap-4">
            <.input field={f[:cc_box_size]} type="checkbox" label="CC Box Size" />
            <.input field={f[:filter_profanity]} type="checkbox" label="Filter Profanity" />
            <.input field={f[:hide_text_on_load]} type="checkbox" label="Hide Text on Load" />
            <.input field={f[:pirate_mode]} type="checkbox" label="Pirate Mode" />
            <.input field={f[:showcase]} type="checkbox" label="Showcase" />
            <.input
              field={f[:switch_settings_position]}
              type="checkbox"
              label="Switch Settings Position"
            />
            <.input field={f[:text_uppercase]} type="checkbox" label="Text Uppercase" />
            <.input field={f[:turn_on_reminder]} type="checkbox" label="Turn On Reminder" />
            <.input field={f[:auto_off_captions]} type="checkbox" label="Auto Off Captions" />
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-6">
          <button
            type="button"
            phx-click={JS.patch(@patch)}
            class="px-4 py-2 text-sm border rounded hover:bg-gray-50"
          >
            Cancel
          </button>
          <.button type="submit">Save</.button>
        </div>
      </.form>
    </div>
    """
  end
end
