defmodule StreamClosedCaptionerPhoenixWeb.Schema do
  use Absinthe.Schema

  alias StreamClosedCaptionerPhoenixWeb.Schema
  import_types(Schema.AccountsTypes)

  # Add import type here. Example
  # import_types(Schema.ProductTypes)

  @desc "Status of a channel"
  object :channel_status do
    field :languages, list_of(:string)
    field :balance, :integer
    field :activated, :boolean
    field :created_at, :string, description: "iso8601 datetime string"
  end

  query do
    # Add queries here. Example
    import_fields(:accounts_queries)

    @desc "Fetch the current status of a channel"
    field :channel_status, :channel_status do
      arg :id, non_null(:id)

      resolve &get_channel_status/3
    end
  end

  #  mutation do
  # Add mutations here. Example
  # import_fields(:create_product)
  #  end

  def get_channel_status(_parent, %{id: id}, _resolution) do
    case StreamClosedCaptionerPhoenix.Accounts.get_user_by_channel_id(id) do
      nil ->
        {:error, "Channel #{id} not found"}
      _user ->
        {:ok, %{
          languages: ["a", "b"],
          balance: 600,
          activated: false,
          created_at: "r3d124e2"
         }}
    end
  end
end
