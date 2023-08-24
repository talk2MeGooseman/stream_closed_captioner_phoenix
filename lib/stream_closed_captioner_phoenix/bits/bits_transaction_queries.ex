defmodule StreamClosedCaptionerPhoenix.Bits.BitsTransactionQueries do
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
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

  def get_bits_transactions_and_debits_for_user(user_id) do
    transaction_query =
      from(t in BitsTransaction,
        where: t.user_id == ^user_id,
        select: %{
          amount: t.amount,
          time: t.time,
          id: t.transaction_id,
          purchaser_id: t.purchaser_uid,
          action: "purchase"
        }
      )

    union_all_query =
      from(d in BitsBalanceDebit,
        where: d.user_id == ^user_id,
        select: %{
          amount: d.amount,
          time: d.created_at,
          id: "",
          purchaser_id: "",
          action: "debit"
        },
        union_all: ^transaction_query
      )

    from(s in subquery(union_all_query), order_by: [desc: s.time])
  end
end
