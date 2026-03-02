defmodule StreamClosedCaptionerPhoenixWeb.Components.Tables do
  @moduledoc """
  Table components
  """
  use Phoenix.Component
  import StreamClosedCaptionerPhoenixWeb.CoreComponents, only: [input: 1]

  attr(:id, :string, required: true)
  attr(:path, :any, required: true)
  attr(:items, :list, required: true)
  attr(:meta, :any)
  attr(:row_click, :any, default: nil)

  slot :col, required: true do
    attr(:label, :string)
    attr(:field, :atom)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def live_table(assigns) do
    assigns
    |> assign(
      opts: [
        container: true,
        container_attrs: [
          id: assigns[:id],
          class: "relative overflow-x-auto shadow-md sm:rounded-lg"
        ],
        no_results_content:
          Phoenix.HTML.Tag.content_tag(:div, "No results.",
            class: "text-base-content/50 text-3xl font-bold text-center py-12"
          ),
        table_attrs: [class: "w-full text-sm text-left text-gray-500 dark:text-gray-400"],
        tbody_tr_attrs: [
          class:
            "bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600"
        ],
        tbody_td_attrs: [class: "px-6 py-4"],
        thead_attrs: [
          class: "text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400"
        ],
        thead_th_attrs: [class: "px-6 py-3"]
      ]
    )
    |> Flop.Phoenix.table()
  end

  attr(:meta, :any, required: true)
  attr(:fields, :list, required: true)
  attr(:rule, :string, default: "ilike_and")
  attr(:class, :string, default: "pb-4 max-w-sm")

  def filter_form(%{meta: meta} = assigns) do
    assigns = assign(assigns, form: Phoenix.Component.to_form(meta), meta: nil)

    ~H"""
    <.form for={@form} phx-change="update-filter" class={@class}>
      <Flop.Phoenix.filter_fields :let={i} form={@form} fields={@fields}>
        <.input
          placeholder={"Filter by #{i.label}"}
          type={i.type}
          field={i.field}
          phx-debounce={120}
          class="block p-2 pl-10 text-sm text-gray-900 border border-gray-300 rounded-lg w-80 bg-gray-50 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
          {i.rest}
        />
      </Flop.Phoenix.filter_fields>
    </.form>
    """
  end

  attr(:path, :any, required: true)
  attr(:meta, :any, required: true)

  def pagination(assigns) do
    assigns =
      assigns
      |> assign(
        opts: [
          disabled_class: "cursor-not-allowed no-underline hover:no-underline text-opacity-50",
          next_link_attrs: [class: "text-sm font-semibold text-gray-900 dark:text-white"],
          previous_link_attrs: [class: "text-sm font-semibold text-gray-900 dark:text-white"],
          pagination_link_attrs: [class: "flex items-center"],
          pagination_list_attrs: [class: "hidden"]
        ]
      )

    ~H"""
    <div :if={@meta.total_count != 0} class="flex flex-col items-center my-4 space-y-4">
      <div class="text-sm font-normal text-gray-500 dark:text-gray-400">
        Showing
        <span class="font-semibold text-gray-900 dark:text-white">
          <%= @meta.current_offset + 1 %>
        </span>
        <span :if={@meta.total_pages != 1}>
          to
          <span class="font-semibold text-gray-900 dark:text-white">
            <%= @meta.next_offset || @meta.total_count %>
          </span>
        </span>
        of <span class="font-semibold text-gray-900 dark:text-white"><%= @meta.total_count %></span>
        Entries
      </div>
      <Flop.Phoenix.pagination :if={@meta.total_pages != 1} meta={@meta} path={@path} opts={@opts} />
    </div>
    """
  end
end
