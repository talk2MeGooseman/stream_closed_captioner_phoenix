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
    <div class="p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">
        {if @action == :new, do: "New Bits Transaction", else: "Edit Bits Transaction"}
      </h2>
      <.form
        :let={f}
        for={@changeset}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <.input field={f[:user_id]} type="number" label="User ID" />
          <.input field={f[:amount]} type="number" label="Amount" />
          <.input field={f[:display_name]} type="text" label="Display Name" />
          <.input field={f[:purchaser_uid]} type="text" label="Purchaser UID" />
          <.input field={f[:sku]} type="text" label="SKU" />
          <.input field={f[:transaction_id]} type="text" label="Transaction ID" />
          <.input field={f[:time]} type="datetime-local" label="Time" />
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
