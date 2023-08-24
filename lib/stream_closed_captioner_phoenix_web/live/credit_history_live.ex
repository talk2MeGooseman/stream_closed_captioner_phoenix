defmodule StreamClosedCaptionerPhoenixWeb.CreditHistoryLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView
  import StreamClosedCaptionerPhoenixWeb.LiveHelpers

  alias StreamClosedCaptionerPhoenix.Bits.BitsTransactionQueries

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
      <ul class="list">
        <%= for entry <- @list do %>
          <li class="list-item"><%= entry.action %></li>
        <% end %>
      </ul>
    </div>
    """
  end

  def mount(_params, session, socket) do
    current_user = session_current_user(session)

    list = BitsTransactionQueries.get_bits_transactions_and_debits_for_user(current_user.id)

    {:ok, assign(socket, :list, list)}
  end

  # def handle_event("inc_temperature", _params, socket) do
  #   {:ok, update(socket, :temperature, &(&1 + 1))}
  # end
end
