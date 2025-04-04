defmodule StreamClosedCaptionerPhoenix.Bits do
  @moduledoc """
  The Bits context.
  """

  use Nebulex.Caching

  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebitQueries
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceQueries
  alias StreamClosedCaptionerPhoenix.Bits.BitsTransactionQueries
  alias StreamClosedCaptionerPhoenix.Cache
  alias StreamClosedCaptionerPhoenix.Repo

  def bits_transactions_and_debits_for_user(user_id, offset, limit) do
    records =
      BitsTransactionQueries.get_bits_transactions_and_debits_for_user(user_id)
      |> limit(^limit)
      |> offset(^offset)
      |> Repo.all()

    total_records =
      Repo.count(BitsTransactionQueries.get_bits_transactions_and_debits_for_user(user_id))

    %{records: records, total_records: total_records}
  end

  def activate_translations_for(%User{} = user) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:bits_balance_check, bits_balance_check(user))
    |> Ecto.Multi.run(:debit, fn _repo, _ ->
      create_bits_balance_debit(user, %{amount: 500})
    end)
    |> Ecto.Multi.run(:update_balance, &update_bits_balance_transaction/2)
    |> Ecto.Multi.run(:broadcast, broadcast_updated_bits_balance(user))
    |> Repo.transaction()
  end

  defp bits_balance_check(user) do
    fn _repo, _ ->
      bits_balance = get_bits_balance_for_user(user)

      if bits_balance.balance >= 500 do
        {:ok, bits_balance}
      else
        {:error, :insufficent_balance}
      end
    end
  end

  defp update_bits_balance_transaction(_repo, %{bits_balance_check: bits_balance, debit: debit}) do
    new_balance = bits_balance.balance - debit.amount
    update_bits_balance(bits_balance, %{balance: new_balance})
  end

  defp broadcast_updated_bits_balance(user) do
    fn _repo, %{update_balance: %{balance: balance}} ->
      StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
        "captions:#{user.id}",
        "translationActivated",
        %{enabled: true, balance: balance}
      )

      {:ok, true}
    end
  end

  @doc """
  Returns the list of bits_balance_debits.

  ## Examples

      iex> list_bits_balance_debits()
      [%BitsBalanceDebit{}, ...]

  """
  def list_bits_balance_debits do
    BitsBalanceDebitQueries.all()
    |> Repo.all()
  end

  @doc """
  Returns the list of bits_balance_debits by user.

  ## Examples

      iex> list_users_bits_balance_debits()
      [%BitsBalanceDebit{}, ...]

  """
  def list_users_bits_balance_debits(%{id: id}) do
    BitsBalanceDebitQueries.with_user_id(id)
    |> Repo.all()
  end

  @doc """
  Gets a single bits_balance_debit.

  Raises `Ecto.NoResultsError` if the Bits balance debit does not exist.

  ## Examples

      iex> get_bits_balance_debit!(123)
      %BitsBalanceDebit{}

      iex> get_bits_balance_debit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bits_balance_debit!(id), do: BitsBalanceDebitQueries.with_id(id) |> Repo.one!()

  def get_users_bits_balance_debit!(%{id: user_id}, id) do
    BitsBalanceDebitQueries.with_user_id(user_id)
    |> BitsBalanceDebitQueries.with_id(id)
    |> limit(1)
    |> Repo.one!()
  end

  @doc """
  Gets a get_user_active_debit for the user_id that has occurred in the past 24 hours.

  ## Examples

      iex> get_bits_balance_debit!(123)
      %BitsBalanceDebit{}

      iex> get_bits_balance_debit!(456)
      nil

  """
  def get_user_active_debit(user_id) do
    BitsBalanceDebitQueries.with_user_id(user_id)
    |> BitsBalanceDebitQueries.less_than_one_day_ago()
    |> limit(1)
    |> Repo.one()
  end

  @decorate cacheable(
              cache: Cache,
              key: {BitsBalanceDebit, user_id},
              opts: [ttl: :timer.minutes(5)]
            )
  def user_active_debit_exists?(user_id) do
    BitsBalanceDebitQueries.with_user_id(user_id)
    |> BitsBalanceDebitQueries.less_than_one_day_ago()
    |> Repo.exists?()
  end

  @doc """
  Creates a bits_balance_debit.

  ## Examples

      iex> create_bits_balance_debit(user, %{field: value})
      {:ok, %BitsBalanceDebit{}}

      iex> create_bits_balance_debit(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bits_balance_debit(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:bits_balance_debits)
    |> BitsBalanceDebit.changeset(attrs)
    |> Repo.insert()
  end

  alias StreamClosedCaptionerPhoenix.Bits.BitsBalance

  @doc """
  Returns the list of bits_balances.

  ## Examples

      iex> list_bits_balances()
      [%BitsBalance{}, ...]

  """
  def list_bits_balances do
    BitsBalanceQueries.all()
    |> Repo.all()
  end

  @doc """
  Gets a single bits_balance.

  Raises `Ecto.NoResultsError` if the Bits balance does not exist.

  ## Examples

      iex> get_bits_balance!(123)
      %BitsBalance{}

      iex> get_bits_balance!(456)
      ** (Ecto.NoResultsError)

      iex> get_bits_balance!(user)
      %BitsBalance{}

  """
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

  @decorate cacheable(
              cache: Cache,
              key: {BitsBalance, user.id},
              opts: [ttl: :timer.minutes(2)]
            )
  def get_bits_balance_for_user(%User{} = user) do
    BitsBalanceQueries.with_user_id(user.id)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Gets a single bits_balance by user_id.

  ## Examples

      iex> get_bits_balance_by_user_id(123)
      {:ok, %BitsBalance{}

      iex> get_bits_balance_by_user_id(456)
      {:error, nil}
  """
  def get_bits_balance_by_user_id(user_id) do
    BitsBalanceQueries.with_user_id(user_id)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> {:error, nil}
      bits_balance -> {:ok, bits_balance}
    end
  end

  @doc """
  Creates a bits_balance.

  ## Examples

      iex> create_bits_balance(user, %{})
      {:ok, %BitsBalance{}}

      iex> create_bits_balance(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bits_balance(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:bits_balance)
    |> BitsBalance.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bits_balance.

  ## Examples

      iex> update_bits_balance(bits_balance, %{field: new_value})
      {:ok, %BitsBalance{}}

      iex> update_bits_balance(bits_balance, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @decorate cache_evict(
              cache: Cache,
              key: {BitsBalance, bits_balance.user_id}
            )
  def update_bits_balance(%BitsBalance{} = bits_balance, attrs) do
    bits_balance
    |> BitsBalance.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bits_balance.

  ## Examples

      iex> delete_bits_balance(bits_balance)
      {:ok, %BitsBalance{}}

      iex> delete_bits_balance(bits_balance)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bits_balance(%BitsBalance{} = bits_balance) do
    Repo.delete(bits_balance)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bits_balance changes.

  ## Examples

      iex> change_bits_balance(bits_balance)
      %Ecto.Changeset{data: %BitsBalance{}}

  """
  def change_bits_balance(%BitsBalance{} = bits_balance, attrs \\ %{}) do
    BitsBalance.changeset(bits_balance, attrs)
  end

  alias StreamClosedCaptionerPhoenix.Bits.BitsTransaction

  @doc """
  Returns the list of bits_transactions.

  ## Examples

      iex> list_bits_transactions()
      [%BitsTransaction{}, ...]

  """
  def list_bits_transactions do
    BitsTransactionQueries.all()
    |> Repo.all()
  end

  @doc """
  Gets a single bits_transaction.

  Raises `Ecto.NoResultsError` if the Bits transactions does not exist.

  ## Examples

      iex> get_bits_transaction!(123)
      %BitsTransaction{}

      iex> get_bits_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bits_transaction!(id) when is_integer(id) do
    BitsTransactionQueries.with_id(id)
    |> limit(1)
    |> Repo.one!()
  end

  def get_bits_transactions!(%User{} = user) do
    BitsTransactionQueries.with_user_id(user.id)
    |> Repo.all()
  end

  @doc """
  Gets a single bits_transaction by its transaction_id.

  ## Examples

      iex> get_bits_transaction_by("123")
      %BitsTransaction{}

      iex> get_bits_transaction_by("456")
      nil

  """
  def get_bits_transaction_by(transaction_id) when is_binary(transaction_id) do
    BitsTransactionQueries.with_transaction_id(transaction_id)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Creates a bits_transaction.

  ## Examples

      iex> create_bits_transaction(user, %{field: value})
      {:ok, %BitsTransaction{}}

      iex> create_bits_transaction(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bits_transaction(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:bits_transactions)
    |> BitsTransaction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a bits_transaction.

  ## Examples

      iex> delete_bits_transaction(bits_transaction)
      {:ok, %BitsTransaction{}}

      iex> delete_bits_transaction(bits_transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bits_transaction(%BitsTransaction{} = bits_transaction) do
    Repo.delete(bits_transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bits_transaction changes.

  ## Examples

      iex> change_bits_transaction(bits_transaction)
      %Ecto.Changeset{data: %BitsTransaction{}}

  """
  def change_bits_transaction(%BitsTransaction{} = bits_transaction, attrs \\ %{}) do
    BitsTransaction.changeset(bits_transaction, attrs)
  end

  @doc """
  Procceses a transaction from Twitch that will credit a users bits balance account
  and record the transaction.

  ## Examples

      iex> process_bits_transaction(uid, transaction_data)
      %{:ok, transaction_multi_map}

      iex> process_bits_transaction(uid, transaction_data)
      %{:error, :validate_transaction, "Transaction 1 is already recorded.", %{}}
  """
  def process_bits_transaction(uid, decoded_token) do
    transaction_info = decoded_token |> Map.get("data")
    transaction_id = Map.get(transaction_info, "transactionId")
    amount = get_in(transaction_info, ["product", "cost", "amount"])

    Ecto.Multi.new()
    |> Ecto.Multi.run(:validate_transaction, validate_transaction(transaction_id))
    |> Ecto.Multi.run(:retrieve_channel_user, retrieve_user_by_uid(uid))
    |> Ecto.Multi.run(:retrieve_balance, &retrieve_balance/2)
    |> Ecto.Multi.run(:add_to_balance, add_to_balance(amount))
    |> Ecto.Multi.run(:save_transaction, save_transaction(transaction_info))
    |> Ecto.Multi.run(:publish_activity, &publish_activity/2)
    |> Repo.transaction()
  end

  defp validate_transaction(transaction_id) do
    fn _repo, _ ->
      case get_bits_transaction_by(transaction_id) do
        nil -> {:ok, transaction_id}
        _transaction -> {:error, "Transaction #{transaction_id} is already recorded."}
      end
    end
  end

  defp retrieve_user_by_uid(uid) do
    fn _repo, _ ->
      case StreamClosedCaptionerPhoenix.AccountsOauth.get_user_for_provider("twitch", uid) do
        nil ->
          {:error, "Channel #{uid} not found"}

        user ->
          {:ok, user}
      end
    end
  end

  defp retrieve_balance(_repo, %{retrieve_channel_user: user}) do
    user = Repo.preload(user, :bits_balance)
    {:ok, user.bits_balance}
  end

  defp add_to_balance(amount) do
    fn _repo, %{retrieve_balance: bits_balance} ->
      update_bits_balance(bits_balance, %{balance: bits_balance.balance + amount})
    end
  end

  defp save_transaction(transaction_info) do
    fn _repo, %{retrieve_channel_user: user} ->
      create_bits_transaction(user, %{
        amount: get_in(transaction_info, ["product", "cost", "amount"]),
        purchaser_uid: get_in(transaction_info, ["userId"]),
        sku: get_in(transaction_info, ["product", "sku"]),
        # get_in(transaction_info, ["time"]),
        time: Timex.now(),
        transaction_id: get_in(transaction_info, ["transactionId"])
      })
    end
  end

  defp publish_activity(_repo, %{retrieve_channel_user: user, add_to_balance: bits_balance}) do
    StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
      "captions:#{user.id}",
      "transaction",
      %{balance: bits_balance.balance}
    )

    {:ok, nil}
  end
end
