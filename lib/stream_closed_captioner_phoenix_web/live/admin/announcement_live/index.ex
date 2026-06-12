defmodule StreamClosedCaptionerPhoenixWeb.Admin.AnnouncementLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view

  alias StreamClosedCaptionerPhoenix.Admin
  alias StreamClosedCaptionerPhoenix.Announcement
  alias StreamClosedCaptionerPhoenixWeb.Admin.AnnouncementLive.FormComponent

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
    socket
    |> assign(:page_title, "Announcements")
    |> assign(:record, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Announcement")
    |> assign(:record, %Announcement{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Announcement")
    |> assign(:record, Admin.get_announcement!(id))
  end

  @impl true
  def handle_info({:saved, _record}, socket) do
    {:noreply, socket |> put_flash(:info, "Announcement saved successfully.") |> load_records()}
  end

  @impl true
  def handle_event("search", %{"search" => s}, socket) do
    {:noreply, socket |> assign(:search, s) |> assign(:page, 1) |> load_records()}
  end

  def handle_event("paginate", %{"page" => p}, socket) do
    {:noreply, socket |> assign(:page, String.to_integer(p)) |> load_records()}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    announcement = Admin.get_announcement!(id)
    {:ok, _} = Admin.delete_announcement(announcement)
    {:noreply, socket |> put_flash(:info, "Announcement deleted.") |> load_records()}
  end

  defp load_records(socket) do
    %{search: s, page: page} = socket.assigns
    records = Admin.list_announcements(s, page)
    count = Admin.count_announcements(s)
    total_pages = max(1, ceil(count / Admin.page_size()))
    assign(socket, records: records, total_count: count, total_pages: total_pages)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_header title="Announcements" count={@total_count}>
      <:actions>
        <.admin_button patch={~p"/admin/announcements/new"}>+ New Announcement</.admin_button>
      </:actions>
    </.admin_page_header>

    <.admin_search search={@search || ""} placeholder="Search by message..." />

    <.admin_table id="announcements-table" rows={@records} row_id={fn r -> "announcement-#{r.id}" end}>
      <:col :let={r} label="ID">{r.id}</:col>
      <:col :let={r} label="Display"><.bool_badge value={r.display || false} /></:col>
      <:col :let={r} label="Message">
        <span class="truncate max-w-xs block" title={r.message}>
          {truncate(r.message, 80)}
        </span>
      </:col>
      <:col :let={r} label="">
        <div class="flex items-center gap-1">
          <.edit_button patch={~p"/admin/announcements/#{r.id}/edit"} />
          <.danger_button
            phx-click="delete"
            phx-value-id={r.id}
            data-confirm="Are you sure you want to delete this announcement?"
          >
            Delete
          </.danger_button>
        </div>
      </:col>
    </.admin_table>

    <.admin_pagination page={@page} total_pages={@total_pages} />

    <%= if @live_action in [:new, :edit] do %>
      <.admin_modal
        id="announcement-form-modal"
        show={true}
        on_cancel={JS.patch(~p"/admin/announcements")}
      >
        <.live_component
          module={FormComponent}
          id={(@record && @record.id) || :new}
          record={@record}
          action={@live_action}
          patch={~p"/admin/announcements"}
        />
      </.admin_modal>
    <% end %>
    """
  end

  defp truncate(nil, _), do: "—"
  defp truncate(str, max) when byte_size(str) <= max, do: str
  defp truncate(str, max), do: String.slice(str, 0, max) <> "…"
end
