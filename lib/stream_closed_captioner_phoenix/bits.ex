defmodule StreamClosedCaptionerPhoenix.Bits do
  @seconds_in_hours 3600

  @moduledoc """
  The Bits context.
  """

  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
  alias StreamClosedCaptionerPhoenix.Repo

  def activate_translations_for(%User{} = user) do
    user = Repo.preload(user, :bits_balance)

    if user.bits_balance.balance >= 500 do
      Ecto.Multi.new()
      |> Ecto.Multi.run(:debit, fn _repo, _ ->
        create_bits_balance_debit(user, %{amount: 500})
      end)
      |> Ecto.Multi.run(:balance, fn _repo, %{debit: debit} ->
        new_balance = user.bits_balance.balance - debit.amount
        update_bits_balance(user.bits_balance, %{balance: new_balance})
      end)
      |> Repo.transaction()
    else
      {:insufficent_balance}
    end
  end

  @doc """
  Returns the list of bits_balance_debits.

  ## Examples

      iex> list_bits_balance_debits()
      [%BitsBalanceDebit{}, ...]

  """
  def list_bits_balance_debits do
    Repo.all(BitsBalanceDebit)
  end

  @doc """
  Returns the list of bits_balance_debits by user.

  ## Examples

      iex> list_users_bits_balance_debits()
      [%BitsBalanceDebit{}, ...]

  """
  def list_users_bits_balance_debits(%{id: id}) do
    BitsBalanceDebit |> where(user_id: ^id) |> Repo.all()
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
  def get_bits_balance_debit!(id), do: Repo.get!(BitsBalanceDebit, id)

  def get_users_bits_balance_debit!(%{id: user_id}, id),
    do: BitsBalanceDebit |> where(user_id: ^user_id) |> where(id: ^id) |> Repo.one!()

  @doc """
  Gets a get_user_active_debit for the user_id that has occurred in the past 24 hours.

  ## Examples

      iex> get_bits_balance_debit!(123)
      %BitsBalanceDebit{}

      iex> get_bits_balance_debit!(456)
      nil

  """
  def get_user_active_debit(user_id) do
    one_day_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(@seconds_in_hours * -24)

    BitsBalanceDebit
    |> where(user_id: ^user_id)
    |> where([u], u.created_at >= ^one_day_ago)
    |> Repo.one()
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
    Repo.all(BitsBalance)
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
  def get_bits_balance!(id) when is_integer(id), do: Repo.get!(BitsBalance, id)
  def get_bits_balance!(%User{} = user), do: Repo.get_by!(BitsBalance, user_id: user.id)

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
    Repo.all(BitsTransaction)
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
  def get_bits_transaction!(id) when is_integer(id), do: Repo.get!(BitsTransaction, id)

  def get_bits_transactions!(%User{} = user) do
    BitsBalanceDebit
    |> where(user_id: ^user.id)
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
  def get_bits_transaction_by(transaction_id) when is_binary(transaction_id),
    do: Repo.get_by(BitsTransaction, transaction_id: transaction_id)

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
    transaction_info = decoded_token |> List.first() |> Map.get("data")
    transaction_id = Map.get(transaction_info, "transactionId")
    amount = get_in(transaction_info, ["product", "cost", "amount"])

    Ecto.Multi.new()
    |> Ecto.Multi.run(:validate_transaction, validate_transaction(transaction_id))
    |> Ecto.Multi.run(:retrieve_channel_user, retrieve_user_by_uid(uid))
    |> Ecto.Multi.run(:retrieve_balance, &retrieve_balance/2)
    |> Ecto.Multi.run(:add_to_balance, add_to_balance(amount))
    |> Ecto.Multi.run(:save_transaction, save_transaction(transaction_info))
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
      bits_balance
      |> update_bits_balance(%{balance: bits_balance.balance + amount})
    end
  end

  defp save_transaction(transaction_info) do
    fn _repo, %{retrieve_channel_user: user} ->
      create_bits_transaction(user, %{
        amount: get_in(transaction_info, ["product", "cost", "amount"]),
        purchaser_uid: get_in(transaction_info, ["userId"]),
        sku: get_in(transaction_info, ["product", "sku"]),
        time: get_in(transaction_info, ["time"]),
        transaction_id: get_in(transaction_info, ["transactionId"])
      })
    end
  end
end
