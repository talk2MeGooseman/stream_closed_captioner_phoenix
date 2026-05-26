defmodule StreamClosedCaptionerPhoenixWeb.Admin.BitsTransactionLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component
  alias StreamClosedCaptionerPhoenix.Admin

  @impl true
  def update(%{record: record} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(changeset: Admin.change_bits_transaction(record))}
  end

  @impl true
  def handle_event("validate", %{"bits_transaction" => params}, socket) do
    cs =
      Admin.change_bits_transaction(socket.assigns.record, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: cs)}
  end

  def handle_event("save", %{"bits_transaction" => params}, socket) do
    result =
      if socket.assigns.action == :new do
        Admin.create_bits_transaction(params)
      else
        Admin.update_bits_transaction(socket.assigns.record, params)
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
    <.admin_modal id="bits-transaction-form" show={true} on_cancel={JS.patch(@patch)}>
      <div class="p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">
          <%= if @action == :new, do: "New Bits Transaction", else: "Edit Bits Transaction" %>
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
              <label class="block text-sm font-medium text-gray-700 mb-1">User ID</label>
              <%= Phoenix.HTML.Form.number_input(f, :user_id,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :user_id) %>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Amount</label>
              <%= Phoenix.HTML.Form.number_input(f, :amount,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :amount) %>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Display Name</label>
              <%= Phoenix.HTML.Form.text_input(f, :display_name,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :display_name) %>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Purchaser UID</label>
              <%= Phoenix.HTML.Form.text_input(f, :purchaser_uid,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :purchaser_uid) %>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">SKU</label>
              <%= Phoenix.HTML.Form.text_input(f, :sku,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :sku) %>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Transaction ID</label>
              <%= Phoenix.HTML.Form.text_input(f, :transaction_id,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :transaction_id) %>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Time</label>
              <%= Phoenix.HTML.Form.datetime_local_input(f, :time,
                class:
                  "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :time) %>
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
    </.admin_modal>
    """
  end
end
