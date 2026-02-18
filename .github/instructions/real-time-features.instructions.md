---
description: 'Real-time features with Phoenix Channels, LiveView, and PubSub'
applyTo: '**/channels/**/*.ex, **/live/**/*.ex, **/live/**/*.heex'
---

# Real-time Features with Phoenix

## Overview

Phoenix provides three primary tools for real-time functionality:
- **Phoenix Channels**: Bidirectional WebSocket communication
- **Phoenix LiveView**: Server-rendered real-time UI without JavaScript
- **Phoenix PubSub**: Message broadcasting across processes and nodes

## Phoenix Channels

### Channel Module Structure
```elixir
defmodule MyAppWeb.CaptionsChannel do
  use MyAppWeb, :channel

  @impl true
  def join("captions:" <> user_id, _payload, socket) do
    if authorized?(socket, user_id) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("new_message", %{"text" => text}, socket) do
    # Handle incoming message
    broadcast!(socket, "new_message", %{text: text})
    {:reply, {:ok, %{status: "sent"}}, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    # Send initial data after join
    push(socket, "initial_data", %{messages: load_messages()})
    {:noreply, socket}
  end

  defp authorized?(socket, user_id) do
    socket.assigns.current_user.id == String.to_integer(user_id)
  end
end
```

### Socket Authentication
```elixir
defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "captions:*", MyAppWeb.CaptionsChannel
  channel "room:*", MyAppWeb.RoomChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case MyApp.Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        user = MyApp.Accounts.get_user!(claims["sub"])
        {:ok, assign(socket, :current_user, user)}

      {:error, _reason} ->
        :error
    end
  end

  @impl true
  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
```

### Channel Patterns

#### Broadcasting
```elixir
# Broadcast to all clients on the topic
broadcast(socket, "new_message", %{text: "Hello"})

# Broadcast to everyone except sender
broadcast_from(socket, "new_message", %{text: "Hello"})

# Broadcast using PubSub directly
MyAppWeb.Endpoint.broadcast("captions:123", "new_message", %{text: "Hello"})

# Broadcast from another process
MyAppWeb.Endpoint.broadcast_from(self(), "captions:123", "update", %{})
```

#### Reply Patterns
```elixir
def handle_in("ping", _payload, socket) do
  # Reply with success
  {:reply, {:ok, %{pong: true}}, socket}
end

def handle_in("save", payload, socket) do
  case save_data(payload) do
    {:ok, data} ->
      {:reply, {:ok, data}, socket}

    {:error, changeset} ->
      {:reply, {:error, %{errors: format_errors(changeset)}}, socket}
  end
end

# No reply needed
def handle_in("analytics", payload, socket) do
  track_analytics(payload)
  {:noreply, socket}
end
```

#### Tracking Presence
```elixir
defmodule MyAppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: MyApp.PubSub
end

# Track user presence in channel
defmodule MyAppWeb.RoomChannel do
  use MyAppWeb, :channel
  alias MyAppWeb.Presence

  def join("room:" <> room_id, _params, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, :room_id, room_id)}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.current_user.id, %{
      online_at: inspect(System.system_time(:second)),
      username: socket.assigns.current_user.name
    })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
end
```

### Client-Side Channel (JavaScript)
```javascript
import { Socket } from "phoenix"

const socket = new Socket("/socket", {
  params: { token: window.userToken }
})

socket.connect()

const channel = socket.channel("captions:123", {})

channel.join()
  .receive("ok", resp => console.log("Joined successfully", resp))
  .receive("error", resp => console.log("Unable to join", resp))

// Send message to server
channel.push("new_message", { text: "Hello" })
  .receive("ok", payload => console.log("Message sent", payload))
  .receive("error", err => console.log("Error", err))

// Listen for broadcasts
channel.on("new_message", payload => {
  console.log("New message:", payload)
})

// Handle disconnection
socket.onError(() => console.log("Socket error"))
socket.onClose(() => console.log("Socket closed"))
```

## Phoenix LiveView

### Basic LiveView Module
```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to PubSub topics on connected mount
      Phoenix.PubSub.subscribe(MyApp.PubSub, "captions:updates")
    end

    {:ok, assign(socket, captions: load_captions(), loading: false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <h1>Dashboard</h1>

      <%= if @loading do %>
        <div class="spinner">Loading...</div>
      <% else %>
        <div class="captions">
          <%= for caption <- @captions do %>
            <div class="caption" data-id={caption.id}>
              <%= caption.text %>
            </div>
          <% end %>
        </div>
      <% end %>

      <button phx-click="refresh">Refresh</button>
    </div>
    """
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, assign(socket, captions: load_captions())}
  end

  @impl true
  def handle_info({:new_caption, caption}, socket) do
    {:noreply, update(socket, :captions, fn captions -> [caption | captions] end)}
  end

  defp load_captions do
    MyApp.Captions.list_recent_captions()
  end
end
```

### LiveView Events

#### Client Events (phx-click, phx-submit, etc.)
```heex
<!-- Click events -->
<button phx-click="save">Save</button>
<button phx-click="delete" phx-value-id={@item.id}>Delete</button>

<!-- Form submission -->
<form phx-submit="create_user">
  <input type="text" name="user[name]" />
  <button type="submit">Create</button>
</form>

<!-- Change events -->
<input phx-change="validate" type="text" name="email" />

<!-- Blur and Focus -->
<input phx-blur="validate_final" type="text" />
<input phx-focus="highlight" type="text" />

<!-- Key events -->
<input phx-keydown="key_pressed" phx-key="Enter" type="text" />

<!-- Window events -->
<div phx-window-keydown="global_key_handler">...</div>
```

#### Server Event Handlers
```elixir
def handle_event("save", %{"user" => user_params}, socket) do
  case Accounts.create_user(user_params) do
    {:ok, user} ->
      {:noreply,
        socket
        |> put_flash(:info, "User created successfully")
        |> push_redirect(to: Routes.user_path(socket, :show, user))}

    {:error, changeset} ->
      {:noreply, assign(socket, changeset: changeset)}
  end
end

def handle_event("delete", %{"id" => id}, socket) do
  Accounts.delete_user(id)
  {:noreply, assign(socket, users: load_users())}
end
```

### LiveView Forms and Changesets
```elixir
defmodule MyAppWeb.UserFormLive do
  use MyAppWeb, :live_view

  alias MyApp.Accounts
  alias MyApp.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user(%User{})

    {:ok, assign(socket,
      changeset: changeset,
      trigger_submit: false
    )}
  end

  def render(assigns) do
    ~H"""
    <.form
      let={f}
      for={@changeset}
      phx-change="validate"
      phx-submit="save"
      phx-trigger-action={@trigger_submit}
    >
      <.input field={f[:name]} type="text" label="Name" />
      <.input field={f[:email]} type="email" label="Email" />

      <button type="submit">Save</button>
    </.form>
    """
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        {:noreply,
          socket
          |> put_flash(:info, "User created")
          |> push_navigate(to: Routes.user_path(socket, :show, user))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
```

### LiveView Components

#### Function Components
```elixir
defmodule MyAppWeb.CoreComponents do
  use Phoenix.Component

  attr :user, :map, required: true
  attr :class, :string, default: ""

  def user_card(assigns) do
    ~H"""
    <div class={"user-card #{@class}"}>
      <img src={@user.avatar_url} alt={@user.name} />
      <h3><%= @user.name %></h3>
      <p><%= @user.email %></p>
    </div>
    """
  end

  slot :inner_block, required: true
  attr :title, :string, required: true

  def card(assigns) do
    ~H"""
    <div class="card">
      <h2 class="card-title"><%= @title %></h2>
      <div class="card-body">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
```

#### Stateful Components
```elixir
defmodule MyAppWeb.SearchComponent do
  use MyAppWeb, :live_component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <form phx-submit="search" phx-target={@myself}>
      <input
        type="text"
        name="query"
        value={@query}
        phx-change="query_changed"
        phx-target={@myself}
        phx-debounce="300"
      />
      <button type="submit">Search</button>
    </form>
    """
  end

  def handle_event("query_changed", %{"query" => query}, socket) do
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    send(self(), {:search, query})
    {:noreply, socket}
  end
end

# Usage in parent LiveView
~H"""
<.live_component
  module={MyAppWeb.SearchComponent}
  id="search"
  query={@search_query}
/>
"""
```

### LiveView Navigation
```elixir
# Navigate to new path (adds to browser history)
push_navigate(socket, to: "/users")

# Redirect (replaces browser history)
push_redirect(socket, to: "/dashboard")

# Patch (updates URL without remounting)
push_patch(socket, to: "/users?page=2")
```

### LiveView Uploads
```elixir
def mount(_params, _session, socket) do
  {:ok,
    socket
    |> assign(:uploaded_files, [])
    |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
end

def render(assigns) do
  ~H"""
  <form phx-submit="save" phx-change="validate">
    <.live_file_input upload={@uploads.avatar} />
    <button type="submit">Upload</button>
  </form>
  """
end

def handle_event("validate", _params, socket) do
  {:noreply, socket}
end

def handle_event("save", _params, socket) do
  consumed_files =
    consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
      dest = Path.join("priv/static/uploads", entry.client_name)
      File.cp!(path, dest)
      Routes.static_path(socket, "/uploads/#{entry.client_name}")
    end)

  {:noreply, update(socket, :uploaded_files, &(&1 ++ consumed_files))}
end
```

## Phoenix PubSub

### Broadcasting Messages
```elixir
# Broadcast to subscribers of a topic
Phoenix.PubSub.broadcast(MyApp.PubSub, "captions:updates", {:new_caption, caption})

# Broadcast from sender process
Phoenix.PubSub.broadcast_from(MyApp.PubSub, self(), "captions:updates", {:update, data})

# Local broadcast (current node only)
Phoenix.PubSub.local_broadcast(MyApp.PubSub, "topic", {:event, data})
```

### Subscribing to Topics
```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "captions:updates")
      Phoenix.PubSub.subscribe(MyApp.PubSub, "user:#{socket.assigns.current_user.id}")
    end

    {:ok, socket}
  end

  def handle_info({:new_caption, caption}, socket) do
    # Handle broadcasted message
    {:noreply, update(socket, :captions, fn caps -> [caption | caps] end)}
  end
end
```

### Dynamic Topics
```elixir
# Subscribe to user-specific channels
def mount(%{"room_id" => room_id}, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "room:#{room_id}")
  end

  {:ok, assign(socket, room_id: room_id)}
end

# Broadcast to specific room
def publish_to_room(room_id, message) do
  Phoenix.PubSub.broadcast(MyApp.PubSub, "room:#{room_id}", {:new_message, message})
end
```

## Best Practices

### Channels
- Always authenticate users in `connect/3` callback
- Use pattern matching in topic names for authorization
- Handle `terminate/2` callback for cleanup
- Use `assign/3` to store socket state
- Don't store large data in socket assigns
- Use `handle_info/2` for async operations

### LiveView
- Use `connected?(socket)` to differentiate initial vs connected mount
- Prefer server-side validation with changesets
- Use components to break down complex views
- Minimize socket assigns (only store what's needed)
- Use temporary assigns for large lists (`assign(socket, :items, temporary_assigns: true)`)
- Debounce expensive operations (`phx-debounce="300"`)

### PubSub
- Keep topic names consistent and predictable
- Don't broadcast large payloads frequently
- Use local_broadcast for single-node operations
- Subscribe in `mount/3` when `connected?(socket)` is true
- Unsubscribe is automatic on process termination

## Performance Optimization

### Rate Limiting Broadcasts
```elixir
defmodule MyAppWeb.CaptionsChannel do
  use MyAppWeb, :channel

  def handle_in("new_caption", params, socket) do
    # Throttle broadcasts to every 100ms
    case Process.get(:last_broadcast_time) do
      nil ->
        broadcast_caption(socket, params)

      last_time ->
        if System.monotonic_time(:millisecond) - last_time > 100 do
          broadcast_caption(socket, params)
        end
    end

    {:noreply, socket}
  end

  defp broadcast_caption(socket, params) do
    broadcast!(socket, "caption_update", params)
    Process.put(:last_broadcast_time, System.monotonic_time(:millisecond))
  end
end
```

### Temporary Assigns in LiveView
```elixir
def mount(_params, _session, socket) do
  {:ok,
    socket
    |> assign(:items, [])
    |> stream(:messages, [])  # Use streams for large lists
  }
end
```

### Pagination in LiveView
```elixir
def handle_event("load_more", _params, socket) do
  new_items = load_items(socket.assigns.page + 1)

  {:noreply,
    socket
    |> update(:items, &(&1 ++ new_items))
    |> assign(:page, socket.assigns.page + 1)}
end
```

## Testing

### Channel Testing
```elixir
test "joins and receives initial data", %{user: user} do
  {:ok, _, socket} =
    MyAppWeb.UserSocket
    |> socket("user_id", %{current_user: user})
    |> subscribe_and_join(MyAppWeb.CaptionsChannel, "captions:#{user.id}")

  assert_push "initial_data", %{captions: captions}
end
```

### LiveView Testing
```elixir
test "renders and updates caption", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/dashboard")

  assert render(view) =~ "Dashboard"

  # Simulate server pushing update
  send(view.pid, {:new_caption, %{text: "Test"}})

  assert render(view) =~ "Test"
end
```

## Resources

- [Phoenix Channels Documentation](https://hexdocs.pm/phoenix/channels.html)
- [Phoenix LiveView Documentation](https://hexdocs.pm/phoenix_live_view/)
- [Phoenix PubSub Documentation](https://hexdocs.pm/phoenix_pubsub/)
- [Phoenix Presence Documentation](https://hexdocs.pm/phoenix/presence.html)
