defmodule StreamClosedCaptionerPhoenixWeb.Components.Cards do
  @moduledoc """
  Card components
  """
  use Phoenix.Component

  attr(:shadow, :boolean, default: false)
  attr(:border, :boolean, default: false)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={[
      "p-6 bg-white rounded-lg dark:bg-gray-800",
      @border && "border border-gray-200 dark:border-gray-700",
      @shadow && "shadow"
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
