defmodule StreamClosedCaptionerPhoenixWeb.Admin.MessageLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component
  alias StreamClosedCaptionerPhoenix.Admin

  @impl true
  def update(%{record: record} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(changeset: Admin.change_message(record))}
  end

  @impl true
  def handle_event("validate", %{"message" => params}, socket) do
    cs =
      Admin.change_message(socket.assigns.record, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: cs)}
  end

  def handle_event("save", %{"message" => params}, socket) do
    result =
      if socket.assigns.action == :new do
        Admin.create_message(params)
      else
        Admin.update_message(socket.assigns.record, params)
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
          <%= if @action == :new, do: "New Message", else: "Edit Message" %>
        </h2>
        <.form
          :let={f}
          for={@changeset}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Transcript ID</label>
              <%= Phoenix.HTML.Form.number_input(f, :transcript_id,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :transcript_id) %>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Text</label>
              <%= Phoenix.HTML.Form.textarea(f, :text,
                rows: 4,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :text) %>
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
