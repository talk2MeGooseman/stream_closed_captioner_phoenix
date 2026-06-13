defmodule StreamClosedCaptionerPhoenixWeb.Admin.UserLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view

  alias StreamClosedCaptionerPhoenix.Admin
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenixWeb.Admin.UserLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:search, nil)
     |> assign(:page, 1)
     |> load_records()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, "Users") |> assign(:record, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket |> assign(:page_title, "New User") |> assign(:record, %User{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket |> assign(:page_title, "Edit User") |> assign(:record, Admin.get_user!(id))
  end

  @impl true
  def handle_info({:saved, _record}, socket) do
    {:noreply, socket |> put_flash(:info, "User saved successfully.") |> load_records()}
  end

  @impl true
  def handle_event("search", %{"search" => s}, socket) do
    {:noreply, socket |> assign(:search, s) |> assign(:page, 1) |> load_records()}
  end

  def handle_event("paginate", %{"page" => p}, socket) do
    {:noreply, socket |> assign(:page, String.to_integer(p)) |> load_records()}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = Admin.delete_user(Admin.get_user!(id))
    {:noreply, socket |> put_flash(:info, "User deleted.") |> load_records()}
  end

  defp load_records(socket) do
    %{search: s, page: page} = socket.assigns
    count = Admin.count_users(s)

    assign(socket,
      records: Admin.list_users(s, page),
      total_count: count,
      total_pages: max(1, ceil(count / Admin.page_size()))
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_header title="Users" count={@total_count}>
      <:actions>
        <.admin_button patch={~p"/admin/users/new"}>+ New User</.admin_button>
      </:actions>
    </.admin_page_header>

    <.admin_search search={@search || ""} placeholder="Search by username, email, or uid..." />

    <.admin_table id="users-table" rows={@records} row_id={fn u -> "user-#{u.id}" end}>
      <:col :let={u} label="ID">{u.id}</:col>
      <:col :let={u} label="Username">{u.username}</:col>
      <:col :let={u} label="Email">{u.email}</:col>
      <:col :let={u} label="UID"><span class="font-mono text-xs">{u.uid}</span></:col>
      <:col :let={u} label="Provider">{u.provider}</:col>
      <:col :let={u} label="Sign-ins">{u.sign_in_count}</:col>
      <:col :let={u} label="Created">{format_dt(u.created_at)}</:col>
      <:col :let={u} label="">
        <div class="flex items-center gap-1">
          <.view_button navigate={~p"/admin/users/#{u.id}"} />
          <.edit_button patch={~p"/admin/users/#{u.id}/edit"} />
          <.danger_button
            phx-click="delete"
            phx-value-id={u.id}
            data-confirm="Are you sure you want to delete this user? This cannot be undone."
          >Delete</.danger_button>
        </div>
      </:col>
    </.admin_table>

    <.admin_pagination page={@page} total_pages={@total_pages} />

    <%= if @live_action in [:new, :edit] do %>
      <.admin_modal id="user-form-modal" show={true} on_cancel={JS.patch(~p"/admin/users")}>
        <.live_component
          module={FormComponent}
          id={(@record && @record.id) || :new}
          record={@record}
          action={@live_action}
          patch={~p"/admin/users"}
        />
      </.admin_modal>
    <% end %>
    """
  end

  defp format_dt(nil), do: "—"
  defp format_dt(dt), do: NaiveDateTime.to_string(dt) |> String.slice(0, 16)
end
