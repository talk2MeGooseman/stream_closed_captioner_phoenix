---
description: 'Testing best practices for Elixir/Phoenix applications using ExUnit'
applyTo: 'test/**/*.exs, test/**/*.ex'
---

# Testing Best Practices

## General Guidelines

- Write tests before or alongside implementation (TDD/BDD)
- Keep tests isolated and independent
- Use descriptive test names that explain what is being tested
- Follow the Arrange-Act-Assert (AAA) pattern
- Use `describe` blocks to group related tests
- Leverage `setup` and `setup_all` for test fixtures
- Mock external dependencies and APIs
- Test both happy paths and error cases
- Aim for high test coverage but focus on critical paths
- Run tests frequently during development
- Keep tests fast and deterministic

## Test Organization

### Directory Structure
```
test/
├── support/
│   ├── conn_case.ex          # Controller test helpers
│   ├── channel_case.ex       # Channel test helpers
│   ├── data_case.ex          # Database test helpers
│   ├── factory.ex            # Test data factories
│   └── fixtures/             # Test fixtures
├── my_app/
│   ├── accounts_test.exs     # Context tests
│   ├── captions_pipeline_test.exs
│   └── services/
│       └── twitch_test.exs   # Service tests
└── my_app_web/
    ├── controllers/
    │   └── user_controller_test.exs
    ├── channels/
    │   └── captions_channel_test.exs
    ├── live/
    │   └── dashboard_live_test.exs
    └── schema/
        └── user_queries_test.exs
```

## Test Cases

### Data Case for Database Tests
```elixir
defmodule MyApp.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias MyApp.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MyApp.DataCase
      import MyApp.Factory
    end
  end

  setup tags do
    MyApp.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
```

### Conn Case for Controller Tests
```elixir
defmodule MyAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import MyAppWeb.ConnCase
      import MyApp.Factory

      alias MyAppWeb.Router.Helpers, as: Routes

      @endpoint MyAppWeb.Endpoint
    end
  end

  setup tags do
    MyApp.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def authenticate(conn, user) do
    {:ok, token, _claims} = MyApp.Guardian.encode_and_sign(user)
    put_req_header(conn, "authorization", "Bearer #{token}")
  end
end
```

## Context Testing

### Basic Context Test
```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase, async: true

  alias MyApp.Accounts

  describe "users" do
    @valid_attrs %{email: "test@example.com", name: "Test User"}
    @invalid_attrs %{email: nil, name: nil}

    test "list_users/0 returns all users" do
      user = insert(:user)
      assert Accounts.list_users() == [user]
    end

    test "get_user/1 returns the user with given id" do
      user = insert(:user)
      assert Accounts.get_user(user.id) == user
    end

    test "get_user/1 returns nil when user doesn't exist" do
      assert Accounts.get_user(999) == nil
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "test@example.com"
      assert user.name == "Test User"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = insert(:user)
      update_attrs = %{name: "Updated Name"}

      assert {:ok, %User{} = updated_user} = Accounts.update_user(user, update_attrs)
      assert updated_user.name == "Updated Name"
    end

    test "delete_user/1 deletes the user" do
      user = insert(:user)
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Accounts.get_user(user.id) == nil
    end
  end
end
```

## Controller Testing

### Basic Controller Test
```elixir
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase, async: true

  setup %{conn: conn} do
    user = insert(:user)
    conn = authenticate(conn, user)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert html_response(conn, 200) =~ "Users"
    end
  end

  describe "create" do
    test "creates user with valid data", %{conn: conn} do
      attrs = params_for(:user)
      conn = post(conn, Routes.user_path(conn, :create), user: attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.user_path(conn, :show, id)
    end

    test "returns errors with invalid data", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: %{})
      assert html_response(conn, 200) =~ "Oops, something went wrong"
    end
  end
end
```

### JSON API Controller Test
```elixir
defmodule MyAppWeb.Api.UserControllerTest do
  use MyAppWeb.ConnCase, async: true

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn}
  end

  describe "GET /api/users" do
    test "returns list of users", %{conn: conn} do
      users = insert_list(3, :user)

      conn = get(conn, Routes.api_user_path(conn, :index))

      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) == 3
    end
  end

  describe "POST /api/users" do
    test "creates user with valid data", %{conn: conn} do
      attrs = %{email: "test@example.com", name: "Test"}

      conn = post(conn, Routes.api_user_path(conn, :create), user: attrs)

      assert %{"data" => %{"id" => id}} = json_response(conn, 201)
    end

    test "returns 422 with invalid data", %{conn: conn} do
      conn = post(conn, Routes.api_user_path(conn, :create), user: %{})

      assert %{"errors" => errors} = json_response(conn, 422)
    end
  end
end
```

## Channel Testing

### Phoenix Channel Test
```elixir
defmodule MyAppWeb.CaptionsChannelTest do
  use MyAppWeb.ChannelCase, async: true

  setup do
    user = insert(:user)
    {:ok, _, socket} =
      MyAppWeb.UserSocket
      |> socket("user_id", %{current_user: user})
      |> subscribe_and_join(MyAppWeb.CaptionsChannel, "captions:#{user.id}")

    {:ok, socket: socket, user: user}
  end

  test "join returns ok", %{socket: socket} do
    assert socket
  end

  test "publishes caption to subscribers", %{socket: socket} do
    payload = %{final: "Hello world", interim: ""}

    push(socket, "publishFinal", payload)

    assert_broadcast "new_caption", %{final: "Hello world"}
  end

  test "handles twitch-enabled captions", %{socket: socket, user: user} do
    payload = %{
      final: "Test caption",
      twitch: %{enabled: true}
    }

    ref = push(socket, "publishFinal", payload)

    assert_reply ref, :ok, %{final: "Test caption"}
  end
end
```

## LiveView Testing

### LiveView Test
```elixir
defmodule MyAppWeb.DashboardLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyApp.Factory

  setup %{conn: conn} do
    user = insert(:user)
    conn = authenticate(conn, user)
    {:ok, conn: conn, user: user}
  end

  test "renders dashboard", %{conn: conn} do
    {:ok, view, html} = live(conn, "/dashboard")

    assert html =~ "Dashboard"
    assert has_element?(view, "#caption-actions")
  end

  test "starts captions on button click", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/dashboard")

    view
    |> element("#start-captions")
    |> render_click()

    assert has_element?(view, "#stop-captions")
  end

  test "updates settings", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/dashboard/settings")

    view
    |> form("#settings-form", stream_settings: %{language: "es-ES"})
    |> render_submit()

    assert render(view) =~ "Settings updated"
  end
end
```

## GraphQL Testing

### GraphQL Query Test
```elixir
defmodule MyAppWeb.Schema.UserQueriesTest do
  use MyAppWeb.ConnCase, async: true

  @user_query """
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      email
      name
    }
  }
  """

  test "gets user by ID", %{conn: conn} do
    user = insert(:user)

    conn = post(conn, "/api/graphql", %{
      query: @user_query,
      variables: %{id: user.id}
    })

    assert %{
      "data" => %{
        "user" => %{
          "id" => id,
          "email" => email
        }
      }
    } = json_response(conn, 200)

    assert id == to_string(user.id)
    assert email == user.email
  end
end
```

## Testing Factories with ExMachina

### Define Factories
```elixir
defmodule MyApp.Factory do
  use ExMachina.Ecto, repo: MyApp.Repo

  def user_factory do
    %MyApp.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      name: "Test User",
      provider: "twitch",
      uid: sequence(:uid, &"twitch_#{&1}")
    }
  end

  def stream_settings_factory do
    %MyApp.Settings.StreamSettings{
      language: "en-US",
      profanity_filter: true,
      pirate_mode: false,
      user: build(:user)
    }
  end

  def caption_factory do
    %MyApp.Transcripts.Caption{
      text: "Sample caption text",
      user: build(:user),
      session_id: sequence(:session, &"session_#{&1}")
    }
  end
end
```

### Use Factories in Tests
```elixir
# Create a single record
user = insert(:user)

# Create with custom attributes
user = insert(:user, name: "Custom Name")

# Create multiple records
users = insert_list(3, :user)

# Build without inserting
user = build(:user)

# Build associations
user = insert(:user, stream_settings: build(:stream_settings))

# Generate params (for forms)
params = params_for(:user)
```

## Mocking External Services

### Using Mox for Behavior Mocks
```elixir
# Define behavior
defmodule MyApp.TwitchBehaviour do
  @callback get_user(String.t()) :: {:ok, map()} | {:error, term()}
end

# Define mock in test helper
Mox.defmock(MyApp.TwitchMock, for: MyApp.TwitchBehaviour)

# Configure application to use mock in test
config :my_app, :twitch_client, MyApp.TwitchMock

# Use in test
defmodule MyApp.AccountsTest do
  use MyApp.DataCase

  import Mox

  setup :verify_on_exit!

  test "syncs user from Twitch" do
    expect(MyApp.TwitchMock, :get_user, fn "123" ->
      {:ok, %{id: "123", name: "streamer"}}
    end)

    assert {:ok, user} = Accounts.sync_from_twitch("123")
    assert user.name == "streamer"
  end
end
```

### Using Bypass for HTTP Mocks
```elixir
defmodule MyApp.ExternalApiTest do
  use MyApp.DataCase

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "fetches data from API", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/users/123", fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(%{id: 123, name: "Test"}))
    end)

    url = "http://localhost:#{bypass.port}/users/123"
    assert {:ok, data} = MyApp.ExternalApi.fetch_user(url, "123")
    assert data.name == "Test"
  end
end
```

## Async Testing

### Enable Async Tests
```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase, async: true  # Run tests concurrently

  # Tests that don't share state can run async
end
```

### When NOT to Use Async
- Tests that modify global state
- Tests that use Sandbox in shared mode
- Tests that depend on specific timing
- Tests that use external services without mocks

## Testing Best Practices

### Use Descriptive Test Names
```elixir
# Bad
test "test user" do
  # ...
end

# Good
test "creates user with valid email and password" do
  # ...
end
```

### Follow AAA Pattern
```elixir
test "calculates total price with tax" do
  # Arrange
  cart = insert(:cart)
  insert_list(3, :item, cart: cart, price: 10.00)

  # Act
  total = Cart.calculate_total(cart, tax_rate: 0.08)

  # Assert
  assert total == Decimal.new("32.40")
end
```

### Test Edge Cases
```elixir
describe "divide/2" do
  test "divides two positive numbers" do
    assert Calculator.divide(10, 2) == 5.0
  end

  test "handles division by zero" do
    assert Calculator.divide(10, 0) == {:error, :division_by_zero}
  end

  test "handles negative numbers" do
    assert Calculator.divide(-10, 2) == -5.0
  end
end
```

### Use Setup for Common Data
```elixir
describe "user actions" do
  setup do
    user = insert(:user)
    {:ok, user: user}
  end

  test "updates profile", %{user: user} do
    # user is available here
  end

  test "deletes account", %{user: user} do
    # user is available here
  end
end
```

## Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/my_app/accounts_test.exs

# Run specific test by line number
mix test test/my_app/accounts_test.exs:42

# Run tests matching pattern
mix test --only wip
mix test --exclude integration

# Run with coverage
mix test --cover

# Run in watch mode (requires mix_test_interactive)
mix test.interactive
```

## Test Tags

```elixir
@tag :integration
test "integrates with external API" do
  # This test is tagged
end

@tag timeout: 60_000
test "long running operation" do
  # Custom timeout
end
```

## Coverage

```elixir
# Generate coverage report
mix test --cover

# View detailed coverage
mix test --cover && open cover/excoveralls.html
```

## Resources

- [ExUnit Documentation](https://hexdocs.pm/ex_unit/)
- [ExMachina Documentation](https://hexdocs.pm/ex_machina/)
- [Mox Documentation](https://hexdocs.pm/mox/)
- [Bypass Documentation](https://hexdocs.pm/bypass/)
