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
          <%= if @action == :new, do: "New Stream Settings", else: "Edit Stream Settings" %>
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
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">User ID</label>
                <%= Phoenix.HTML.Form.number_input(f, :user_id,
                  class:
                    "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                ) %>
                <%= Phoenix.HTML.Form.error_tag(f, :user_id) %>
              </div>
            <% end %>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Language</label>
              <%= Phoenix.HTML.Form.text_input(f, :language,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :language) %>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Caption Delay</label>
              <%= Phoenix.HTML.Form.number_input(f, :caption_delay,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :caption_delay) %>
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div class="flex items-center gap-2">
                <%= Phoenix.HTML.Form.checkbox(f, :cc_box_size,
                  class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                ) %>
                <label class="text-sm text-gray-700">CC Box Size</label>
              </div>
              <div class="flex items-center gap-2">
                <%= Phoenix.HTML.Form.checkbox(f, :filter_profanity,
                  class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                ) %>
                <label class="text-sm text-gray-700">Filter Profanity</label>
              </div>
              <div class="flex items-center gap-2">
                <%= Phoenix.HTML.Form.checkbox(f, :hide_text_on_load,
                  class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                ) %>
                <label class="text-sm text-gray-700">Hide Text on Load</label>
              </div>
              <div class="flex items-center gap-2">
                <%= Phoenix.HTML.Form.checkbox(f, :pirate_mode,
                  class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                ) %>
                <label class="text-sm text-gray-700">Pirate Mode</label>
              </div>
              <div class="flex items-center gap-2">
                <%= Phoenix.HTML.Form.checkbox(f, :showcase,
                  class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                ) %>
                <label class="text-sm text-gray-700">Showcase</label>
              </div>
              <div class="flex items-center gap-2">
                <%= Phoenix.HTML.Form.checkbox(f, :switch_settings_position,
                  class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                ) %>
                <label class="text-sm text-gray-700">Switch Settings Position</label>
              </div>
              <div class="flex items-center gap-2">
                <%= Phoenix.HTML.Form.checkbox(f, :text_uppercase,
                  class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                ) %>
                <label class="text-sm text-gray-700">Text Uppercase</label>
              </div>
              <div class="flex items-center gap-2">
                <%= Phoenix.HTML.Form.checkbox(f, :turn_on_reminder,
                  class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                ) %>
                <label class="text-sm text-gray-700">Turn On Reminder</label>
              </div>
              <div class="flex items-center gap-2">
                <%= Phoenix.HTML.Form.checkbox(f, :auto_off_captions,
                  class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                ) %>
                <label class="text-sm text-gray-700">Auto Off Captions</label>
              </div>
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
