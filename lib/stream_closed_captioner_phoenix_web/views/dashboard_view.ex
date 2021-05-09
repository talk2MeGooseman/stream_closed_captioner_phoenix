defmodule StreamClosedCaptionerPhoenixWeb.DashboardView do
  use StreamClosedCaptionerPhoenixWeb, :view

  def display_translation_status(translation_active) when is_nil(translation_active),
    do: "Disabled"

  def display_translation_status(translation_active), do: "Enabled"
end
