defmodule StreamClosedCaptionerPhoenixWeb.Admin.EventsubSubscriptionLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component
  alias StreamClosedCaptionerPhoenix.Admin

  @impl true
  def update(%{record: record} = assigns, socket) do
    {:ok,
     socket |> assign(assigns) |> assign(changeset: Admin.change_eventsub_subscription(record))}
  end

  @impl true
  def handle_event("validate", %{"eventsub_subscription" => params}, socket) do
    cs =
      Admin.change_eventsub_subscription(socket.assigns.record, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: cs)}
  end

  def handle_event("save", %{"eventsub_subscription" => params}, socket) do
    result =
      if socket.assigns.action == :new do
        Admin.create_eventsub_subscription(params)
      else
        Admin.update_eventsub_subscription(socket.assigns.record, params)
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
        {if @action == :new, do: "New Eventsub Subscription", else: "Edit Eventsub Subscription"}
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
          <.input field={f[:type]} type="text" label="Type" />
          <.input field={f[:subscription_id]} type="text" label="Subscription ID" />
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
