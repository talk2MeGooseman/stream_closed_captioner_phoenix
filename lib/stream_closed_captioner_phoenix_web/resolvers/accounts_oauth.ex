defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.AccountsOauth do
  def get_channel_info(_, %{id: id}, %{
        context: %{decoded_token: decoded_token}
      }) do
    id = Map.get(decoded_token, "channel_id")

    # TODO: Cache the user query using cachex
    case StreamClosedCaptionerPhoenix.AccountsOauth.get_user_for_provider("twitch", id) do
      nil ->
        {:error, "Channel #{id} not found"}

      user ->
        {:ok, user}
    end
  end

  def get_channel_info(_parent, _args, _resolution) do
    {:error,
     "Access denied, missing or invalid token. Please try again with correct credentials."}
  end
end
