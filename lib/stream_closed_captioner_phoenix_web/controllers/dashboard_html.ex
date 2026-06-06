defmodule StreamClosedCaptionerPhoenixWeb.DashboardHTML do
  use StreamClosedCaptionerPhoenixWeb, :html
  embed_templates("dashboard/**/*")

  def display_translation_status(translation_active) when is_nil(translation_active),
    do: "Not Activated"

  def display_translation_status(_), do: "Activated"

  @doc "A single row in the System Status grid (label · value · state dot)."
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :state, :string, default: "ok"
  attr :icon, :string, required: true

  def sys_row(assigns) do
    ~H"""
    <div class="sysrow" data-state={@state}>
      <span class="s-dot"></span>
      <svg
        class="sysrow__ico"
        viewBox="0 0 24 24"
        width="17"
        height="17"
        fill="none"
        stroke="currentColor"
        stroke-width="1.9"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
      >
        <path d={@icon} />
      </svg>
      <span class="sysrow__txt">
        <span class="sysrow__lbl">{@label}</span>
        <span class="sysrow__val">{@value}</span>
      </span>
    </div>
    """
  end

  @doc "On/Off status label for a boolean setting."
  def on_off(true), do: "Enabled"
  def on_off(_), do: "Disabled"
end
