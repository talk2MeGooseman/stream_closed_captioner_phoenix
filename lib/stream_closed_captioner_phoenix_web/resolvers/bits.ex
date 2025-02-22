defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.Bits do
  alias StreamClosedCaptionerPhoenix.{Accounts, Bits}

  def bits_balance(%Accounts.User{} = user, _args, _resolution) do
    bits_balance = Bits.get_bits_balance_for_user(user)

    case bits_balance do
      nil ->
        {:error, "Bits balance not found"}

      bits_balance ->
        {:ok, bits_balance}
    end
  end

  def process_bits_transaction(_parent, %{channel_id: channel_id}, %{
        context: %{decoded_token: decoded_token}
      }) do
    case Bits.process_bits_transaction(channel_id, decoded_token) do
      {:ok, _} -> {:ok, %{message: "Transaction Successful"}}
      {:error, _, message, _} -> {:error, %{message: message}}
    end
  end

  def process_bits_transaction(_parent, _args, _resolution) do
    {:error, "Access denied, missing or invalid token"}
  end
end
