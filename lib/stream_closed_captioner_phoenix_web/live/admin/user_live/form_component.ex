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
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <%= Phoenix.HTML.Form.text_input(f, :email,
                class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :email) %>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Username</label>
              <%= Phoenix.HTML.Form.text_input(f, :username,
                class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :username) %>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Login</label>
              <%= Phoenix.HTML.Form.text_input(f, :login,
                class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :login) %>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">UID</label>
              <%= Phoenix.HTML.Form.text_input(f, :uid,
                class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :uid) %>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Provider</label>
              <%= Phoenix.HTML.Form.text_input(f, :provider,
                class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :provider) %>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Sign-in Count</label>
              <%= Phoenix.HTML.Form.number_input(f, :sign_in_count,
                class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              ) %>
              <%= Phoenix.HTML.Form.error_tag(f, :sign_in_count) %>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <%= Phoenix.HTML.Form.text_input(f, :description,
              class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            ) %>
            <%= Phoenix.HTML.Form.error_tag(f, :description) %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Profile Image URL</label>
            <%= Phoenix.HTML.Form.text_input(f, :profile_image_url,
              class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            ) %>
            <%= Phoenix.HTML.Form.error_tag(f, :profile_image_url) %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Offline Image URL</label>
            <%= Phoenix.HTML.Form.text_input(f, :offline_image_url,
              class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            ) %>
            <%= Phoenix.HTML.Form.error_tag(f, :offline_image_url) %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Access Token</label>
            <%= Phoenix.HTML.Form.text_input(f, :access_token,
              class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            ) %>
            <%= Phoenix.HTML.Form.error_tag(f, :access_token) %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Refresh Token</label>
            <%= Phoenix.HTML.Form.text_input(f, :refresh_token,
              class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            ) %>
            <%= Phoenix.HTML.Form.error_tag(f, :refresh_token) %>
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
          <.button type="submit">Save User</.button>
        </div>
      </.form>
    </div>
    """
  end
end
