defmodule StreamClosedCaptionerPhoenixWeb.Components.Dropdowns do
  @moduledoc """
  Dropdown components
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  def toggle_dropdown(id, js \\ %JS{}) do
    js
    |> JS.toggle(
      to: id,
      in:
        {"transition ease-out duration-150", "opacity-0 translate-y-1",
         "opacity-100 translate-y-0"},
      out:
        {"transition ease-in duration-100", "opacity-100 translate-y-0",
         "opacity-0 translate-y-1"}
    )
  end

  def close_dropdown(id, js \\ %JS{}) do
    js
    |> JS.hide(
      to: id,
      transition:
        {"transition ease-in duration-100", "opacity-100 translate-y-0",
         "opacity-0 translate-y-1"}
    )
  end
end
