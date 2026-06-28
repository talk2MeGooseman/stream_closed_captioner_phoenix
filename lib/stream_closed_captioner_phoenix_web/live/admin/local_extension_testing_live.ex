defmodule StreamClosedCaptionerPhoenixWeb.Admin.LocalExtensionTestingLive do
  @moduledoc """
  Admin-only helper for testing the Twitch extension front end locally against
  live caption traffic.

  The page is reachable only through the `:admin_protected` pipeline (the owner
  account, `uid == "120750024"`), so the ability to watch any currently-live
  channel's captions stays restricted to the admin.

  It mints a short-lived socket token and lists every channel that is currently
  publishing captions. Each channel gets a one-click link that opens the local
  extension dev build (default `http://localhost:8080`) with the token and
  channel id carried in the URL fragment, so the local build connects straight
  to that broadcaster's live caption stream.

  The local build can only reach this deploy's websocket if its origin is in
  `LOCAL_EXT_TESTING_ORIGINS` (see `config/runtime.exs`).
  """
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.AccountsOauth
  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  @default_local_base "http://localhost:8080"

  @impl true
  def mount(_params, _session, socket) do
    # mount/3 runs twice (disconnected HTTP render, then connected). Defer the
    # Tracker scan + OAuth lookups to the connected mount so the initial render
    # stays cheap and the work isn't done twice.
    active_channels = if connected?(socket), do: load_active_channels(), else: []

    {:ok,
     socket
     |> assign(:page_title, "Local Extension Testing")
     |> assign(:local_base, @default_local_base)
     |> assign(:manual_channel, "")
     |> assign(:socket_token, mint_socket_token())
     |> assign(:active_channels, active_channels)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, assign(socket, :active_channels, load_active_channels())}
  end

  @impl true
  def handle_event("update_form", %{"local_base" => base, "manual_channel" => manual}, socket) do
    {:noreply,
     socket
     |> assign(:local_base, base)
     |> assign(:manual_channel, String.trim(manual))}
  end

  @impl true
  def handle_event("regenerate_token", _params, socket) do
    {:noreply, assign(socket, :socket_token, mint_socket_token())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_header title="Local Extension Testing" count={length(@active_channels)}>
      <:actions>
        <.admin_button phx-click="refresh">Refresh</.admin_button>
      </:actions>
    </.admin_page_header>

    <div class="space-y-6">
      <div class="rounded-md bg-amber-50 border border-amber-200 p-4 text-sm text-amber-800">
        <p class="font-semibold">Admin-only local testing</p>
        <p class="mt-1">
          Use this page to drive the extension front end on your machine against real,
          currently-live captions. The local build can only connect if this deploy's
          <code class="font-mono">LOCAL_EXT_TESTING_ORIGINS</code>
          includes your local origin (e.g. <code class="font-mono">http://localhost:8080</code>).
        </p>
      </div>

      <form
        id="local-dev-form"
        phx-change="update_form"
        phx-submit="update_form"
        class="grid grid-cols-1 sm:grid-cols-2 gap-4"
      >
        <div>
          <label for="local_base" class="block text-sm font-medium text-gray-700">
            Local extension URL
          </label>
          <input
            type="text"
            name="local_base"
            id="local_base"
            value={@local_base}
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm text-sm font-mono"
          />
          <p class="mt-1 text-xs text-gray-500">Where your <code>yarn start</code> dev server is served.</p>
        </div>
        <div>
          <label for="manual_channel" class="block text-sm font-medium text-gray-700">
            Manual channel id (optional)
          </label>
          <input
            type="text"
            name="manual_channel"
            id="manual_channel"
            value={@manual_channel}
            placeholder="Twitch channel/user id"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm text-sm font-mono"
          />
          <p class="mt-1 text-xs text-gray-500">Target a specific channel even if it isn't listed below.</p>
        </div>
      </form>

      <div :if={@manual_channel != ""} class="rounded-md border border-gray-200 p-4">
        <p class="text-sm font-medium text-gray-900">Manual channel: {@manual_channel}</p>
        <div class="mt-2 flex flex-wrap gap-3">
          <a
            href={dev_link(@local_base, @socket_token, @manual_channel, "video_overlay")}
            target="_blank"
            rel="noopener"
            class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
          >
            Open video overlay →
          </a>
          <a
            href={dev_link(@local_base, @socket_token, @manual_channel, "mobile")}
            target="_blank"
            rel="noopener"
            class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
          >
            Open mobile →
          </a>
        </div>
      </div>

      <div>
        <div class="flex items-center justify-between mb-2">
          <h2 class="text-sm font-semibold text-gray-900">Currently live channels</h2>
          <button
            type="button"
            phx-click="regenerate_token"
            class="text-xs text-gray-500 hover:text-gray-700 underline"
          >
            Regenerate token
          </button>
        </div>

        <p :if={@active_channels == []} class="text-sm text-gray-500">
          No channels are currently captioning. Click "Refresh" once a broadcaster is live.
        </p>

        <ul :if={@active_channels != []} role="list" class="divide-y divide-gray-200 border border-gray-200 rounded-md">
          <li
            :for={channel <- @active_channels}
            id={"channel-#{channel.uid}"}
            class="flex items-center justify-between gap-4 px-4 py-3"
          >
            <div class="min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">
                {channel.name || "Unknown"}
              </p>
              <p class="text-xs text-gray-500 font-mono truncate">{channel.uid}</p>
            </div>
            <div class="flex flex-shrink-0 flex-wrap gap-3">
              <a
                href={dev_link(@local_base, @socket_token, channel.uid, "video_overlay")}
                target="_blank"
                rel="noopener"
                class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
              >
                Overlay →
              </a>
              <a
                href={dev_link(@local_base, @socket_token, channel.uid, "mobile")}
                target="_blank"
                rel="noopener"
                class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
              >
                Mobile →
              </a>
            </div>
          </li>
        </ul>
      </div>

      <div>
        <label for="socket_token" class="block text-sm font-medium text-gray-700">
          Socket token (auto-included in the links above)
        </label>
        <textarea
          id="socket_token"
          rows="3"
          readonly
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm text-xs font-mono break-all"
        >{@socket_token}</textarea>
        <p class="mt-1 text-xs text-gray-500">
          Short-lived; paste it manually into the extension dev controls if you need to.
        </p>
      </div>
    </div>
    """
  end

  defp mint_socket_token do
    Twitch.Jwt.sign_token_for(:standard, Accounts.owner_id()).jwt_token
  end

  defp load_active_channels do
    UserTracker.recently_active_channels()
    |> Enum.map(fn uid -> %{uid: uid, name: channel_name(uid)} end)
    |> Enum.sort_by(fn %{name: name, uid: uid} -> String.downcase(name || uid) end)
  end

  defp channel_name(uid) do
    case AccountsOauth.get_user_for_provider("twitch", uid) do
      nil -> nil
      user -> user.username || user.login
    end
  end

  # Builds the local extension URL. Token + channel ride in the fragment so they
  # are never sent to the server (the extension reads them client-side).
  # Values are URI-encoded so a channel id with reserved characters can't
  # produce a malformed URL the extension can't parse.
  defp dev_link(base, token, channel, anchor) do
    query = URI.encode_query([{"anchor", anchor}])
    fragment = URI.encode_query([{"scc_dev_token", token}, {"scc_dev_channel", channel}])

    "#{normalize_base(base)}/?#{query}##{fragment}"
  end

  # Reconstructs a clean http(s) origin from the entered base so the generated
  # hrefs can't become unsafe or broken. Anything without an http(s) scheme and
  # host (empty, "javascript:...", protocol-relative) falls back to the default,
  # and any userinfo/path/query/fragment the operator pasted is dropped.
  defp normalize_base(base) do
    case base |> to_string() |> String.trim() |> URI.parse() do
      %URI{scheme: scheme, host: host} = uri
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        port = if uri.port in [nil, 80, 443], do: "", else: ":#{uri.port}"
        "#{scheme}://#{host}#{port}"

      _ ->
        @default_local_base
    end
  end
end
