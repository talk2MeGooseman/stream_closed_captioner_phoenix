defmodule StreamClosedCaptionerPhoenix.BitsTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenix.DataCase, async: false
  import StreamClosedCaptionerPhoenix.AuditHelpers

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Cache
  alias StreamClosedCaptionerPhoenix.Repo

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

    test "activate_translations_for/1 return an :insufficient_balance error if user doesnt have large enough bits balance" do
      user = insert(:user, bits_balance: build(:bits_balance, balance: 0, user: nil))

      result =
        capture_audit_events(fn ->
          Bits.activate_translations_for(user)
        end)

      assert {:error, :bits_balance_check, _, _} = result
      assert_audit_event("bits.translation_activation_failed")
    end

    test "activate_translations_for/1 emits audit log when activation succeeds" do
      user = insert(:user, bits_balance: build(:bits_balance, balance: 500, user: nil))

      result =
        capture_audit_events(fn ->
          Bits.activate_translations_for(user)
        end)

      assert {:ok, _} = result
      assert_audit_event("bits.translation_activated")
    end

    test "activate_translations_for/1 return :ok if user has minimum balance" do
      parent = self()
      created_user = insert(:user, bits_balance: build(:bits_balance, balance: 500, user: nil))

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

      results = [Task.await(task1), Task.await(task2)]
      assert Enum.any?(results, &match?({:ok, _}, &1)),
        "Expected one task to succeed"
      assert Enum.any?(results, &match?({:error, :bits_balance_check, :insufficient_balance, _}, &1)),
        "Expected one task to fail with :insufficient_balance"
      assert Bits.get_bits_balance!(user).balance == 0
    end

    test "list_users_bits_balance_debits/1 returns all bits_balance_debits for a user" do
      bits_balance_debit = insert(:bits_balance_debit)

      assert Enum.map(Bits.list_users_bits_balance_debits(bits_balance_debit.user), & &1.id) ==
               [bits_balance_debit.id]
    end

    test "list_bits_balance_debits/0 returns all bits_balance_debits" do
      bits_balance_debit = insert(:bits_balance_debit)
      assert Enum.map(Bits.list_bits_balance_debits(), & &1.id) == [bits_balance_debit.id]
    end

    test "get_bits_balance_debit!/1 returns the bits_balance_debit with given id" do
      bits_balance_debit = insert(:bits_balance_debit)

      assert Bits.get_bits_balance_debit!(bits_balance_debit.id).id ==
               bits_balance_debit.id
    end

    test "get_users_bits_balance_debit!/1 returns the bits_balance_debit for given user and debit id" do
      bits_balance_debit = insert(:bits_balance_debit)

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
      bits_balance_debit = insert(:bits_balance_debit)
      assert Bits.get_user_active_debit(bits_balance_debit.user_id)
    end

    test "get_user_active_debit/1 returns no record if debit is older than 24 hours" do
      created_at = Timex.today() |> Timex.shift(days: -3) |> Timex.to_naive_datetime()

      bits_balance_debit = insert(:bits_balance_debit, created_at: created_at)

      refute Bits.get_user_active_debit(bits_balance_debit.user_id)
    end

    # --- 24h boundary tests (issue #289) ---
    #
    # We update `created_at` via raw SQL using `NOW() AT TIME ZONE 'UTC'` so that the fixture
    # timestamps match the UTC-normalized reference frame used by the query's
    # `(NOW() AT TIME ZONE 'UTC') - INTERVAL '24 hours'` expression. This avoids
    # drift on non-UTC database sessions.

    test "get_user_active_debit/1 returns a debit created 23h 59m ago (just inside the 24h window)" do
      bits_balance_debit = insert(:bits_balance_debit)

      Repo.query!(
        "UPDATE bits_balance_debits SET created_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '23 hours 59 minutes' WHERE id = $1",
        [bits_balance_debit.id]
      )

      assert Bits.get_user_active_debit(bits_balance_debit.user_id)
    end

    test "get_user_active_debit/1 does not return a debit created 24h 1m ago (just outside the 24h window)" do
      # so a debit at 24h+1m ago could still be returned. This exact DB-native interval
      # comparison closes that gap.
      bits_balance_debit = insert(:bits_balance_debit)

      Repo.query!(
        "UPDATE bits_balance_debits SET created_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '24 hours 1 minute' WHERE id = $1",
        [bits_balance_debit.id]
      )

      refute Bits.get_user_active_debit(bits_balance_debit.user_id)
    end

    test "get_user_active_debit/1 does not return a debit created 25h ago (well outside the 24h window)" do
      bits_balance_debit = insert(:bits_balance_debit)

      Repo.query!(
        "UPDATE bits_balance_debits SET created_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '25 hours' WHERE id = $1",
        [bits_balance_debit.id]
      )

      refute Bits.get_user_active_debit(bits_balance_debit.user_id)
    end

    # Boundary note — exactly 24h ago:
    # The query uses `>=`, so a record created at precisely NOW() - 24h is included.
    # Testing this microsecond edge is inherently racy; the three tests above (23h59m,
    # 24h+1m, 25h) provide sufficient coverage of the boundary on both sides.
  end

  describe "bits_balances" do
    alias StreamClosedCaptionerPhoenix.Bits.BitsBalance

    @valid_attrs %{balance: 42}
    @update_attrs %{balance: 43}
    @invalid_attrs %{balance: nil, user_id: 100}

    test "list_bits_balances/0 returns all bits_balances" do
      bits_balance = insert(:bits_balance)
      assert Enum.map(Bits.list_bits_balances(), & &1.id) == [bits_balance.id]
    end

    test "get_bits_balance!/1 returns the bits_balance with given id" do
      bits_balance = insert(:bits_balance)
      assert Bits.get_bits_balance!(bits_balance.id).id == bits_balance.id
    end

    test "get_bits_balance!/1 returns the bits_balance with given user" do
      bits_balance = insert(:bits_balance)
      assert Bits.get_bits_balance!(bits_balance.user).id == bits_balance.id
    end

    test "get_bits_balance_by_user_id/1 returns the bits_balance with given user" do
      bits_balance = insert(:bits_balance, balance: 100)
      {:ok, result} = Bits.get_bits_balance_by_user_id(bits_balance.user_id)
      assert result.id == bits_balance.id
      assert result.balance == bits_balance.balance
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
      bits_balance = insert(:bits_balance)

      assert {:ok, %BitsBalance{} = bits_balance} =
               Bits.update_bits_balance(bits_balance, @update_attrs)

      assert bits_balance.balance == 43
    end

    test "update_bits_balance/2 with invalid data returns error changeset" do
      bits_balance = insert(:bits_balance)
      assert {:error, %Ecto.Changeset{}} = Bits.update_bits_balance(bits_balance, @invalid_attrs)
      assert bits_balance.id == Bits.get_bits_balance!(bits_balance.id).id
    end

    test "delete_bits_balance/1 deletes the bits_balance" do
      bits_balance = insert(:bits_balance)
      assert {:ok, %BitsBalance{}} = Bits.delete_bits_balance(bits_balance)
      assert_raise Ecto.NoResultsError, fn -> Bits.get_bits_balance!(bits_balance.id) end
    end

    test "change_bits_balance/1 returns a bits_balance changeset" do
      bits_balance = insert(:bits_balance)
      assert %Ecto.Changeset{} = Bits.change_bits_balance(bits_balance)
    end
  end

  describe "cache behavior" do
    alias StreamClosedCaptionerPhoenix.Bits.BitsBalance
    alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit

    setup do
      Cache.delete_all()
      :ok
    end

    test "user_active_debit_exists?/1 returns cached result after debit is deleted directly from DB" do
      user = insert(:user)
      debit = insert(:bits_balance_debit, user: user)

      # Prime the cache — result is true because debit exists
      assert Bits.user_active_debit_exists?(user.id) == true

      # Delete the debit directly, bypassing Bits.create_bits_balance_debit cache eviction
      Repo.delete!(debit)

      # Cache is still warm: result must still be true
      assert Bits.user_active_debit_exists?(user.id) == true
    end

    test "create_bits_balance_debit/2 evicts the debit cache so fresh data is returned" do
      user = insert(:user)

      # Prime the cache — no debit exists yet, result is false
      assert Bits.user_active_debit_exists?(user.id) == false

      # create_bits_balance_debit evicts the cache key
      {:ok, _debit} = Bits.create_bits_balance_debit(user, %{amount: 500})

      # Cache was evicted: fresh DB read shows true
      assert Bits.user_active_debit_exists?(user.id) == true
    end

    test "get_bits_balance_for_user/1 returns cached result after balance is updated directly in DB" do
      user = insert(:user)

      # Prime the cache — default balance is 0
      cached = Bits.get_bits_balance_for_user(user)
      assert %BitsBalance{} = cached
      original_balance = cached.balance

      # Update the balance directly in the DB, bypassing update_bits_balance cache eviction
      Repo.update!(Ecto.Changeset.change(user.bits_balance, balance: original_balance + 999))

      # Cache is still warm: balance must be unchanged
      result = Bits.get_bits_balance_for_user(user)
      assert result.balance == original_balance
    end

    test "update_bits_balance/2 evicts the balance cache so fresh data is returned" do
      user = insert(:user)

      # Prime the cache — default balance is 0
      assert %BitsBalance{balance: 0} = Bits.get_bits_balance_for_user(user)

      # update_bits_balance evicts the cache key
      {:ok, _updated} = Bits.update_bits_balance(user.bits_balance, %{balance: 100})

      # Cache was evicted: fresh DB read shows the new balance
      assert %BitsBalance{balance: 100} = Bits.get_bits_balance_for_user(user)
    end

    test "update_bits_balance/2 also evicts the debit cache (cross-invalidation)" do
      user = insert(:user)
      insert(:bits_balance_debit, user: user)

      # Prime the debit cache — debit exists, so true
      assert Bits.user_active_debit_exists?(user.id) == true

      # Delete the debit directly in DB so next fresh DB read returns false
      Bits.get_user_active_debit(user.id) |> Repo.delete!()

      # Cache is still warm: stale true
      assert Bits.user_active_debit_exists?(user.id) == true

      # update_bits_balance must also evict {BitsBalanceDebit, user_id}
      {:ok, _updated} = Bits.update_bits_balance(user.bits_balance, %{balance: 50})

      # Debit cache evicted: fresh DB read returns false
      assert Bits.user_active_debit_exists?(user.id) == false
    end

    test "create_bits_balance_debit/2 also evicts the balance cache (cross-invalidation)" do
      user = insert(:user)

      # Prime the balance cache
      cached_balance = Bits.get_bits_balance_for_user(user)
      assert %BitsBalance{} = cached_balance

      # Update balance directly in DB, bypassing cache eviction
      Repo.update!(Ecto.Changeset.change(user.bits_balance, balance: cached_balance.balance + 999))

      # Cache is still warm: returns stale value
      assert Bits.get_bits_balance_for_user(user).balance == cached_balance.balance

      # create_bits_balance_debit must also evict {BitsBalance, user_id}
      {:ok, _debit} = Bits.create_bits_balance_debit(user, %{amount: 500})

      # Balance cache evicted: fresh DB read shows the updated value
      assert Bits.get_bits_balance_for_user(user).balance == cached_balance.balance + 999
    end

    test "get_translation_snapshot/1 reads from DB regardless of stale cache" do
      user = insert(:user)

      # Prime the debit cache with false (no debit)
      assert Bits.user_active_debit_exists?(user.id) == false

      # Insert a debit directly in DB, bypassing cache eviction
      insert(:bits_balance_debit, user: user)

      # Cached value is stale: still says false
      assert Bits.user_active_debit_exists?(user.id) == false

      # Snapshot always reads DB — returns the real debit
      {balance, debit} = Bits.get_translation_snapshot(user.id)
      assert %BitsBalance{} = balance
      assert debit != nil
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
      bits_transaction = insert(:bits_transaction)
      assert Enum.map(Bits.list_bits_transactions(), & &1.id) == [bits_transaction.id]
    end

    test "get_bits_transaction!/1 returns the bits_transaction with given id" do
      bits_transaction = insert(:bits_transaction)

      assert Bits.get_bits_transaction!(bits_transaction.id).id ==
               bits_transaction.id
    end

    test "get_bits_transactions!/1 returns the bits_transactions for the given user" do
      bits_transaction = insert(:bits_transaction)

      assert Enum.map(Bits.get_bits_transactions!(bits_transaction.user), & &1.id) ==
               [bits_transaction.id]
    end

    test "get_bits_transaction_by/1 returns the bits_transactions for the given transaction_id" do
      bits_transaction = insert(:bits_transaction, transaction_id: "1234")

      assert Bits.get_bits_transaction_by(bits_transaction.transaction_id).id ==
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

      result =
        capture_audit_events(fn ->
          Bits.process_bits_transaction(user.uid, data)
        end)

      assert {:ok, _} = result
      assert_audit_event("bits.credit_applied")
    end

    test "process_bits_transaction returns error when user has no bits_balance" do
      user = insert(:user, provider: "twitch")
      StreamClosedCaptionerPhoenix.Repo.delete!(user.bits_balance)

      data = %{
        "data" => %{
          "transactionId" => "2",
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

      assert {:error, :retrieve_balance, :no_bits_balance, _} =
               Bits.process_bits_transaction(user.uid, data)
    end
  end


  # ===== BROADCAST TESTS (Critical Gaps) =====

  describe "broadcast behavior" do
    test "activate_translations_for/1 broadcasts translationActivated event after transaction commits" do
      user = insert(:user, bits_balance: build(:bits_balance, balance: 500, user: nil))

      # Subscribe to the captions channel before calling the function
      :ok = StreamClosedCaptionerPhoenixWeb.Endpoint.subscribe("captions:#{user.id}")

      # Call activate_translations_for
      {:ok, %{update_balance: updated_balance}} = Bits.activate_translations_for(user)

      # Assert that the broadcast was received with the correct event and payload
      assert_receive %Phoenix.Socket.Broadcast{
        event: "translationActivated",
        payload: %{enabled: true, balance: balance}
      }, 1000

      # Verify the balance in the broadcast payload matches the updated balance
      assert balance == updated_balance.balance
    end

    test "activate_translations_for/1 does NOT broadcast on failure (phantom broadcast prevention)" do
      # Create a user with NO bits_balance (force the transaction to fail)
      user = insert(:user)
      Repo.delete!(user.bits_balance)
      user = Repo.reload(user)

      # Subscribe to the captions channel
      :ok = StreamClosedCaptionerPhoenixWeb.Endpoint.subscribe("captions:#{user.id}")

      # Call activate_translations_for - should fail
      {:error, :bits_balance_check, :insufficient_balance, _} = Bits.activate_translations_for(user)

      # Assert NO broadcast is received (phantom broadcast prevention)
      refute_receive %Phoenix.Socket.Broadcast{event: "translationActivated"}, 500
    end

    test "process_bits_transaction/2 broadcasts transaction event after balance is credited" do
      user = insert(:user, provider: "twitch")

      # Subscribe to the captions channel before calling the function
      :ok = StreamClosedCaptionerPhoenixWeb.Endpoint.subscribe("captions:#{user.id}")

      data = %{
        "data" => %{
          "transactionId" => "broadcast-test-tx-#{user.id}-#{System.monotonic_time()}",
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

      # Get the initial balance before the transaction
      initial_balance = Bits.get_bits_balance!(user).balance

      # Call process_bits_transaction
      {:ok, %{add_to_balance: updated_balance}} = Bits.process_bits_transaction(user.uid, data)

      # Assert that the broadcast was received with the correct event and payload
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction",
        payload: %{balance: broadcast_balance}
      }, 1000

      # Verify the balance in the broadcast payload matches the updated balance
      assert broadcast_balance == updated_balance.balance
      assert broadcast_balance == initial_balance + 500
    end
  end

  # ===== PAGINATION & EDGE CASE TESTS (Medium Priority Gaps) =====

  describe "bits_transactions_and_debits_for_user" do
    test "bits_transactions_and_debits_for_user/3 returns paginated results with correct total count" do
      user = insert(:user)

      # Create 3 debits
      _debits = Enum.map(1..3, fn _i ->
        insert(:bits_balance_debit, user: user)
      end)

      # Create 2 transactions with unique transaction_ids
      _transactions = Enum.map(1..2, fn i ->
        insert(:bits_transaction, user: user, transaction_id: "tx-unique-#{user.id}-#{i}-#{System.monotonic_time()}")
      end)

      # Total should be 5 records
      result = Bits.bits_transactions_and_debits_for_user(user.id, 0, 10)

      assert result.total_records == 5
      assert length(result.records) == 5
    end

    test "bits_transactions_and_debits_for_user/3 respects offset and limit pagination" do
      user = insert(:user)

      # Create 5 debits
      _debits = Enum.map(1..5, fn _i ->
        insert(:bits_balance_debit, user: user)
      end)

      # Create 3 transactions with unique transaction_ids (using counter to ensure uniqueness)
      _transactions = Enum.map(1..3, fn i ->
        insert(:bits_transaction, user: user, transaction_id: "tx-offset-#{user.id}-#{i}")
      end)

      # Total: 8 records

      # Get first page: offset=0, limit=3
      page1 = Bits.bits_transactions_and_debits_for_user(user.id, 0, 3)

      # Get second page: offset=3, limit=3
      page2 = Bits.bits_transactions_and_debits_for_user(user.id, 3, 3)

      # Get third page: offset=6, limit=3
      page3 = Bits.bits_transactions_and_debits_for_user(user.id, 6, 3)

      # Assert total count
      assert page1.total_records == 8
      assert page2.total_records == 8
      assert page3.total_records == 8

      # Assert that pagination returns the correct number of records per page
      assert length(page1.records) == 3
      assert length(page2.records) == 3
      assert length(page3.records) == 2
    end

    test "bits_transactions_and_debits_for_user/3 returns empty result for user with no records" do
      user = insert(:user)

      result = Bits.bits_transactions_and_debits_for_user(user.id, 0, 10)

      assert result.total_records == 0
      assert result.records == []
    end
  end

  describe "get_translation_snapshot" do
    test "get_translation_snapshot/1 returns tuple with balance and debit when both exist" do
      user = insert(:user)
      _debit = insert(:bits_balance_debit, user: user)

      {balance, debit} = Bits.get_translation_snapshot(user.id)

      assert not is_nil(balance)
      assert not is_nil(debit)
      assert balance.user_id == user.id
      assert debit.user_id == user.id
    end

    test "get_translation_snapshot/1 returns {balance, nil} when user has no active debit" do
      user = insert(:user)
      # Don't insert any debit

      {balance, debit} = Bits.get_translation_snapshot(user.id)

      assert not is_nil(balance)
      assert is_nil(debit)
      assert balance.user_id == user.id
    end

    test "get_translation_snapshot/1 returns {nil, nil} when user has neither balance nor debit" do
      user = insert(:user, bits_balance: nil)
      # Don't insert any debit

      {balance, debit} = Bits.get_translation_snapshot(user.id)

      assert is_nil(balance)
      assert is_nil(debit)
    end

    test "get_translation_snapshot/1 returns {nil, debit} when user has active debit but no balance record" do
      user = insert(:user)
      debit = insert(:bits_balance_debit, user: user)
      Repo.delete!(user.bits_balance)

      {balance, active_debit} = Bits.get_translation_snapshot(user.id)

      assert is_nil(balance)
      assert not is_nil(active_debit)
      assert active_debit.id == debit.id
    end
  end

end
