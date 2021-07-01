defmodule StreamClosedCaptionerPhoenixWeb.Schema.AccountsTypes do
  use Absinthe.Schema.Notation

  alias StreamClosedCaptionerPhoenixWeb.Resolvers

  @desc "A user"
  object :user do
    field :uid, :id
    field :username, :string
  end

  @desc "Get information about a user"
  object :me do
    field :id, :id
    field :extension_installed, :boolean
  end

  object :accounts_queries do
    @desc "Get a users"
    field :user, :user do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Accounts.get_user/3)
    end

    @desc "Fetch the current users information"
    field :me, :me do
      resolve(&Resolvers.Accounts.get_me/3)
    end
  end
end
