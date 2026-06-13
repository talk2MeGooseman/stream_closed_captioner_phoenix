defmodule StreamClosedCaptionerPhoenixWeb.Admin.UserTokenLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view

  alias StreamClosedCaptionerPhoenix.Admin

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(search: nil, page: 1) |> load_records()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "User Tokens", record: nil)
  end

  @impl true
  def handle_event("search", %{"search" => s}, socket) do
    {:noreply, socket |> assign(search: s, page: 1) |> load_records()}
  end

  def handle_event("paginate", %{"page" => p}, socket) do
    {:noreply, socket |> assign(page: String.to_integer(p)) |> load_records()}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = Admin.delete_user_token(Admin.get_user_token!(id))
    {:noreply, socket |> put_flash(:info, "Deleted.") |> load_records()}
  end

  defp load_records(socket) do
    %{search: s, page: page} = socket.assigns
    count = Admin.count_user_tokens(s)

    assign(socket,
      records: Admin.list_user_tokens(s, page),
      total_count: count,
      total_pages: max(1, ceil(count / Admin.page_size()))
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_header title="User Tokens" count={@total_count} />

    <.admin_search search={@search || ""} placeholder="Search by username or context..." />

    <.admin_table id="user-tokens-table" rows={@records} row_id={fn r -> "user-token-#{r.id}" end}>
      <:col :let={r} label="ID">{r.id}</:col>
      <:col :let={r} label="User"><.user_link user={r.user} /></:col>
      <:col :let={r} label="Context">{r.context}</:col>
      <:col :let={r} label="Sent To">{r.sent_to}</:col>
      <:col :let={r} label="Inserted At">{r.inserted_at}</:col>
      <:col :let={r} label="">
        <.danger_button
          phx-click="delete"
          phx-value-id={r.id}
          data-confirm="Are you sure you want to delete this token?"
        >
          Delete
        </.danger_button>
      </:col>
    </.admin_table>

    <.admin_pagination page={@page} total_pages={@total_pages} />
    """
  end
end
