defmodule StreamClosedCaptionerPhoenix.Bits.BitsBalanceQueries do
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Bits.BitsBalance
  alias StreamClosedCaptionerPhoenix.Repo

  def all(query \\ base()), do: query

  def with_user_id(query \\ base(), user_id) do
    query
    |> where([bits_balance], bits_balance.user_id == ^user_id)
  end

  def with_id(query \\ base(), id) do
    query
    |> where([bits_balance], bits_balance.id == ^id)
  end

  defp base do
    from(_ in BitsBalance, as: :bits_balance)
  end
end
