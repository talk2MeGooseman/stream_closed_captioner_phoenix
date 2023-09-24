defmodule StreamClosedCaptionerPhoenixWeb.CreditHistoryLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView
  import StreamClosedCaptionerPhoenixWeb.LiveHelpers

  alias StreamClosedCaptionerPhoenix.Bits

  def render(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="mt-11 w-[40rem] sm:w-full">
        <thead class="text-left text-[0.8125rem] leading-6 text-zinc-500">
          <tr>
            <th class="p-0 pb-4 pr-6 font-normal">Action</th>
            <th class="p-0 pb-4 pr-6 font-normal">Amount</th>
            <th class="p-0 pb-4 pr-6 font-normal">Date</th>
          </tr>
        </thead>
        <tbody
          id="transactions"
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={row[:id]} class="group">
            <td class="relative p-0">
              <div class="block py-4 pr-6">
                <span>
                  <%= row[:action] %>
                </span>
              </div>
            </td>
            <td class="relative p-0">
              <div class="block py-4 pr-6">
                <span>
                  <%= row[:amount] %>
                </span>
              </div>
            </td>
            <td class="relative p-0">
              <div class="block py-4 pr-6">
                <span>
                  <%= convert_timestamp_to_human_readable(row[:time]) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  def mount(_params, session, socket) do
    current_user = session_current_user(session)

    result = Bits.bits_transactions_and_debits_for_user(current_user.id, 0, 50)

    {:ok, assign(socket, :rows, result.records) |> assign(:temperature, 0)}
  end

  def handle_event("load_more", _value, socket) do
    {:ok, update(socket, :temperature, &(&1 + 1))}
  end

  def convert_timestamp_to_human_readable(timestamp) do
    Timex.to_datetime(timestamp, "Etc/UTC")
    |> Timex.format!("{UNIX}")
  end
end
