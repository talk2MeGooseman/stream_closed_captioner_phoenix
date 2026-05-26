defmodule StreamClosedCaptionerPhoenixWeb.AdminComponents do
  use Phoenix.Component
  import Phoenix.HTML

  alias Phoenix.LiveView.JS

  @doc "Page header with title and optional action button."
  attr :title, :string, required: true
  attr :count, :integer, default: nil
  slot :actions

  def admin_page_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-baseline gap-3">
        <h1 class="text-xl font-bold text-gray-900"><%= @title %></h1>
        <%= if @count do %>
          <span class="text-sm text-gray-500"><%= @count %> records</span>
        <% end %>
      </div>
      <div class="flex items-center gap-2">
        <%= render_slot(@actions) %>
      </div>
    </div>
    """
  end

  @doc "Search bar."
  attr :search, :string, default: ""
  attr :placeholder, :string, default: "Search..."

  def admin_search(assigns) do
    ~H"""
    <form phx-submit="search" phx-change="search" class="mb-4">
      <div class="relative max-w-sm">
        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <svg class="h-4 w-4 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
        </div>
        <input
          type="text"
          name="search"
          value={@search}
          placeholder={@placeholder}
          class="block w-full pl-9 pr-3 py-2 text-sm border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500 bg-white"
          phx-debounce="300"
        />
      </div>
    </form>
    """
  end

  @doc "Data table wrapper with head and rows."
  slot :col, required: true do
    attr :label, :string
  end

  attr :rows, :list, required: true
  attr :id, :string, required: true
  attr :row_id, :any, default: nil
  attr :row_click, :any, default: nil

  def admin_table(assigns) do
    ~H"""
    <div class="overflow-x-auto bg-white rounded-lg shadow border border-gray-200">
      <table class="min-w-full divide-y divide-gray-200 text-sm">
        <thead class="bg-gray-50">
          <tr>
            <%= for col <- @col do %>
              <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider whitespace-nowrap">
                <%= col[:label] %>
              </th>
            <% end %>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100" id={@id}>
          <%= for row <- @rows do %>
            <tr
              id={@row_id && @row_id.(row)}
              class={["hover:bg-gray-50 transition-colors", @row_click && "cursor-pointer"]}
              phx-click={@row_click && @row_click.(row)}
            >
              <%= for col <- @col do %>
                <td class="px-4 py-3 text-gray-700 max-w-xs truncate">
                  <%= render_slot(col, row) %>
                </td>
              <% end %>
            </tr>
          <% end %>

          <%= if Enum.empty?(@rows) do %>
            <tr>
              <td colspan={length(@col)} class="px-4 py-8 text-center text-gray-400 text-sm">
                No records found.
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @doc "Pagination controls."
  attr :page, :integer, required: true
  attr :total_pages, :integer, required: true

  def admin_pagination(assigns) do
    ~H"""
    <%= if @total_pages > 1 do %>
      <div class="flex items-center justify-between mt-4 text-sm text-gray-600">
        <span>Page <%= @page %> of <%= @total_pages %></span>
        <div class="flex items-center gap-1">
          <button
            phx-click="paginate"
            phx-value-page={@page - 1}
            disabled={@page <= 1}
            class="px-3 py-1.5 rounded border border-gray-300 bg-white hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >
            &larr; Prev
          </button>
          <%= for p <- page_range(@page, @total_pages) do %>
            <%= if p == :ellipsis do %>
              <span class="px-2">…</span>
            <% else %>
              <button
                phx-click="paginate"
                phx-value-page={p}
                class={[
                  "px-3 py-1.5 rounded border transition-colors",
                  if(p == @page, do: "bg-indigo-600 border-indigo-600 text-white", else: "border-gray-300 bg-white hover:bg-gray-50")
                ]}
              >
                <%= p %>
              </button>
            <% end %>
          <% end %>
          <button
            phx-click="paginate"
            phx-value-page={@page + 1}
            disabled={@page >= @total_pages}
            class="px-3 py-1.5 rounded border border-gray-300 bg-white hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >
            Next &rarr;
          </button>
        </div>
      </div>
    <% end %>
    """
  end

  @doc "Foreign-key link badge — renders user as a clickable link to the admin user show page."
  attr :user, :any, default: nil

  def user_link(assigns) do
    ~H"""
    <%= if @user do %>
      <.link navigate={~p"/admin/users/#{@user.id}"} class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800 hover:bg-indigo-200 transition-colors whitespace-nowrap">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/></svg>
        <%= @user.username || @user.email || "##{@user.id}" %>
      </.link>
    <% else %>
      <span class="text-gray-400 text-xs">—</span>
    <% end %>
    """
  end

  @doc "Transcript link badge."
  attr :transcript, :any, default: nil

  def transcript_link(assigns) do
    ~H"""
    <%= if @transcript do %>
      <.link navigate={~p"/admin/transcripts/#{@transcript.id}"} class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800 hover:bg-purple-200 transition-colors whitespace-nowrap">
        <%= @transcript.name || "##{@transcript.id}" %>
      </.link>
    <% else %>
      <span class="text-gray-400 text-xs">—</span>
    <% end %>
    """
  end

  @doc "Boolean badge."
  attr :value, :boolean, required: true

  def bool_badge(assigns) do
    ~H"""
    <%= if @value do %>
      <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700">Yes</span>
    <% else %>
      <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-500">No</span>
    <% end %>
    """
  end

  @doc "Primary admin button."
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def admin_button(assigns) do
    ~H"""
    <%= if @patch || @navigate do %>
      <.link
        patch={@patch}
        navigate={@navigate}
        class="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium rounded-md bg-indigo-600 text-white hover:bg-indigo-700 transition-colors"
        {@rest}
      >
        <%= render_slot(@inner_block) %>
      </.link>
    <% else %>
      <button
        class="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium rounded-md bg-indigo-600 text-white hover:bg-indigo-700 transition-colors"
        {@rest}
      >
        <%= render_slot(@inner_block) %>
      </button>
    <% end %>
    """
  end

  @doc "Danger (delete) button."
  attr :rest, :global
  slot :inner_block, required: true

  def danger_button(assigns) do
    ~H"""
    <button
      class="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-medium rounded text-red-700 hover:bg-red-50 transition-colors border border-red-200"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc "Edit link button."
  attr :patch, :string, required: true

  def edit_button(assigns) do
    ~H"""
    <.link
      patch={@patch}
      class="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-medium rounded text-indigo-700 hover:bg-indigo-50 transition-colors border border-indigo-200"
    >
      Edit
    </.link>
    """
  end

  @doc "View link button."
  attr :navigate, :string, required: true

  def view_button(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-medium rounded text-gray-700 hover:bg-gray-100 transition-colors border border-gray-200"
    >
      View
    </.link>
    """
  end

  @doc "Modal container for create/edit forms."
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def admin_modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      class="hidden relative z-50"
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-gray-900/70 backdrop-blur-sm transition-opacity" aria-hidden="true" />
      <div class="fixed inset-0 overflow-y-auto flex min-h-full items-center justify-center p-4">
        <div
          id={"#{@id}-container"}
          phx-click-away={@on_cancel}
          phx-window-keydown={@on_cancel}
          phx-key="escape"
          class="w-full max-w-2xl bg-white rounded-xl shadow-xl ring-1 ring-gray-200"
        >
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  defp show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(to: "##{id}-bg", transition: {"transition-opacity ease-out duration-200", "opacity-0", "opacity-100"})
    |> JS.show(to: "##{id}-container", transition: {"transition-all ease-out duration-200", "opacity-0 scale-95", "opacity-100 scale-100"})
  end

  defp hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}-bg", transition: {"transition-opacity ease-in duration-150", "opacity-100", "opacity-0"})
    |> JS.hide(to: "##{id}-container", transition: {"transition-all ease-in duration-150", "opacity-100 scale-100", "opacity-0 scale-95"})
    |> JS.hide(to: "##{id}", transition: {"block", "block", "block"})
  end

  defp page_range(current, total) do
    cond do
      total <= 7 ->
        Enum.to_list(1..total)

      current <= 4 ->
        Enum.to_list(1..5) ++ [:ellipsis, total]

      current >= total - 3 ->
        [1, :ellipsis] ++ Enum.to_list((total - 4)..total)

      true ->
        [1, :ellipsis] ++ Enum.to_list((current - 1)..(current + 1)) ++ [:ellipsis, total]
    end
  end
end
