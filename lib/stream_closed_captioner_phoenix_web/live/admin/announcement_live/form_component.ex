defmodule StreamClosedCaptionerPhoenixWeb.Admin.AnnouncementLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  alias StreamClosedCaptionerPhoenix.Admin

  @impl true
  def update(%{record: record} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, Admin.change_announcement(record))}
  end

  @impl true
  def handle_event("validate", %{"announcement" => params}, socket) do
    cs =
      Admin.change_announcement(socket.assigns.record, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, cs)}
  end

  def handle_event("save", %{"announcement" => params}, socket) do
    result =
      if socket.assigns.action == :new do
        Admin.create_announcement(params)
      else
        Admin.update_announcement(socket.assigns.record, params)
      end

    case result do
      {:ok, record} ->
        send(self(), {:saved, record})
        {:noreply, socket |> put_flash(:info, "Announcement saved successfully.") |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :changeset, cs)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-5">
        <%= if @action == :new, do: "New Announcement", else: "Edit Announcement" %>
      </h2>

      <.form
        :let={f}
        for={@changeset}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <.input field={f[:display]} type="checkbox" label="Display (show to users)" />

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Message</label>
            <%!--
              Quill rich-text editor hook.
              The hidden input carries the value; its wrapper has phx-update="ignore"
              so LiveView does not clobber the DOM after Quill takes over the editor div.
            --%>
            <div phx-update="ignore" id="announcement-message-wrapper">
              <input
                type="hidden"
                id="announcement-message-value"
                name={f[:message].name}
                value={Phoenix.HTML.Form.normalize_value("hidden", f[:message].value)}
              />
            </div>
            <div
              id="announcement-message-editor"
              phx-hook="QuillEditor"
              data-input-id="announcement-message-value"
              class="min-h-[160px] border border-gray-300 rounded-md bg-white"
            >
            </div>
            <.error :for={msg <- Enum.map(f[:message].errors, &StreamClosedCaptionerPhoenixWeb.CoreComponents.translate_error/1)}>
              <%= msg %>
            </.error>
          </div>
        </div>

        <div class="flex justify-end gap-2 mt-6 pt-4 border-t border-gray-100">
          <button
            type="button"
            phx-click={JS.patch(@patch)}
            class="px-4 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <.button type="submit">Save Announcement</.button>
        </div>
      </.form>
    </div>
    """
  end
end
