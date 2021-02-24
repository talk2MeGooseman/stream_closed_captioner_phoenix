defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.Accounts do

  def get_user(_parent, %{id: id}, _resolution) do
    case StreamClosedCaptionerPhoenix.Accounts.get_user!(id) do
      nil ->
        {:error, "User ID #{id} not found"}
      user ->
        {:ok, user}
    end
  end
end
