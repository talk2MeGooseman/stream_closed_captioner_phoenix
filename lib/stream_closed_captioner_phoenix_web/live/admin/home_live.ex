defmodule StreamClosedCaptionerPhoenixWeb.Admin.HomeLive do
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Admin Dashboard")}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_header title="Admin Dashboard" />

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <.admin_card
        title="Users"
        description="Manage user accounts"
        navigate={~p"/admin/users"}
        icon="users"
      />
      <.admin_card
        title="Announcements"
        description="Manage site announcements"
        navigate={~p"/admin/announcements"}
        icon="announcements"
      />
      <.admin_card
        title="Bits Balances"
        description="View and manage bits balances"
        navigate={~p"/admin/bits-balances"}
        icon="bits"
      />
      <.admin_card
        title="Bits Transactions"
        description="Browse bits transaction history"
        navigate={~p"/admin/bits-transactions"}
        icon="transactions"
      />
      <.admin_card
        title="Bits Balance Debits"
        description="View debit records"
        navigate={~p"/admin/bits-balance-debits"}
        icon="debits"
      />
      <.admin_card
        title="Transcripts"
        description="Browse caption transcripts"
        navigate={~p"/admin/transcripts"}
        icon="transcripts"
      />
      <.admin_card
        title="Messages"
        description="Browse transcript messages"
        navigate={~p"/admin/messages"}
        icon="messages"
      />
      <.admin_card
        title="Stream Settings"
        description="Manage stream configurations"
        navigate={~p"/admin/stream-settings"}
        icon="settings"
      />
      <.admin_card
        title="Translate Languages"
        description="Manage translation language records"
        navigate={~p"/admin/translate-languages"}
        icon="languages"
      />
      <.admin_card
        title="EventSub Subscriptions"
        description="Manage Twitch EventSub subscriptions"
        navigate={~p"/admin/eventsub-subscriptions"}
        icon="eventsub"
      />
      <.admin_card
        title="User Tokens"
        description="View user session tokens"
        navigate={~p"/admin/user-tokens"}
        icon="tokens"
      />
    </div>
    """
  end

  defp admin_card(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class="block bg-white rounded-lg border border-gray-200 shadow-sm p-5 hover:shadow-md hover:border-indigo-300 transition-all group"
    >
      <div class="flex items-start gap-3">
        <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-indigo-50 group-hover:bg-indigo-100 flex items-center justify-center transition-colors">
          <svg class="w-5 h-5 text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
          </svg>
        </div>
        <div class="min-w-0">
          <h2 class="text-sm font-semibold text-gray-900 group-hover:text-indigo-700 transition-colors">
            <%= @title %>
          </h2>
          <p class="mt-0.5 text-xs text-gray-500"><%= @description %></p>
        </div>
        <div class="ml-auto flex-shrink-0 text-gray-300 group-hover:text-indigo-400 transition-colors">
          <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </div>
      </div>
    </.link>
    """
  end
end
