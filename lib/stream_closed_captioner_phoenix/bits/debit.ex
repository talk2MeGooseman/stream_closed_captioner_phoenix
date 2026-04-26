defmodule StreamClosedCaptionerPhoenix.Bits.Debit do
  @moduledoc "CRUD for BitsBalanceDebit with Nebulex caching and translation activation."

  use Nebulex.Caching
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.AuditLog
  alias StreamClosedCaptionerPhoenix.Bits.Balance
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalance
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebitQueries
  # BitsBalanceQueries is used directly here (not via Balance) so that bits_balance_check/1
  # can issue a "FOR UPDATE" locking query through the transactional repo from Ecto.Multi.
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceQueries
  alias StreamClosedCaptionerPhoenix.Cache
  alias StreamClosedCaptionerPhoenix.Repo

  @cache_ttl :timer.minutes(2)

  def list_bits_balance_debits, do: BitsBalanceDebitQueries.all() |> Repo.all()

  def list_users_bits_balance_debits(%{id: id}),
    do: BitsBalanceDebitQueries.with_user_id(id) |> Repo.all()

  def get_bits_balance_debit!(id), do: BitsBalanceDebitQueries.with_id(id) |> Repo.one!()

  def get_users_bits_balance_debit!(%{id: user_id}, id) do
    BitsBalanceDebitQueries.with_user_id(user_id)
    |> BitsBalanceDebitQueries.with_id(id)
    |> limit(1)
    |> Repo.one!()
  end

  def get_user_active_debit(user_id) do
    BitsBalanceDebitQueries.with_user_id(user_id)
    |> BitsBalanceDebitQueries.less_than_one_day_ago()
    |> limit(1)
    |> Repo.one()
  end

  def get_translation_snapshot(user_id) do
    debit = get_user_active_debit(user_id)
    balance = Balance.get_bits_balance_uncached(user_id)
    {balance, debit}
  end

  @decorate cacheable(cache: Cache, key: {BitsBalanceDebit, user_id}, opts: [ttl: @cache_ttl])
  def user_active_debit_exists?(user_id) do
    BitsBalanceDebitQueries.with_user_id(user_id)
    |> BitsBalanceDebitQueries.less_than_one_day_ago()
    |> Repo.exists?()
  end

  @decorate cache_evict(cache: Cache, key: {BitsBalanceDebit, user.id})
  @decorate cache_evict(cache: Cache, key: {BitsBalance, user.id})
  def create_bits_balance_debit(user, attrs \\ %{}) do
    result =
      user
      |> Ecto.build_assoc(:bits_balance_debits)
      |> BitsBalanceDebit.changeset(attrs)
      |> Repo.insert()

    case result do
      {:error, _changeset} ->
        AuditLog.warn("bits.debit_create_failed", %{user_id: user.id})

      _ ->
        :ok
    end

    result
  end

  def activate_translations_for(%User{} = user) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:bits_balance_check, bits_balance_check(user))
      |> Ecto.Multi.run(:debit, fn _repo, _ -> create_bits_balance_debit(user, %{amount: 500}) end)
      |> Ecto.Multi.run(:update_balance, &update_bits_balance_transaction/2)
      |> Repo.transaction()

    case result do
      {:ok, %{debit: debit, update_balance: updated_balance}} ->
        AuditLog.info("bits.debit_created", %{user_id: user.id, debit_id: debit.id, amount: debit.amount})

        StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
          "captions:#{user.id}",
          "translationActivated",
          %{enabled: true, balance: updated_balance.balance}
        )

        AuditLog.info("bits.translation_activated", %{
          user_id: user.id,
          debit_id: debit.id,
          amount: debit.amount,
          balance: updated_balance.balance
        })

      {:error, :bits_balance_check, :insufficient_balance, _} ->
        AuditLog.warn("bits.translation_activation_failed", %{
          user_id: user.id,
          reason: :insufficient_balance
        })

      {:error, step, reason, _} ->
        AuditLog.warn("bits.translation_activation_failed", %{
          user_id: user.id,
          step: step,
          reason: AuditLog.format_reason(reason)
        })
    end

    result
  end

  defp bits_balance_check(user) do
    fn repo, _ ->
      bits_balance =
        BitsBalanceQueries.with_user_id(user.id)
        |> limit(1)
        |> repo.one(lock: "FOR UPDATE")

      if bits_balance && bits_balance.balance >= 500 do
        {:ok, bits_balance}
      else
        {:error, :insufficient_balance}
      end
    end
  end

  defp update_bits_balance_transaction(_repo, %{bits_balance_check: balance, debit: debit}),
    do: Balance.update_bits_balance(balance, %{balance: balance.balance - debit.amount})

end
