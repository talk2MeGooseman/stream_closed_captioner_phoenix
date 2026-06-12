defmodule StreamClosedCaptionerPhoenixWeb.Admin.TranslateLanguageLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view

  alias StreamClosedCaptionerPhoenix.Admin
  alias StreamClosedCaptionerPhoenix.Settings.TranslateLanguage
  alias StreamClosedCaptionerPhoenixWeb.Admin.TranslateLanguageLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(search: nil, page: 1) |> load_records()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "Translate Languages", record: nil)
  end

  defp apply_action(socket, :new, _params) do
    socket |> assign(page_title: "New Translate Language", record: %TranslateLanguage{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(page_title: "Edit Translate Language", record: Admin.get_translate_language!(id))
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
    {:ok, _} = Admin.delete_translate_language(Admin.get_translate_language!(id))
    {:noreply, socket |> put_flash(:info, "Deleted.") |> load_records()}
  end

  defp load_records(socket) do
    %{search: s, page: page} = socket.assigns
    count = Admin.count_translate_languages(s)

    assign(socket,
      records: Admin.list_translate_languages(s, page),
      total_count: count,
      total_pages: max(1, ceil(count / Admin.page_size()))
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_header title="Translate Languages" count={@total_count}>
      <:actions>
        <.admin_button patch={~p"/admin/translate-languages/new"}>+ New Translate Language</.admin_button>
      </:actions>
    </.admin_page_header>

    <.admin_search search={@search || ""} placeholder="Search by username..." />

    <.admin_table
      id="translate-languages-table"
      rows={@records}
      row_id={fn r -> "translate-language-#{r.id}" end}
    >
      <:col :let={r} label="ID">{r.id}</:col>
      <:col :let={r} label="User"><.user_link user={r.user} /></:col>
      <:col :let={r} label="Language">{r.language}</:col>
      <:col :let={r} label="Created At">{r.created_at}</:col>
      <:col :let={r} label="">
        <div class="flex items-center gap-1">
          <.edit_button patch={~p"/admin/translate-languages/#{r.id}/edit"} />
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
        id="translate-language-form-modal"
        show={true}
        on_cancel={JS.patch(~p"/admin/translate-languages")}
      >
        <.live_component
          module={FormComponent}
          id={(@record && @record.id) || :new}
          record={@record}
          action={@live_action}
          patch={~p"/admin/translate-languages"}
        />
      </.admin_modal>
    <% end %>
    """
  end
end
