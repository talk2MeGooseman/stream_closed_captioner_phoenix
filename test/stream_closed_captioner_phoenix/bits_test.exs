defmodule StreamClosedCaptionerPhoenix.BitsTest do
  use StreamClosedCaptionerPhoenix.DataCase

  alias StreamClosedCaptionerPhoenix.Bits

  describe "bits_balance_debits" do
    alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit

    @valid_attrs %{amount: 42, user_id: 42}
    @update_attrs %{amount: 43, user_id: 43}
    @invalid_attrs %{amount: nil, user_id: nil}

    def bits_balance_debit_fixture(attrs \\ %{}) do
      {:ok, bits_balance_debit} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Bits.create_bits_balance_debit()

      bits_balance_debit
    end

    test "list_bits_balance_debits/0 returns all bits_balance_debits" do
      bits_balance_debit = bits_balance_debit_fixture()
      assert Bits.list_bits_balance_debits() == [bits_balance_debit]
    end

    test "get_bits_balance_debit!/1 returns the bits_balance_debit with given id" do
      bits_balance_debit = bits_balance_debit_fixture()
      assert Bits.get_bits_balance_debit!(bits_balance_debit.id) == bits_balance_debit
    end

    test "create_bits_balance_debit/1 with valid data creates a bits_balance_debit" do
      assert {:ok, %BitsBalanceDebit{} = bits_balance_debit} = Bits.create_bits_balance_debit(@valid_attrs)
      assert bits_balance_debit.amount == 42
      assert bits_balance_debit.user_id == 42
    end

    test "create_bits_balance_debit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_balance_debit(@invalid_attrs)
    end
  end
end
