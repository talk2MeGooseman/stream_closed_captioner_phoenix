---
description: 'GraphQL API development with Absinthe in Phoenix applications'
applyTo: '**/schema/**/*.ex, **/resolvers/**/*.ex, **/types/**/*.ex'
---

# GraphQL with Absinthe

## General Guidelines

- Define GraphQL types in `schema/types/` directory
- Keep resolvers focused in dedicated resolver modules
- Use dataloaders to batch database queries and prevent N+1 queries
- Define input objects for all mutations
- Use middleware for authentication, authorization, and error handling
- Return consistent error formats across all resolvers
- Document queries and mutations with descriptions
- Use subscriptions for real-time data updates
- Keep resolvers thin; delegate to context modules
- Use custom scalar types for domain-specific data

## Schema Organization

### Directory Structure
```
lib/my_app_web/
├── schema.ex              # Main schema file
├── schema/
│   ├── types/            # Type definitions
│   │   ├── user_types.ex
│   │   ├── caption_types.ex
│   │   └── scalar_types.ex
│   └── middleware/       # Custom middleware
│       ├── authenticate.ex
│       └── handle_errors.ex
└── resolvers/            # Resolver modules
    ├── user_resolver.ex
    ├── caption_resolver.ex
    └── subscription_resolver.ex
```

### Main Schema File
```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  # Import types
  import_types Absinthe.Type.Custom
  import_types MyAppWeb.Schema.Types.UserTypes
  import_types MyAppWeb.Schema.Types.CaptionTypes

  # Define query root
  query do
    import_fields :user_queries
    import_fields :caption_queries
  end

  # Define mutation root
  mutation do
    import_fields :user_mutations
    import_fields :caption_mutations
  end

  # Define subscription root
  subscription do
    import_fields :caption_subscriptions
  end

  # Add context for dataloaders
  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Repo, Dataloader.Ecto.new(Repo))

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
```

## Type Definitions

### Object Types
```elixir
defmodule MyAppWeb.Schema.Types.UserTypes do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc "A user of the application"
  object :user do
    field :id, non_null(:id)
    field :email, non_null(:string)
    field :name, :string
    field :inserted_at, non_null(:datetime)

    # Associations with dataloader
    field :posts, list_of(:post), resolve: dataloader(Repo)
    field :profile, :profile, resolve: dataloader(Repo)
  end

  # Extend query root
  object :user_queries do
    @desc "Get a user by ID"
    field :user, :user do
      arg :id, non_null(:id)
      resolve &MyAppWeb.Resolvers.UserResolver.get_user/3
    end

    @desc "List all users"
    field :users, list_of(:user) do
      arg :limit, :integer, default_value: 10
      arg :offset, :integer, default_value: 0
      resolve &MyAppWeb.Resolvers.UserResolver.list_users/3
    end
  end

  # Extend mutation root
  object :user_mutations do
    @desc "Create a new user"
    field :create_user, :user do
      arg :input, non_null(:create_user_input)
      resolve &MyAppWeb.Resolvers.UserResolver.create_user/3
    end
  end
end
```

### Input Objects
```elixir
@desc "Input for creating a user"
input_object :create_user_input do
  field :email, non_null(:string)
  field :name, :string
  field :password, non_null(:string)
end

@desc "Input for updating a user"
input_object :update_user_input do
  field :name, :string
  field :email, :string
end
```

### Custom Scalar Types
```elixir
defmodule MyAppWeb.Schema.Types.ScalarTypes do
  use Absinthe.Schema.Notation

  @desc "A datetime in ISO 8601 format"
  scalar :datetime do
    parse fn input ->
      case DateTime.from_iso8601(input.value) do
        {:ok, datetime, _} -> {:ok, datetime}
        _ -> :error
      end
    end

    serialize fn datetime ->
      DateTime.to_iso8601(datetime)
    end
  end
end
```

### Enums
```elixir
@desc "User role"
enum :user_role do
  value :admin, description: "Administrator with full access"
  value :user, description: "Regular user"
  value :guest, description: "Guest with limited access"
end
```

## Resolvers

### Basic Resolver Pattern
```elixir
defmodule MyAppWeb.Resolvers.UserResolver do
  alias MyApp.Accounts

  @doc """
  Get a single user by ID
  """
  def get_user(_parent, %{id: id}, _resolution) do
    case Accounts.get_user(id) do
      nil -> {:error, "User not found"}
      user -> {:ok, user}
    end
  end

  @doc """
  List users with pagination
  """
  def list_users(_parent, args, _resolution) do
    users = Accounts.list_users(args)
    {:ok, users}
  end

  @doc """
  Create a new user
  """
  def create_user(_parent, %{input: params}, _resolution) do
    case Accounts.create_user(params) do
      {:ok, user} -> {:ok, user}
      {:error, changeset} -> {:error, format_changeset_errors(changeset)}
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
```

### Resolver with Authentication
```elixir
def update_user(_parent, %{id: id, input: params}, %{context: %{current_user: current_user}}) do
  with {:ok, user} <- Accounts.get_user(id),
       :ok <- authorize(current_user, :update, user),
       {:ok, updated_user} <- Accounts.update_user(user, params) do
    {:ok, updated_user}
  else
    {:error, :not_found} -> {:error, "User not found"}
    {:error, :unauthorized} -> {:error, "Not authorized"}
    {:error, changeset} -> {:error, format_changeset_errors(changeset)}
  end
end

defp authorize(%{id: user_id}, :update, %{id: user_id}), do: :ok
defp authorize(%{role: :admin}, :update, _user), do: :ok
defp authorize(_user, _action, _resource), do: {:error, :unauthorized}
```

## Dataloader for N+1 Prevention

### Setup Dataloader
```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Repo, Dataloader.Ecto.new(Repo))

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
```

### Use Dataloader in Types
```elixir
object :user do
  field :id, non_null(:id)
  field :email, non_null(:string)

  # This will batch load all posts for multiple users
  field :posts, list_of(:post), resolve: dataloader(Repo)

  # Custom dataloader with filters
  field :published_posts, list_of(:post) do
    resolve dataloader(Repo, :posts, fn query, _parent, _args ->
      from p in query, where: p.published == true
    end)
  end
end
```

## Subscriptions

### Define Subscription
```elixir
defmodule MyAppWeb.Schema.Types.CaptionTypes do
  use Absinthe.Schema.Notation

  object :caption_subscriptions do
    @desc "Subscribe to new captions for a specific channel"
    field :new_caption, :caption do
      arg :channel_id, non_null(:string)

      config fn args, _resolution ->
        {:ok, topic: "captions:#{args.channel_id}"}
      end

      trigger :publish_caption, topic: fn caption ->
        "captions:#{caption.channel_id}"
      end
    end
  end
end
```

### Publish to Subscription
```elixir
defmodule MyAppWeb.Resolvers.CaptionResolver do
  def publish_caption(_parent, %{input: params}, _resolution) do
    case Captions.create_caption(params) do
      {:ok, caption} ->
        # Publish to subscribers
        Absinthe.Subscription.publish(
          MyAppWeb.Endpoint,
          caption,
          new_caption: "captions:#{caption.channel_id}"
        )
        {:ok, caption}

      {:error, changeset} ->
        {:error, format_errors(changeset)}
    end
  end
end
```

## Middleware

### Authentication Middleware
```elixir
defmodule MyAppWeb.Schema.Middleware.Authenticate do
  @behaviour Absinthe.Middleware

  def call(resolution, _opts) do
    case resolution.context do
      %{current_user: _user} ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "Unauthenticated"})
    end
  end
end
```

### Apply Middleware to Fields
```elixir
object :user_mutations do
  field :update_user, :user do
    arg :id, non_null(:id)
    arg :input, non_null(:update_user_input)

    middleware MyAppWeb.Schema.Middleware.Authenticate
    resolve &MyAppWeb.Resolvers.UserResolver.update_user/3
  end
end
```

### Global Middleware
```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  def middleware(middleware, field, object) do
    middleware
    |> apply_authentication(field, object)
    |> apply_error_handling(field, object)
  end

  defp apply_authentication(middleware, _field, %{identifier: :mutation}) do
    [MyAppWeb.Schema.Middleware.Authenticate | middleware]
  end
  defp apply_authentication(middleware, _field, _object), do: middleware

  defp apply_error_handling(middleware, _field, _object) do
    middleware ++ [MyAppWeb.Schema.Middleware.HandleErrors]
  end
end
```

## Error Handling

### Consistent Error Format
```elixir
defmodule MyAppWeb.Schema.Middleware.HandleErrors do
  @behaviour Absinthe.Middleware

  def call(%{errors: errors} = resolution, _opts) when length(errors) > 0 do
    formatted_errors =
      errors
      |> Enum.map(&format_error/1)

    %{resolution | errors: formatted_errors}
  end

  def call(resolution, _opts), do: resolution

  defp format_error(%Ecto.Changeset{} = changeset) do
    %{
      message: "Validation failed",
      details: format_changeset_errors(changeset)
    }
  end

  defp format_error(error) when is_binary(error) do
    %{message: error}
  end

  defp format_error(error), do: error
end
```

## Testing

### GraphQL Request Testing
```elixir
defmodule MyAppWeb.Schema.UserQueriesTest do
  use MyAppWeb.ConnCase
  import MyApp.Factory

  @user_query """
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      email
      name
    }
  }
  """

  test "get user by ID", %{conn: conn} do
    user = insert(:user)

    conn = post(conn, "/api/graphql", %{
      "query" => @user_query,
      "variables" => %{"id" => user.id}
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

### Subscription Testing
```elixir
test "subscribes to new captions", %{socket: socket} do
  ref = push_doc(socket, """
    subscription {
      newCaption(channelId: "#{@channel_id}") {
        id
        text
      }
    }
  """)

  assert_reply ref, :ok, %{subscriptionId: subscription_id}

  # Trigger caption creation
  {:ok, caption} = Captions.create_caption(%{channel_id: @channel_id, text: "Hello"})

  assert_push "subscription:data", %{
    result: %{data: %{"newCaption" => %{"id" => id, "text" => "Hello"}}}
  }
end
```

## Best Practices

- **Use Dataloaders**: Always use dataloaders for associations to prevent N+1 queries
- **Input Objects**: Define input objects for all mutations, never use raw arguments
- **Error Handling**: Return consistent error formats with meaningful messages
- **Authorization**: Use middleware for authentication/authorization checks
- **Pagination**: Implement pagination for list queries (cursor or offset-based)
- **Descriptions**: Document all types, fields, queries, and mutations
- **Thin Resolvers**: Keep resolvers thin; delegate to context modules
- **Testing**: Write comprehensive tests for queries, mutations, and subscriptions
- **Versioning**: Use deprecation notices for backwards compatibility
- **Performance**: Monitor query complexity and implement query depth limits

## Common Patterns

### Pagination with Relay Connections
```elixir
connection node_type: :user do
  field :total_count, non_null(:integer)

  edge do
    field :cursor, non_null(:string)
    field :node, non_null(:user)
  end
end
```

### Batch Loading with Custom Function
```elixir
field :stats, :user_stats do
  resolve fn user, _args, %{context: %{loader: loader}} ->
    loader
    |> Dataloader.load(Stats, :user_stats, user.id)
    |> on_load(fn loader ->
      {:ok, Dataloader.get(loader, Stats, :user_stats, user.id)}
    end)
  end
end
```

### Union Types
```elixir
union :search_result do
  types [:user, :post, :comment]

  resolve_type fn
    %User{}, _ -> :user
    %Post{}, _ -> :post
    %Comment{}, _ -> :comment
  end
end
```

## Resources

- [Absinthe Documentation](https://hexdocs.pm/absinthe/)
- [Dataloader Documentation](https://hexdocs.pm/dataloader/)
- [GraphQL Best Practices](https://graphql.org/learn/best-practices/)
