defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.Bits do
  alias StreamClosedCaptionerPhoenix.Bits

  def process_bits_transaction(_parent, %{channel_id: channel_id}, %{
        context: %{decoded_token: decoded_token}
      }) do
    if channel_id == decoded_token["channel_id"] do
      case Bits.process_bits_transaction(channel_id, decoded_token) do
        {:ok, _} -> {:ok, %{message: "Transaction Successful"}}
        {:error, _, message, _} -> {:error, %{message: message}}
      end
    else
      {:error, "Access denied"}
    end
  end

  def process_bits_transaction(_parent, _args, _resolution) do
    {:error, "Access denied, missing or invalid token"}
  end
end
