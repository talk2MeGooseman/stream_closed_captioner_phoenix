defmodule StreamClosedCaptionerPhoenixWeb.Admin.UserLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  alias StreamClosedCaptionerPhoenix.Admin

  @impl true
  def update(%{record: record} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, Admin.change_user(record))}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    cs =
      Admin.change_user(socket.assigns.record, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, cs)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    result =
      if socket.assigns.action == :new do
        Admin.create_user(params)
      else
        Admin.update_user(socket.assigns.record, params)
      end

    case result do
      {:ok, record} ->
        send(self(), {:saved, record})
        {:noreply, socket |> put_flash(:info, "User saved successfully.") |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :changeset, cs)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-5">
        <%= if @action == :new, do: "New User", else: "Edit User" %>
      </h2>

      <.form
        :let={f}
        for={@changeset}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <.input field={f[:email]} type="text" label="Email" />
            <.input field={f[:username]} type="text" label="Username" />
            <.input field={f[:login]} type="text" label="Login" />
            <.input field={f[:uid]} type="text" label="UID" />
            <.input field={f[:provider]} type="text" label="Provider" />
            <.input field={f[:sign_in_count]} type="number" label="Sign-in Count" />
          </div>

          <.input field={f[:description]} type="text" label="Description" />
          <.input field={f[:profile_image_url]} type="text" label="Profile Image URL" />
          <.input field={f[:offline_image_url]} type="text" label="Offline Image URL" />
          <.input field={f[:access_token]} type="text" label="Access Token" />
          <.input field={f[:refresh_token]} type="text" label="Refresh Token" />
        </div>

        <div class="flex justify-end gap-2 mt-6 pt-4 border-t border-gray-100">
          <button
            type="button"
            phx-click={JS.patch(@patch)}
            class="px-4 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <.button type="submit">Save User</.button>
        </div>
      </.form>
    </div>
    """
  end
end
