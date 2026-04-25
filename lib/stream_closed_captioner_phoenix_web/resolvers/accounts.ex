defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.Accounts do
  alias StreamClosedCaptionerPhoenix.Accounts

  def get_user(_parent, %{id: id}, _resolution) do
    case Accounts.get_user!(id) do
      nil ->
        {:error, "User ID #{id} not found"}

      user ->
        {:ok, user}
    end
  end

  def get_me(_parent, _params, %{context: %{current_user: %Accounts.User{} = current_user}}) do
    {:ok, current_user}
  end

  def get_me(_parent, _args, _resolution) do
    {:error, "Access denied, missing current user"}
  end
end
