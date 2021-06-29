defmodule StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebitQueries do
  import Ecto.Query, warn: false

  @seconds_in_hours 3600

  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
  alias StreamClosedCaptionerPhoenix.Repo

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
    one_day_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(@seconds_in_hours * -24)

    query
    |> where([bits_balance_debit], bits_balance_debit.created_at >= ^one_day_ago)
  end

  defp base do
    from(_ in BitsBalanceDebit, as: :bits_balance_debit)
  end
end
