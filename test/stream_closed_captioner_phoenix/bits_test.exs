defmodule StreamClosedCaptionerPhoenix.BitsTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenix.DataCase

  alias StreamClosedCaptionerPhoenix.{Bits, Repo}
  import StreamClosedCaptionerPhoenix.BitsFixtures
  import StreamClosedCaptionerPhoenix.AccountsFixtures

  describe "bits_balance_debits" do
    alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit

    @valid_attrs %{amount: 42}
    @update_attrs %{amount: 43}
    @invalid_attrs %{amount: nil}

    def bits_balance_debit_fixture(attrs \\ %{}) do
      {:ok, bits_balance_debit} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Bits.create_bits_balance_debit()

      bits_balance_debit
    end

    test "list_bits_balance_debits/0 returns all bits_balance_debits" do
      bits_balance_debit = insert(:bits_balance_debit)
      assert Bits.list_bits_balance_debits() |> Repo.preload(:user) == [bits_balance_debit]
    end

    test "get_bits_balance_debit!/1 returns the bits_balance_debit with given id" do
      bits_balance_debit = insert(:bits_balance_debit)
      assert Bits.get_bits_balance_debit!(bits_balance_debit.id) |> Repo.preload(:user) == bits_balance_debit
    end

    test "create_bits_balance_debit/1 with valid data creates a bits_balance_debit" do
      user = insert(:user)
      assert {:ok, %BitsBalanceDebit{} = bits_balance_debit} =
               Bits.create_bits_balance_debit(user, @valid_attrs)

      assert bits_balance_debit.amount == @valid_attrs.amount
      assert bits_balance_debit.user_id == user.id
    end

    test "create_bits_balance_debit/1 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_balance_debit(user, @invalid_attrs)
    end

    test "get_user_active_debit/1 return a record a debit has occurred in the past 24 hours" do
      bits_balance_debit = insert(:bits_balance_debit)
      assert Bits.get_user_active_debit(bits_balance_debit.user_id)
    end

    test "get_user_active_debit/1 returns no record if debit is older than 24 hours" do
      created_at = Timex.today |> Timex.shift(days: -3) |> Timex.to_naive_datetime()
      bits_balance_debit = insert(:bits_balance_debit, created_at: created_at)
      refute Bits.get_user_active_debit(bits_balance_debit.user_id)
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
    alias StreamClosedCaptionerPhoenix.Bits.BitsTransaction

    @valid_attrs %{
      amount: 42,
      display_name: "some display_name",
      purchaser_uid: "some purchaser_uid",
      sku: "some sku",
      time: ~N[2010-04-17 14:00:00],
      transaction_id: "some transaction_id",
    }

    test "list_bits_transactions/0 returns all bits_transactions" do
      bits_transaction = insert(:bits_transaction)
      assert Bits.list_bits_transactions() |> Repo.preload(:user) == [bits_transaction]
    end

    test "get_bits_transaction!/1 returns the bits_transaction with given id" do
      bits_transaction = insert(:bits_transaction)
      assert Bits.get_bits_transaction!(bits_transaction.id) |> Repo.preload(:user) == bits_transaction
    end

    test "create_bits_transaction/1 with valid data creates a bits_transaction" do
      user = insert(:user)
      assert {:ok, %BitsTransaction{} = bits_transaction} =
               Bits.create_bits_transaction(user, @valid_attrs)

      assert bits_transaction.amount == 42
      assert bits_transaction.display_name == "some display_name"
      assert bits_transaction.purchaser_uid == "some purchaser_uid"
      assert bits_transaction.sku == "some sku"
      assert bits_transaction.time == ~N[2010-04-17 14:00:00]
      assert bits_transaction.transaction_id == "some transaction_id"
      assert bits_transaction.user_id == user.id
    end

    test "create_bits_transaction/1 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_transaction(user, @invalid_attrs)
    end

    test "create_bits_transaction/1 doesnt allow the same transction to be saved more than once" do
      user = insert(:user)
      assert {:ok, %BitsTransaction{}} = Bits.create_bits_transaction(user, @valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_transaction(user, @valid_attrs)
    end

    test "delete_bits_transaction/1 deletes the bits_transaction" do
      bits_transaction = insert(:bits_transaction)
      assert {:ok, %BitsTransaction{}} = Bits.delete_bits_transaction(bits_transaction)

      assert_raise Ecto.NoResultsError, fn ->
        Bits.get_bits_transaction!(bits_transaction.id)
      end
    end

    test "change_bits_transaction1 returns a bits_transaction changeset" do
      bits_transaction = insert(:bits_transaction)
      assert %Ecto.Changeset{} = Bits.change_bits_transaction(bits_transaction)
    end
  end
end
