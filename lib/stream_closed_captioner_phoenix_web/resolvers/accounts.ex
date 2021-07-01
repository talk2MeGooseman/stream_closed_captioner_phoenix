defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.Accounts do
  def get_user(_parent, %{id: id}, _resolution) do
    case StreamClosedCaptionerPhoenix.Accounts.get_user!(id) do
      nil ->
        {:error, "User ID #{id} not found"}

      user ->
        {:ok, user}
    end
  end

  def get_me(_parent, _params, %{
        context: %{current_user: current_user}
      }) do
    case StreamClosedCaptionerPhoenix.Accounts.get_user!(current_user.id) do
      nil ->
        {:error, "Access Denied, no current user set"}

      user ->
        {:ok, user}
    end
  end

  def get_me(_parent, _args, _resolution) do
    {:error, "Access denied, missing current user"}
  end
end
