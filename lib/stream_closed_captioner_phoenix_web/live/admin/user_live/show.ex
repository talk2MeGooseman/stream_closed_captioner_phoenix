defmodule StreamClosedCaptionerPhoenixWeb.Admin.UserLive.Show do
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view

  alias StreamClosedCaptionerPhoenix.Admin
  alias StreamClosedCaptionerPhoenixWeb.Admin.UserLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, id)}
  end

  defp apply_action(socket, :show, _params, id) do
    user = Admin.get_user!(id)

    socket
    |> assign(:page_title, "User — #{user.username || user.email}")
    |> assign(:user, user)
    |> assign(:record, nil)
  end

  defp apply_action(socket, :edit, _params, id) do
    user = Admin.get_user!(id)

    socket
    |> assign(:page_title, "Edit User — #{user.username || user.email}")
    |> assign(:user, user)
    |> assign(:record, user)
  end

  @impl true
  def handle_info({:saved, user}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "User saved successfully.")
     |> assign(:user, Admin.get_user!(user.id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_header title={"User: #{@user.username || @user.email}"}>
      <:actions>
        <.admin_button patch={~p"/admin/users/#{@user.id}/show/edit"}>Edit User</.admin_button>
        <.admin_button navigate={~p"/admin/users"}>← All Users</.admin_button>
      </:actions>
    </.admin_page_header>

    <%!-- User Detail Card --%>
    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <h2 class="text-sm font-semibold text-gray-900">User Details</h2>
        <.edit_button patch={~p"/admin/users/#{@user.id}/show/edit"} />
      </div>
      <div class="px-5 py-4 grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3 text-sm">
        <div>
          <span class="text-gray-500 font-medium">ID</span>
          <span class="ml-2 text-gray-900"><%= @user.id %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Email</span>
          <span class="ml-2 text-gray-900"><%= @user.email || "—" %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Username</span>
          <span class="ml-2 text-gray-900"><%= @user.username || "—" %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Login</span>
          <span class="ml-2 text-gray-900"><%= @user.login || "—" %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">UID</span>
          <span class="ml-2 font-mono text-gray-900"><%= @user.uid || "—" %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Provider</span>
          <span class="ml-2 text-gray-900"><%= @user.provider || "—" %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Sign-in Count</span>
          <span class="ml-2 text-gray-900"><%= @user.sign_in_count || 0 %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Last Sign-in</span>
          <span class="ml-2 text-gray-900"><%= format_dt(@user.last_sign_in_at) %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Created</span>
          <span class="ml-2 text-gray-900"><%= format_dt(@user.created_at) %></span>
        </div>
      </div>
    </div>

    <%!-- Bits Balance --%>
    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-gray-900">Bits Balance</h2>
          <span class="text-xs bg-gray-100 text-gray-600 rounded-full px-2 py-0.5">
            <%= if @user.bits_balance, do: 1, else: 0 %>
          </span>
        </div>
        <.admin_button navigate={~p"/admin/bits-balances/new"}>+ New</.admin_button>
      </div>
      <div class="px-5 py-4 text-sm">
        <%= if @user.bits_balance do %>
          <div class="flex items-center gap-4">
            <.link navigate={~p"/admin/bits-balances/#{@user.bits_balance.id}/edit"} class="text-indigo-600 hover:underline font-mono">
              #<%= @user.bits_balance.id %>
            </.link>
            <span class="text-gray-600">Balance: <strong><%= @user.bits_balance.balance %></strong></span>
          </div>
        <% else %>
          <span class="text-gray-400">No bits balance record.</span>
        <% end %>
      </div>
    </div>

    <%!-- Bits Transactions --%>
    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-gray-900">Bits Transactions</h2>
          <span class="text-xs bg-gray-100 text-gray-600 rounded-full px-2 py-0.5">
            <%= length(@user.bits_transactions) %>
          </span>
        </div>
        <.admin_button navigate={~p"/admin/bits-transactions/new"}>+ New</.admin_button>
      </div>
      <div class="overflow-x-auto">
        <.admin_table id={"user-bits-transactions-#{@user.id}"} rows={@user.bits_transactions}>
          <:col :let={t} label="ID">
            <.link navigate={~p"/admin/bits-transactions/#{t.id}/edit"} class="text-indigo-600 hover:underline font-mono">
              #<%= t.id %>
            </.link>
          </:col>
          <:col :let={t} label="Amount"><%= t.amount %></:col>
          <:col :let={t} label="Display Name"><%= t.display_name || "—" %></:col>
          <:col :let={t} label="Purchaser UID"><%= t.purchaser_uid || "—" %></:col>
          <:col :let={t} label="SKU"><%= t.sku || "—" %></:col>
          <:col :let={t} label="Time"><%= t.time || "—" %></:col>
        </.admin_table>
      </div>
    </div>

    <%!-- Bits Balance Debits --%>
    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-gray-900">Bits Balance Debits</h2>
          <span class="text-xs bg-gray-100 text-gray-600 rounded-full px-2 py-0.5">
            <%= length(@user.bits_balance_debits) %>
          </span>
        </div>
        <.admin_button navigate={~p"/admin/bits-balance-debits/new"}>+ New</.admin_button>
      </div>
      <div class="overflow-x-auto">
        <.admin_table id={"user-bits-debits-#{@user.id}"} rows={@user.bits_balance_debits}>
          <:col :let={d} label="ID">
            <.link navigate={~p"/admin/bits-balance-debits/#{d.id}/edit"} class="text-indigo-600 hover:underline font-mono">
              #<%= d.id %>
            </.link>
          </:col>
          <:col :let={d} label="Amount"><%= d.amount %></:col>
          <:col :let={d} label="Created"><%= format_dt(d.created_at) %></:col>
        </.admin_table>
      </div>
    </div>

    <%!-- Stream Settings --%>
    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-gray-900">Stream Settings</h2>
          <span class="text-xs bg-gray-100 text-gray-600 rounded-full px-2 py-0.5">
            <%= if @user.stream_settings, do: 1, else: 0 %>
          </span>
        </div>
        <.admin_button navigate={~p"/admin/stream-settings/new"}>+ New</.admin_button>
      </div>
      <div class="px-5 py-4 text-sm">
        <%= if @user.stream_settings do %>
          <div class="flex items-center gap-4">
            <.link navigate={~p"/admin/stream-settings/#{@user.stream_settings.id}/edit"} class="text-indigo-600 hover:underline font-mono">
              #<%= @user.stream_settings.id %> — Edit Settings
            </.link>
          </div>
        <% else %>
          <span class="text-gray-400">No stream settings record.</span>
        <% end %>
      </div>
    </div>

    <%!-- Translate Languages --%>
    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-gray-900">Translate Languages</h2>
          <span class="text-xs bg-gray-100 text-gray-600 rounded-full px-2 py-0.5">
            <%= length(@user.translate_languages) %>
          </span>
        </div>
        <.admin_button navigate={~p"/admin/translate-languages/new"}>+ New</.admin_button>
      </div>
      <div class="overflow-x-auto">
        <.admin_table id={"user-translate-languages-#{@user.id}"} rows={@user.translate_languages}>
          <:col :let={l} label="ID">
            <.link navigate={~p"/admin/translate-languages/#{l.id}/edit"} class="text-indigo-600 hover:underline font-mono">
              #<%= l.id %>
            </.link>
          </:col>
          <:col :let={l} label="Language"><%= l.language %></:col>
        </.admin_table>
      </div>
    </div>

    <%!-- Transcripts --%>
    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-gray-900">Transcripts</h2>
          <span class="text-xs bg-gray-100 text-gray-600 rounded-full px-2 py-0.5">
            <%= length(@user.transcripts) %>
          </span>
        </div>
        <.admin_button navigate={~p"/admin/transcripts/new"}>+ New</.admin_button>
      </div>
      <div class="overflow-x-auto">
        <.admin_table id={"user-transcripts-#{@user.id}"} rows={@user.transcripts}>
          <:col :let={t} label="ID">
            <.link navigate={~p"/admin/transcripts/#{t.id}"} class="text-indigo-600 hover:underline font-mono">
              #<%= t.id %>
            </.link>
          </:col>
          <:col :let={t} label="Name"><%= t.name || "—" %></:col>
          <:col :let={t} label="Session"><%= t.session || "—" %></:col>
          <:col :let={t} label="Created"><%= format_dt(t.created_at) %></:col>
        </.admin_table>
      </div>
    </div>

    <%!-- EventSub Subscriptions --%>
    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-gray-900">EventSub Subscriptions</h2>
          <span class="text-xs bg-gray-100 text-gray-600 rounded-full px-2 py-0.5">
            <%= length(@user.eventsub_subscriptions) %>
          </span>
        </div>
        <.admin_button navigate={~p"/admin/eventsub-subscriptions/new"}>+ New</.admin_button>
      </div>
      <div class="overflow-x-auto">
        <.admin_table id={"user-eventsub-#{@user.id}"} rows={@user.eventsub_subscriptions}>
          <:col :let={e} label="ID">
            <.link navigate={~p"/admin/eventsub-subscriptions/#{e.id}/edit"} class="text-indigo-600 hover:underline font-mono">
              #<%= e.id %>
            </.link>
          </:col>
          <:col :let={e} label="Type"><%= e.type %></:col>
          <:col :let={e} label="Subscription ID"><span class="font-mono text-xs"><%= e.subscription_id %></span></:col>
        </.admin_table>
      </div>
    </div>

    <%= if @live_action == :edit do %>
      <.admin_modal
        id="user-show-form-modal"
        show={true}
        on_cancel={JS.patch(~p"/admin/users/#{@user.id}")}
      >
        <.live_component
          module={FormComponent}
          id={"user-show-edit-#{@user.id}"}
          record={@record}
          action={:edit}
          patch={~p"/admin/users/#{@user.id}"}
        />
      </.admin_modal>
    <% end %>
    """
  end

  defp format_dt(nil), do: "—"
  defp format_dt(dt), do: NaiveDateTime.to_string(dt) |> String.slice(0, 16)
end
