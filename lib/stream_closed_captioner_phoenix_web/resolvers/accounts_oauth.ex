defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.AccountsOauth do
  def get_channel_info(_, %{id: id}, %{
        context: %{decoded_token: _decoded_token}
      }) do
    case StreamClosedCaptionerPhoenix.AccountsOauth.get_user_for_provider("twitch", id) do
      nil ->
        {:error, "Channel #{id} not found"}

      user ->
        {:ok, user}
    end
  end

  def get_channel_info(_parent, _args, _resolution) do
    {:error, "Access denied, missing or invalid token"}
  end
end
