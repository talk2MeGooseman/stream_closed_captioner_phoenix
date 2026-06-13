defmodule StreamClosedCaptionerPhoenixWeb.Admin.BitsBalanceDebitLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view
  alias StreamClosedCaptionerPhoenix.Admin
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(search: nil, page: 1) |> load_records()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "Bits Balance Debits", record: nil)
  end

  defp apply_action(socket, :new, _params) do
    socket |> assign(page_title: "New Bits Balance Debit", record: %BitsBalanceDebit{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(page_title: "Edit Bits Balance Debit", record: Admin.get_bits_balance_debit!(id))
  end

  @impl true
  def handle_info({:saved, _record}, socket) do
    {:noreply, socket |> put_flash(:info, "Saved.") |> load_records()}
  end

  @impl true
  def handle_event("search", %{"search" => s}, socket) do
    {:noreply, socket |> assign(search: s, page: 1) |> load_records()}
  end

  def handle_event("paginate", %{"page" => p}, socket) do
    {:noreply, socket |> assign(page: String.to_integer(p)) |> load_records()}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = Admin.delete_bits_balance_debit(Admin.get_bits_balance_debit!(id))
    {:noreply, socket |> put_flash(:info, "Deleted.") |> load_records()}
  end

  defp load_records(socket) do
    %{search: s, page: page} = socket.assigns
    count = Admin.count_bits_balance_debits(s)

    assign(socket,
      records: Admin.list_bits_balance_debits(s, page),
      total_count: count,
      total_pages: max(1, ceil(count / Admin.page_size()))
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_header title="Bits Balance Debits" count={@total_count}>
      <:actions>
        <.admin_button patch={~p"/admin/bits-balance-debits/new"}>
          New Bits Balance Debit
        </.admin_button>
      </:actions>
    </.admin_page_header>

    <.admin_search search={@search || ""} placeholder="Search by username..." />

    <.admin_table
      id="bits-balance-debits"
      rows={@records}
      row_id={fn r -> "bits-balance-debit-#{r.id}" end}
    >
      <:col :let={r} label="ID">{r.id}</:col>
      <:col :let={r} label="User"><.user_link user={r.user} /></:col>
      <:col :let={r} label="Amount">{r.amount}</:col>
      <:col :let={r} label="Created At">{r.created_at}</:col>
      <:col :let={r} label="Actions">
        <div class="flex items-center gap-1">
          <.edit_button patch={~p"/admin/bits-balance-debits/#{r.id}/edit"} />
          <.danger_button
            phx-click="delete"
            phx-value-id={r.id}
            data-confirm="Are you sure you want to delete this record?"
          >
            Delete
          </.danger_button>
        </div>
      </:col>
    </.admin_table>

    <.admin_pagination page={@page} total_pages={@total_pages} />

    <%= if @live_action in [:new, :edit] do %>
      <.admin_modal
        id="bits-balance-debit-form-modal"
        show={true}
        on_cancel={JS.patch(~p"/admin/bits-balance-debits")}
      >
        <.live_component
          module={StreamClosedCaptionerPhoenixWeb.Admin.BitsBalanceDebitLive.FormComponent}
          id={
            if @record.id,
              do: "edit-bits-balance-debit-#{@record.id}",
              else: "new-bits-balance-debit"
          }
          action={@live_action}
          record={@record}
          patch={~p"/admin/bits-balance-debits"}
        />
      </.admin_modal>
    <% end %>
    """
  end
end
