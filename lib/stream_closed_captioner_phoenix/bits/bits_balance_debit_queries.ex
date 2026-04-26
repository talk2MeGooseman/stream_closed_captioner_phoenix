defmodule StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebitQueries do
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit

  def all(query \\ base()), do: query

  def with_user_id(query \\ base(), user_id) do
    query
    |> where([bits_balance_debit], bits_balance_debit.user_id == ^user_id)
  end

  def with_id(query \\ base(), id) do
    query
    |> where([bits_balance_debit], bits_balance_debit.id == ^id)
  end

  def less_than_one_day_ago(query \\ base()) do
    query
    |> where([bits_balance_debit], bits_balance_debit.created_at >= fragment("(NOW() AT TIME ZONE 'UTC') - INTERVAL '24 hours'"))
  end

  defp base do
    from(_ in BitsBalanceDebit, as: :bits_balance_debit)
  end
end
