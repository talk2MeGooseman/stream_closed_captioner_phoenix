defmodule StreamClosedCaptionerPhoenix.BitsTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenix.DataCase

  alias StreamClosedCaptionerPhoenix.Bits
  import StreamClosedCaptionerPhoenix.BitsFixtures
  import StreamClosedCaptionerPhoenix.AccountsFixtures

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
      assert {:ok, %BitsBalanceDebit{} = bits_balance_debit} =
               Bits.create_bits_balance_debit(@valid_attrs)

      assert bits_balance_debit.amount == 42
      assert bits_balance_debit.user_id == 42
    end

    test "create_bits_balance_debit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_balance_debit(@invalid_attrs)
    end

    test "get_user_active_debit/1 return a record a debit has occurred in the past 24 hours" do
      bits_balance_debit = bits_balance_debit_fixture()

      assert Bits.get_user_active_debit(bits_balance_debit.user_id)
    end

    test "get_user_active_debit/1 returns no record if debit is older than 24 hours" do
      refute Bits.get_user_active_debit(2)
    end
  end

  describe "bits_balances" do
    alias StreamClosedCaptionerPhoenix.Bits.BitsBalance

    @valid_attrs %{total: 42}
    @update_attrs %{total: 43}
    @invalid_attrs %{total: nil, user_id: 100}

    test "list_bits_balances/0 returns all bits_balances" do
      bits_balance = bits_balance_fixture()
      assert Bits.list_bits_balances() == [bits_balance]
    end

    test "get_bits_balance!/1 returns the bits_balance with given id" do
      bits_balance = bits_balance_fixture()
      assert Bits.get_bits_balance!(bits_balance.id) == bits_balance
    end

    test "create_bits_balance/1 with valid data creates a bits_balance" do
      attrs = %{total: 42, user_id: user_fixture().id}
      assert {:ok, %BitsBalance{} = bits_balance} = Bits.create_bits_balance(attrs)
      assert bits_balance.total == 42
      assert bits_balance.user_id == attrs.user_id
    end

    test "create_bits_balance/1 doesnt create a new record if a user already as one" do
      attrs = %{total: 42, user_id: user_fixture().id}
      assert {:ok, %BitsBalance{}} = Bits.create_bits_balance(attrs)
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_balance(attrs)
    end

    test "create_bits_balance/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_balance(@invalid_attrs)
    end

    test "update_bits_balance/2 with valid data updates the bits_balance" do
      bits_balance = bits_balance_fixture()

      assert {:ok, %BitsBalance{} = bits_balance} =
               Bits.update_bits_balance(bits_balance, @update_attrs)

      assert bits_balance.total == 43
    end

    test "update_bits_balance/2 with invalid data returns error changeset" do
      bits_balance = bits_balance_fixture()
      assert {:error, %Ecto.Changeset{}} = Bits.update_bits_balance(bits_balance, @invalid_attrs)
      assert bits_balance == Bits.get_bits_balance!(bits_balance.id)
    end

    test "delete_bits_balance/1 deletes the bits_balance" do
      bits_balance = bits_balance_fixture()
      assert {:ok, %BitsBalance{}} = Bits.delete_bits_balance(bits_balance)
      assert_raise Ecto.NoResultsError, fn -> Bits.get_bits_balance!(bits_balance.id) end
    end

    test "change_bits_balance/1 returns a bits_balance changeset" do
      bits_balance = bits_balance_fixture()
      assert %Ecto.Changeset{} = Bits.change_bits_balance(bits_balance)
    end
  end

  describe "bits_transactions" do
    alias StreamClosedCaptionerPhoenix.Bits.BitsTransactions

    @valid_attrs %{
      amount: 42,
      display_name: "some display_name",
      purchaser_uid: "some purchaser_uid",
      sku: "some sku",
      time: ~N[2010-04-17 14:00:00],
      transaction_id: "some transaction_id",
      user_id: 42
    }
    # @update_attrs %{
    #   amount: 43,
    #   display_name: "some updated display_name",
    #   purchaser_uid: "some updated purchaser_uid",
    #   sku: "some updated sku",
    #   time: ~N[2011-05-18 15:01:01],
    #   transaction_id: "some updated transaction_id",
    #   user_id: 43
    # }
    # @invalid_attrs %{
    #   amount: nil,
    #   display_name: nil,
    #   purchaser_uid: nil,
    #   sku: nil,
    #   time: nil,
    #   transaction_id: nil,
    #   user_id: nil
    # }

    test "list_bits_transactions/0 returns all bits_transactions" do
      bits_transactions = bits_transactions_fixture()
      assert Bits.list_bits_transactions() == [bits_transactions]
    end

    test "get_bits_transactions!/1 returns the bits_transactions with given id" do
      bits_transactions = bits_transactions_fixture()
      assert Bits.get_bits_transactions!(bits_transactions.id) == bits_transactions
    end

    test "create_bits_transactions/1 with valid data creates a bits_transactions" do
      assert {:ok, %BitsTransactions{} = bits_transactions} =
               Bits.create_bits_transactions(@valid_attrs)

      assert bits_transactions.amount == 42
      assert bits_transactions.display_name == "some display_name"
      assert bits_transactions.purchaser_uid == "some purchaser_uid"
      assert bits_transactions.sku == "some sku"
      assert bits_transactions.time == ~N[2010-04-17 14:00:00]
      assert bits_transactions.transaction_id == "some transaction_id"
      assert bits_transactions.user_id == 42
    end

    test "create_bits_transactions/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_transactions(@invalid_attrs)
    end

    test "create_bits_transactions/1 with doesnt allow the same transction to be saved more than once" do
      assert {:ok, %BitsTransactions{}} =
               Bits.create_bits_transactions(@valid_attrs)

      assert {:error, %Ecto.Changeset{}} =
               Bits.create_bits_transactions(@valid_attrs)
    end

    test "delete_bits_transactions/1 deletes the bits_transactions" do
      bits_transactions = bits_transactions_fixture()
      assert {:ok, %BitsTransactions{}} = Bits.delete_bits_transactions(bits_transactions)

      assert_raise Ecto.NoResultsError, fn ->
        Bits.get_bits_transactions!(bits_transactions.id)
      end
    end

    test "change_bits_transactions/1 returns a bits_transactions changeset" do
      bits_transactions = bits_transactions_fixture()
      assert %Ecto.Changeset{} = Bits.change_bits_transactions(bits_transactions)
    end
  end
end
