defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.Bits do
  alias StreamClosedCaptionerPhoenix.{Accounts, Repo}

  def bits_balance(%Accounts.User{} = user, _args, _resolution) do
    user = Repo.preload(user, :bits_balance)

    case user.bits_balance do
      nil ->
        {:error, "Bits balance not found"}

      bits_balance ->
        {:ok, bits_balance}
    end
  end
end
