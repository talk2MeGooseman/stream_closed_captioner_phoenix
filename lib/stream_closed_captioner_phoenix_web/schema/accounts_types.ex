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

    field :extension_installed, :boolean do
      resolve(&has_extension_installed?/3)
    end
  end

  object :accounts_queries do
    @desc "Fetch the current users information"
    field :me, :me do
      resolve(&Resolvers.Accounts.get_me/3)
    end
  end

  # Return a boolean indicating whether the user has the extension installed
  def has_extension_installed?(user, _args, _resolution) do
    status = StreamClosedCaptionerPhoenix.Accounts.user_has_extension_installed?(user)
    {:ok, status}
  end
end
