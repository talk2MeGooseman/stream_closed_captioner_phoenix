defmodule StreamClosedCaptionerPhoenix.Bits.Balance do
  @moduledoc "CRUD for BitsBalance with Nebulex caching."

  use Nebulex.Caching
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalance
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceQueries
  alias StreamClosedCaptionerPhoenix.Cache
  alias StreamClosedCaptionerPhoenix.Repo

  @cache_ttl :timer.minutes(2)

  def list_bits_balances, do: BitsBalanceQueries.all() |> Repo.all()

  def get_bits_balance!(id) when is_integer(id) do
    BitsBalanceQueries.with_id(id)
    |> limit(1)
    |> Repo.one!()
  end

  def get_bits_balance!(%User{} = user) do
    BitsBalanceQueries.with_user_id(user.id)
    |> limit(1)
    |> Repo.one!()
  end

  @decorate cacheable(cache: Cache, key: {BitsBalance, user.id}, opts: [ttl: @cache_ttl])
  def get_bits_balance_for_user(%User{} = user) do
    BitsBalanceQueries.with_user_id(user.id)
    |> limit(1)
    |> Repo.one()
  end

  def get_bits_balance_by_user_id(user_id) do
    BitsBalanceQueries.with_user_id(user_id)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> {:error, nil}
      bits_balance -> {:ok, bits_balance}
    end
  end

  def create_bits_balance(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:bits_balance)
    |> BitsBalance.changeset(attrs)
    |> Repo.insert()
  end

  @decorate cache_evict(cache: Cache, key: {BitsBalance, bits_balance.user_id})
  @decorate cache_evict(cache: Cache, key: {BitsBalanceDebit, bits_balance.user_id})
  def update_bits_balance(%BitsBalance{} = bits_balance, attrs) do
    bits_balance
    |> BitsBalance.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_bits_balance(%BitsBalance{} = bits_balance), do: Repo.delete(bits_balance)

  def change_bits_balance(%BitsBalance{} = bits_balance, attrs \\ %{}) do
    BitsBalance.changeset(bits_balance, attrs)
  end

  @doc "Returns the balance record directly from DB, bypassing cache. Use when point-in-time consistency is required."
  def get_bits_balance_uncached(user_id) do
    BitsBalanceQueries.with_user_id(user_id) |> limit(1) |> Repo.one()
  end
end
