defmodule StreamClosedCaptionerPhoenix.Bits do
  @seconds_in_hours 3600

  @moduledoc """
  The Bits context.
  """

  import Ecto.Query, warn: false
  alias StreamClosedCaptionerPhoenix.Repo

  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit

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
  def list_users_bits_balance_debits(%{ id: id }) do
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

  def get_users_bits_balance_debit!(%{ id: user_id }, id), do: BitsBalanceDebit |> where(user_id: ^user_id) |> where(id: ^id) |> Repo.one!()

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

      iex> create_bits_balance_debit(%{field: value})
      {:ok, %BitsBalanceDebit{}}

      iex> create_bits_balance_debit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bits_balance_debit(attrs \\ %{}) do
    %BitsBalanceDebit{}
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

  """
  def get_bits_balance!(id), do: Repo.get!(BitsBalance, id)

  @doc """
  Creates a bits_balance.

  ## Examples

      iex> create_bits_balance(%{field: value})
      {:ok, %BitsBalance{}}

      iex> create_bits_balance(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bits_balance(attrs \\ %{}) do
    %BitsBalance{}
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

  alias StreamClosedCaptionerPhoenix.Bits.BitsTransactions

  @doc """
  Returns the list of bits_transactions.

  ## Examples

      iex> list_bits_transactions()
      [%BitsTransactions{}, ...]

  """
  def list_bits_transactions do
    Repo.all(BitsTransactions)
  end

  @doc """
  Gets a single bits_transactions.

  Raises `Ecto.NoResultsError` if the Bits transactions does not exist.

  ## Examples

      iex> get_bits_transactions!(123)
      %BitsTransactions{}

      iex> get_bits_transactions!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bits_transactions!(id), do: Repo.get!(BitsTransactions, id)

  @doc """
  Creates a bits_transactions.

  ## Examples

      iex> create_bits_transactions(%{field: value})
      {:ok, %BitsTransactions{}}

      iex> create_bits_transactions(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bits_transactions(attrs \\ %{}) do
    %BitsTransactions{}
    |> BitsTransactions.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a bits_transactions.

  ## Examples

      iex> delete_bits_transactions(bits_transactions)
      {:ok, %BitsTransactions{}}

      iex> delete_bits_transactions(bits_transactions)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bits_transactions(%BitsTransactions{} = bits_transactions) do
    Repo.delete(bits_transactions)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bits_transactions changes.

  ## Examples

      iex> change_bits_transactions(bits_transactions)
      %Ecto.Changeset{data: %BitsTransactions{}}

  """
  def change_bits_transactions(%BitsTransactions{} = bits_transactions, attrs \\ %{}) do
    BitsTransactions.changeset(bits_transactions, attrs)
  end
end
