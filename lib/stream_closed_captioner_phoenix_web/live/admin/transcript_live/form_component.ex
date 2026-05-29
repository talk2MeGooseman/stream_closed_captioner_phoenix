defmodule StreamClosedCaptionerPhoenixWeb.Admin.TranscriptLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component
  alias StreamClosedCaptionerPhoenix.Admin

  @impl true
  def update(%{record: record} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(changeset: Admin.change_transcript(record))}
  end

  @impl true
  def handle_event("validate", %{"transcript" => params}, socket) do
    cs =
      Admin.change_transcript(socket.assigns.record, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: cs)}
  end

  def handle_event("save", %{"transcript" => params}, socket) do
    result =
      if socket.assigns.action == :new do
        Admin.create_transcript(params)
      else
        Admin.update_transcript(socket.assigns.record, params)
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
          <%= if @action == :new, do: "New Transcript", else: "Edit Transcript" %>
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
              <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
              <%= Phoenix.HTML.Form.text_input(f, :name,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :name) %>
            </div>
            <%= if @action == :new do %>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Session</label>
                <%= Phoenix.HTML.Form.text_input(f, :session,
                  class:
                    "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                ) %>
                <%= Phoenix.HTML.Form.error_tag(f, :session) %>
              </div>
            <% end %>
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
