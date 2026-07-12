defmodule StreamClosedCaptionerPhoenixWeb.Admin.LocalExtensionTestingLive do
  @moduledoc """
  Admin-only helper for testing the Twitch extension front end locally against
  live caption traffic.

  The page is reachable only through the `:admin_protected` pipeline (the owner
  account, `uid == "120750024"`), so the ability to watch any currently-live
  channel's captions stays restricted to the admin.

  It lists every channel that is currently publishing captions. Each channel
  gets one-click links that open the local extension dev build (default
  `http://localhost:8080`) with a short-lived socket token minted for that
  channel, the channel id, and this deploy's origin carried in the URL
  fragment, so the local build connects straight to that broadcaster's live
  caption stream on this backend.

  The local build can only reach this deploy's websocket and GraphQL API if its
  origin is in `LOCAL_EXT_TESTING_ORIGINS` (see `config/runtime.exs`).
  """
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.AccountsOauth
  alias StreamClosedCaptionerPhoenixWeb.Endpoint
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
     |> assign(:form, build_form(@default_local_base, ""))
     |> assign(:socket_token, mint_socket_token(Accounts.owner_id()))
     |> assign(:active_channels, active_channels)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, assign(socket, :active_channels, load_active_channels())}
  end

  @impl true
  def handle_event("update_form", %{"local_base" => base, "manual_channel" => manual}, socket) do
    manual = String.trim(manual)

    {:noreply,
     socket
     |> assign(:local_base, base)
     |> assign(:manual_channel, manual)
     |> assign(:form, build_form(base, manual))}
  end

  @impl true
  def handle_event("regenerate_token", _params, socket) do
    {:noreply, assign(socket, :socket_token, mint_socket_token(Accounts.owner_id()))}
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

      <.form
        for={@form}
        id="local-dev-form"
        phx-change="update_form"
        phx-submit="update_form"
        class="grid grid-cols-1 sm:grid-cols-2 gap-4"
      >
        <div>
          <.input field={@form[:local_base]} type="text" label="Local extension URL" />
          <p class="mt-1 text-xs text-gray-500">
            Where your <code>yarn start</code> dev server is served.
          </p>
        </div>
        <div>
          <.input
            field={@form[:manual_channel]}
            type="text"
            label="Manual channel id (optional)"
            placeholder="Twitch channel/user id"
          />
          <p class="mt-1 text-xs text-gray-500">
            Target a specific channel even if it isn't listed below.
          </p>
        </div>
      </.form>

      <div :if={@manual_channel != ""} class="rounded-md border border-gray-200 p-4">
        <p class="text-sm font-medium text-gray-900">Manual channel: {@manual_channel}</p>
        <.dev_links base={@local_base} channel={@manual_channel} class="mt-2" />
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

        <ul
          :if={@active_channels != []}
          role="list"
          class="divide-y divide-gray-200 border border-gray-200 rounded-md"
        >
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
            <.dev_links base={@local_base} channel={channel.uid} class="flex-shrink-0" />
          </li>
        </ul>
      </div>

      <div>
        <.input
          type="textarea"
          id="socket_token"
          name="socket_token"
          value={@socket_token}
          label="Socket token (minted for your own channel — for manual pasting into the extension dev dialog)"
          rows="3"
          readonly
        />
        <p class="mt-1 text-xs text-gray-500">
          Short-lived (~2h). The channel links above mint their own per-channel tokens.
        </p>
      </div>
    </div>
    """
  end

  attr(:base, :string, required: true)
  attr(:channel, :string, required: true)
  attr(:class, :string, default: nil)

  defp dev_links(assigns) do
    ~H"""
    <div class={["flex flex-wrap gap-3", @class]}>
      <a
        :for={{anchor, label} <- [{"video_overlay", "Overlay →"}, {"mobile", "Mobile →"}]}
        href={dev_link(@base, @channel, anchor)}
        target="_blank"
        rel="noopener"
        class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
      >
        {label}
      </a>
    </div>
    """
  end

  defp build_form(base, manual) do
    to_form(%{"local_base" => base, "manual_channel" => manual})
  end

  defp mint_socket_token(channel_id) do
    Twitch.Jwt.sign_token_for(:standard, channel_id).jwt_token
  end

  defp load_active_channels do
    uids = UserTracker.recently_active_channels()

    # One batch lookup instead of a query per live channel.
    names =
      "twitch"
      |> AccountsOauth.users_for_provider(uids)
      |> Map.new(fn user -> {user.uid, user.username || user.login} end)

    uids
    |> Enum.map(fn uid -> %{uid: uid, name: Map.get(names, uid)} end)
    |> Enum.sort_by(fn %{name: name, uid: uid} -> String.downcase(name || uid) end)
  end

  # Builds the local extension URL. The overlay entry point needs both anchor
  # and platform — the extension's isVideoOverlay() requires platform=web, so
  # links mirror the query string Twitch itself uses. Token, channel id, and
  # this deploy's origin ride in the fragment so they are never sent to the
  # local dev server (the extension reads them client-side). The token is
  # minted per channel because channel-scoped GraphQL resolvers read the
  # token's channel_id claim, not the query argument — a shared admin token
  # would resolve every query to the admin's own channel.
  defp dev_link(base, channel, anchor) do
    query = URI.encode_query([{"anchor", anchor}, {"platform", platform_for(anchor)}])

    fragment =
      URI.encode_query([
        {"scc_dev_token", mint_socket_token(channel)},
        {"scc_dev_channel", channel},
        {"scc_dev_backend", Endpoint.url()}
      ])

    "#{normalize_base(base)}/?#{query}##{fragment}"
  end

  defp platform_for("video_overlay"), do: "web"
  defp platform_for(_anchor), do: "mobile"

  # Reconstructs a clean http(s) origin from the entered base so the generated
  # hrefs can't become unsafe or broken. Anything without an http(s) scheme and
  # host (empty, "javascript:...", protocol-relative) falls back to the default,
  # and any userinfo/path/query/fragment the operator pasted is dropped.
  defp normalize_base(base) do
    trimmed = base |> to_string() |> String.trim()

    case trimmed |> ensure_http_scheme() |> URI.parse() do
      %URI{scheme: scheme, host: host} = uri
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        port = if uri.port in [nil, 80, 443], do: "", else: ":#{uri.port}"
        "#{scheme}://#{host}#{port}"

      _ ->
        @default_local_base
    end
  end

  # "localhost:9000"-style pastes get an http:// prefix instead of silently
  # falling back to the default base. Only host[:port] shapes qualify — anything
  # else (e.g. "javascript:alert(1)") is left for the http(s) guard to reject.
  defp ensure_http_scheme(base) do
    if base =~ ~r/^[A-Za-z0-9.\-]+(:\d{1,5})?$/ do
      "http://" <> base
    else
      base
    end
  end
end
