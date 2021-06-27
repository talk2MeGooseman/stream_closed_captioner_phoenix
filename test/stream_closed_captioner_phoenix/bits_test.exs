defmodule StreamClosedCaptionerPhoenix.BitsTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  alias StreamClosedCaptionerPhoenix.{Bits, Accounts}

  describe "bits_balance_debits" do
    alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit

    @valid_attrs %{amount: 500}
    @update_attrs %{amount: 500}
    @invalid_attrs %{amount: nil}

    def bits_balance_debit_fixture(attrs \\ %{}) do
      {:ok, bits_balance_debit} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Bits.create_bits_balance_debit()

      bits_balance_debit
    end

    test "activate_translations_for/1 return an :insufficent_balance error if user doesnt have large enough bits balance" do
      user = insert(:user, bits_balance: build(:bits_balance, balance: 0))
      assert {:error, :bits_balance_check, _, _} = Bits.activate_translations_for(user)
    end

    test "activate_translations_for/1 return :ok if user has minimum balance" do
      parent = self()
      created_user = insert(:user, bits_balance: build(:bits_balance, balance: 500))

      user = Accounts.get_user!(created_user.id)

      task1 =
        Task.async(fn ->
          Ecto.Adapters.SQL.Sandbox.allow(Repo, parent, self())
          Bits.activate_translations_for(user)
        end)

      task2 =
        Task.async(fn ->
          Ecto.Adapters.SQL.Sandbox.allow(Repo, parent, self())
          Bits.activate_translations_for(user)
        end)

      assert {:ok, _} = Task.await(task1)
      assert {:error, :bits_balance_check, :insufficent_balance, _} = Task.await(task2)
      assert Bits.get_bits_balance!(user).balance == 0
    end

    test "list_users_bits_balance_debits/1 returns all bits_balance_debits for a user" do
      bits_balance_debit = insert(:bits_balance_debit, user: build(:user, bits_balance: nil))

      assert Enum.map(Bits.list_users_bits_balance_debits(bits_balance_debit.user), & &1.id) ==
               [bits_balance_debit.id]
    end

    test "list_bits_balance_debits/0 returns all bits_balance_debits" do
      bits_balance_debit = insert(:bits_balance_debit, user: build(:user, bits_balance: nil))
      assert Enum.map(Bits.list_bits_balance_debits(), & &1.id) == [bits_balance_debit.id]
    end

    test "get_bits_balance_debit!/1 returns the bits_balance_debit with given id" do
      bits_balance_debit = insert(:bits_balance_debit, user: build(:user, bits_balance: nil))

      assert Bits.get_bits_balance_debit!(bits_balance_debit.id).id ==
               bits_balance_debit.id
    end

    test "get_users_bits_balance_debit!/1 returns the bits_balance_debit for given user and debit id" do
      bits_balance_debit = insert(:bits_balance_debit, user: build(:user, bits_balance: nil))

      assert Bits.get_users_bits_balance_debit!(bits_balance_debit.user, bits_balance_debit.id).id ==
               bits_balance_debit.id
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
      bits_balance_debit = insert(:bits_balance_debit, user: build(:user, bits_balance: nil))
      assert Bits.get_user_active_debit(bits_balance_debit.user_id)
    end

    test "get_user_active_debit/1 returns no record if debit is older than 24 hours" do
      created_at = Timex.today() |> Timex.shift(days: -3) |> Timex.to_naive_datetime()

      bits_balance_debit =
        insert(:bits_balance_debit, created_at: created_at, user: build(:user, bits_balance: nil))

      refute Bits.get_user_active_debit(bits_balance_debit.user_id)
    end
  end

  describe "bits_balances" do
    alias StreamClosedCaptionerPhoenix.Bits.BitsBalance

    @valid_attrs %{balance: 42}
    @update_attrs %{balance: 43}
    @invalid_attrs %{balance: nil, user_id: 100}

    test "list_bits_balances/0 returns all bits_balances" do
      bits_balance = insert(:bits_balance, user: build(:user, bits_balance: nil))
      assert Enum.map(Bits.list_bits_balances(), & &1.id) == [bits_balance.id]
    end

    test "get_bits_balance!/1 returns the bits_balance with given id" do
      bits_balance = insert(:bits_balance, user: build(:user, bits_balance: nil))
      assert Bits.get_bits_balance!(bits_balance.id).id == bits_balance.id
    end

    test "create_bits_balance/1 with valid data creates a bits_balance" do
      user = insert(:user, bits_balance: nil)
      assert {:ok, %BitsBalance{} = bits_balance} = Bits.create_bits_balance(user)
      assert bits_balance.balance == 0
      assert bits_balance.user_id == user.id
    end

    test "create_bits_balance/1 doesnt create a new record if a user already as one" do
      user = insert(:user)
      assert %BitsBalance{} = user.bits_balance
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_balance(user)
    end

    test "create_bits_balance/1 with invalid data returns error changeset" do
      user = insert(:user, bits_balance: nil)
      assert {:error, %Ecto.Changeset{}} = Bits.create_bits_balance(user, @invalid_attrs)
    end

    test "update_bits_balance/2 with valid data updates the bits_balance" do
      bits_balance = insert(:bits_balance, user: build(:user, bits_balance: nil))

      assert {:ok, %BitsBalance{} = bits_balance} =
               Bits.update_bits_balance(bits_balance, @update_attrs)

      assert bits_balance.balance == 43
    end

    test "update_bits_balance/2 with invalid data returns error changeset" do
      bits_balance = insert(:bits_balance, user: build(:user, bits_balance: nil))
      assert {:error, %Ecto.Changeset{}} = Bits.update_bits_balance(bits_balance, @invalid_attrs)
      assert bits_balance.id == Bits.get_bits_balance!(bits_balance.id).id
    end

    test "delete_bits_balance/1 deletes the bits_balance" do
      bits_balance = insert(:bits_balance, user: build(:user, bits_balance: nil))
      assert {:ok, %BitsBalance{}} = Bits.delete_bits_balance(bits_balance)
      assert_raise Ecto.NoResultsError, fn -> Bits.get_bits_balance!(bits_balance.id) end
    end

    test "change_bits_balance/1 returns a bits_balance changeset" do
      bits_balance = insert(:bits_balance, user: build(:user, bits_balance: nil))
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
      transaction_id: "some transaction_id"
    }

    test "list_bits_transactions/0 returns all bits_transactions" do
      bits_transaction = insert(:bits_transaction, user: build(:user, bits_balance: nil))
      assert Enum.map(Bits.list_bits_transactions(), & &1.id) == [bits_transaction.id]
    end

    test "get_bits_transaction!/1 returns the bits_transaction with given id" do
      bits_transaction = insert(:bits_transaction, user: build(:user, bits_balance: nil))

      assert Bits.get_bits_transaction!(bits_transaction.id).id ==
               bits_transaction.id
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
      bits_transaction = insert(:bits_transaction, user: build(:user, bits_balance: nil))
      assert {:ok, %BitsTransaction{}} = Bits.delete_bits_transaction(bits_transaction)

      assert_raise Ecto.NoResultsError, fn ->
        Bits.get_bits_transaction!(bits_transaction.id)
      end
    end

    test "change_bits_transaction returns a bits_transaction changeset" do
      bits_transaction = insert(:bits_transaction, user: build(:user, bits_balance: nil))
      assert %Ecto.Changeset{} = Bits.change_bits_transaction(bits_transaction)
    end

    test "process_bits_transaction updates user channel bits balance if they exist" do
      user = insert(:user, provider: "twitch")

      data = %{
        "data" => %{
          "transactionId" => "1",
          "userId" => "1235",
          "time" => NaiveDateTime.utc_now(),
          "product" => %{
            "sku" => "translation500",
            "cost" => %{
              "amount" => 500
            }
          }
        }
      }

      assert {:ok, _} = Bits.process_bits_transaction(user.uid, data)
    end
  end
end
