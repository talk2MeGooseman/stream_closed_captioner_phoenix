defmodule StreamClosedCaptionerPhoenix.Bits.BitsTransactionQueries do
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Bits.BitsTransaction

  def all(query \\ base()), do: query

  @spec with_user_id(any, any) :: Ecto.Query.t()
  def with_user_id(query \\ base(), user_id) do
    query
    |> where([bits_transaction], bits_transaction.user_id == ^user_id)
  end

  @spec with_id(any, any) :: Ecto.Query.t()
  def with_id(query \\ base(), id) do
    query
    |> where([bits_transaction], bits_transaction.id == ^id)
  end

  @spec with_transaction_id(any, String.t()) :: Ecto.Query.t()
  def with_transaction_id(query \\ base(), transaction_id) do
    query
    |> where([bits_transaction], bits_transaction.transaction_id == ^transaction_id)
  end

  defp base do
    from(_ in BitsTransaction, as: :bits_transaction)
  end
end
