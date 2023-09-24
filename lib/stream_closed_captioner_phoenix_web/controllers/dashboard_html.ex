defmodule StreamClosedCaptionerPhoenixWeb.DashboardHTML do
  use StreamClosedCaptionerPhoenixWeb, :html
  embed_templates("dashboard/**/*")

  def display_translation_status(translation_active) when is_nil(translation_active),
    do: "Not Activated"

  def display_translation_status(_), do: "Activated"
end
