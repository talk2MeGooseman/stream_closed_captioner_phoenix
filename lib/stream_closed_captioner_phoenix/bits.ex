defmodule StreamClosedCaptionerPhoenix.Bits do
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
  Gets a single bits_balance_debit.

  Raises `Ecto.NoResultsError` if the Bits balance debit does not exist.

  ## Examples

      iex> get_bits_balance_debit!(123)
      %BitsBalanceDebit{}

      iex> get_bits_balance_debit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bits_balance_debit!(id), do: Repo.get!(BitsBalanceDebit, id)

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

  @doc """
  Updates a bits_balance_debit.

  ## Examples

      iex> update_bits_balance_debit(bits_balance_debit, %{field: new_value})
      {:ok, %BitsBalanceDebit{}}

      iex> update_bits_balance_debit(bits_balance_debit, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bits_balance_debit(%BitsBalanceDebit{} = bits_balance_debit, attrs) do
    bits_balance_debit
    |> BitsBalanceDebit.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bits_balance_debit.

  ## Examples

      iex> delete_bits_balance_debit(bits_balance_debit)
      {:ok, %BitsBalanceDebit{}}

      iex> delete_bits_balance_debit(bits_balance_debit)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bits_balance_debit(%BitsBalanceDebit{} = bits_balance_debit) do
    Repo.delete(bits_balance_debit)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bits_balance_debit changes.

  ## Examples

      iex> change_bits_balance_debit(bits_balance_debit)
      %Ecto.Changeset{data: %BitsBalanceDebit{}}

  """
  def change_bits_balance_debit(%BitsBalanceDebit{} = bits_balance_debit, attrs \\ %{}) do
    BitsBalanceDebit.changeset(bits_balance_debit, attrs)
  end
end
