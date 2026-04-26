# Tank: Bits Context — Test Gap Analysis

## Summary
Analysis of `bits_test.exs` against `bits.ex` implementation (issue #287 refactoring). Trinity is refactoring `bits.ex` into sub-contexts (`Bits.Balance`, `Bits.Debit`, `Bits.Transaction`) with `defdelegate` facade.

---

## Covered Functions (Have Tests)

### bits_balance_debits (Debit operations)
- ✅ `activate_translations_for/1` — 3 tests covering:
  - Insufficient balance error case
  - Audit log emission on success
  - Concurrent activation with race condition handling
- ✅ `list_users_bits_balance_debits/1` — tested
- ✅ `list_bits_balance_debits/0` — tested
- ✅ `get_bits_balance_debit!/1` — tested
- ✅ `get_users_bits_balance_debit!/2` — tested
- ✅ `create_bits_balance_debit/2` — 2 tests (valid & invalid attrs)
- ✅ `get_user_active_debit/1` — 2 tests (exists & >24h old)

### bits_balances (Balance operations)
- ✅ `list_bits_balances/0` — tested
- ✅ `get_bits_balance!/1` (by ID & by user) — 2 tests
- ✅ `get_bits_balance_by_user_id/1` — tested
- ✅ `create_bits_balance/1` — 3 tests (valid, duplicate, invalid)
- ✅ `update_bits_balance/2` — 2 tests (valid & invalid)
- ✅ `delete_bits_balance/1` — tested
- ✅ `change_bits_balance/1` — tested
- ✅ `get_bits_balance_for_user/1` — covered in cache tests
- ✅ `user_active_debit_exists?/1` — covered in cache tests

### bits_transactions (Transaction operations)
- ✅ `list_bits_transactions/0` — tested
- ✅ `get_bits_transaction!/1` — tested
- ✅ `get_bits_transactions!/1` — tested
- ✅ `get_bits_transaction_by/1` — tested
- ✅ `create_bits_transaction/2` — 2 tests (valid & duplicate prevention)
- ✅ `delete_bits_transaction/1` — tested
- ✅ `change_bits_transaction/1` — tested
- ✅ `process_bits_transaction/2` — 2 tests:
  - Success case with audit log verification
  - Error case (no bits_balance)

### Cache behavior
- ✅ `user_active_debit_exists?/1` — cache warm/stale tests
- ✅ `get_bits_balance_for_user/1` — cache warm/stale tests
- ✅ Cache eviction on `create_bits_balance_debit/2`
- ✅ Cache eviction on `update_bits_balance/2`
- ✅ Cross-invalidation (balance ↔ debit cache)
- ✅ `get_translation_snapshot/1` — DB bypass verification

---

## Uncovered or Partially Covered Functions

### 🔴 CRITICAL: Broadcast behavior gaps

#### `activate_translations_for/1` — **PARTIAL COVERAGE**
- ✅ Tests verify success/failure outcomes
- ✅ Tests verify audit logs
- ❌ **NO test verifies the broadcast happens OUTSIDE the transaction**
- ❌ **NO test verifies broadcast does NOT fire on rollback** (phantom broadcast prevention)
- ❌ **NO test verifies broadcast payload structure** (`enabled: true, balance: X`)
- **Impact**: Line 91-101 `broadcast_updated_bits_balance/2` runs inside `Ecto.Multi` but may broadcast even if transaction rolls back on later steps
- **Concern for refactoring**: If broadcast moves to sub-context, must verify it still runs post-commit (currently runs inside transaction boundary)

#### `process_bits_transaction/2` — **PARTIAL COVERAGE**
- ✅ Tests verify success/failure outcomes  
- ✅ Tests verify audit logs
- ❌ **NO test verifies broadcast in `publish_activity/2` (line 599-607)**
  - Does broadcast fire? With correct payload?
  - What happens if broadcast fails (error is swallowed)?
- ❌ **NO test verifies the broadcast happens AFTER transaction commit**
- **Concern for refactoring**: Line 599-607 contains `Endpoint.broadcast` but no test coverage of broadcast behavior

---

## Uncovered or Partially Covered Functions (continued)

### 🟡 MEDIUM PRIORITY: Missing functional tests

#### `bits_transactions_and_debits_for_user/3` — **NOT TESTED**
- **Location**: Line 21-32
- **Function signature**: `bits_transactions_and_debits_for_user(user_id, offset, limit)`
- **What it does**: Fetches paginated combined results of bits_transactions AND debits for a user
- **Gap**: No test coverage for:
  - Basic retrieval (returns both transactions and debits)
  - Offset/limit pagination
  - Total record count accuracy
  - Empty result set handling
  - Query ordering (are they ordered by created_at? by type?)
- **Why it matters**: This is a complex query combining two entities; easy to have bugs in pagination or ordering

#### `get_translation_snapshot/1` — **PARTIALLY COVERED**
- **Location**: Line 178-182
- **Current coverage** (line 311-327): One test verifies DB bypass when cache is stale
- **Gaps**:
  - No test verifies it returns a tuple `{balance, debit}` consistently
  - No test verifies atomicity (balance and debit represent same point-in-time)
  - No test verifies behavior when user has NO balance record
  - No test verifies behavior when user has NO debit record
  - No test verifies behavior when both are nil

---

## New Tests Recommended

### 1️⃣ Broadcast behavior: `activate_translations_for/1` post-transaction

**Function under test**: `activate_translations_for/1`  
**Scenario**: Broadcast must fire AFTER transaction commits, not inside it  
**Assertion approach**:
```elixir
test "activate_translations_for/1 broadcasts AFTER transaction commit (not on rollback)" do
  # Arrange
  user = insert(:user, bits_balance: build(:bits_balance, balance: 500, user: nil))
  
  # Act
  # Intercept broadcasts using Phoenix.ChannelTest.assert_broadcast or mock
  # or verify that broadcast fires and contains correct payload
  {:ok, result} = Bits.activate_translations_for(user)
  
  # Assert
  # Verify broadcast was called with:
  # - topic: "captions:#{user.id}"
  # - event: "translationActivated"
  # - payload: %{enabled: true, balance: X}
  # Verify it fires AFTER Repo.transaction returns (subscription-based test)
end
```

**Why**: The current code runs broadcast inside `Ecto.Multi.run(:broadcast, ...)` which means it runs during the transaction. If any later step fails, the broadcast fires but the transaction rolls back (phantom broadcast). Trinity's refactoring must preserve post-commit semantics.

---

### 2️⃣ Broadcast behavior: `process_bits_transaction/2` publication

**Function under test**: `process_bits_transaction/2`  
**Scenario**: Verify `publish_activity/2` broadcasts correct payload after balance update  
**Assertion approach**:
```elixir
test "process_bits_transaction/2 broadcasts balance update after transaction succeeds" do
  # Arrange
  user = insert(:user, provider: "twitch", bits_balance: build(:bits_balance, balance: 0, user: nil))
  data = %{
    "data" => %{
      "transactionId" => "tx-123",
      "userId" => user.uid,
      "time" => NaiveDateTime.utc_now(),
      "product" => %{
        "sku" => "translation500",
        "cost" => %{"amount" => 500}
      }
    }
  }
  
  # Act
  {:ok, result} = Bits.process_bits_transaction(user.uid, data)
  
  # Assert
  # Verify broadcast was called with:
  # - topic: "captions:#{user.id}"
  # - event: "transaction"
  # - payload: %{balance: 500} (new balance after credit)
end
```

**Why**: The `publish_activity/2` at line 599-607 broadcasts to the user's channel but has NO test coverage. This is critical for client-side balance UI updates.

---

### 3️⃣ Pagination & ordering: `bits_transactions_and_debits_for_user/3`

**Function under test**: `bits_transactions_and_debits_for_user/3`  
**Scenario A**: Pagination returns correct records and total count  
**Assertion approach**:
```elixir
test "bits_transactions_and_debits_for_user/3 returns paginated results with correct total count" do
  # Arrange
  user = insert(:user)
  
  # Create 5 debits and 3 transactions (8 total records)
  _debits = Enum.map(1..5, fn _ -> insert(:bits_balance_debit, user: user) end)
  _transactions = Enum.map(1..3, fn _ -> insert(:bits_transaction, user: user) end)
  
  # Act
  result = Bits.bits_transactions_and_debits_for_user(user.id, 0, 10)
  
  # Assert
  assert result.total_records == 8
  assert length(result.records) == 8  # All fit in one page
end
```

**Scenario B**: Offset and limit work correctly  
**Assertion approach**:
```elixir
test "bits_transactions_and_debits_for_user/3 respects offset and limit" do
  # Arrange
  user = insert(:user)
  Enum.map(1..10, fn i -> insert(:bits_balance_debit, user: user, created_at: Timex.shift(Timex.now(), days: -i)) end)
  
  # Act - first page
  page1 = Bits.bits_transactions_and_debits_for_user(user.id, 0, 3)
  
  # Act - second page
  page2 = Bits.bits_transactions_and_debits_for_user(user.id, 3, 3)
  
  # Assert
  assert length(page1.records) == 3
  assert length(page2.records) == 3
  assert page1.total_records == 10
  assert page2.total_records == 10
  # Verify no overlap between pages
  page1_ids = Enum.map(page1.records, & &1.id)
  page2_ids = Enum.map(page2.records, & &1.id)
  assert MapSet.intersection(MapSet.new(page1_ids), MapSet.new(page2_ids)) |> MapSet.size() == 0
end
```

**Why**: This function combines two separate record types; pagination bugs are common (off-by-one, incorrect total, overlapping pages).

---

### 4️⃣ Edge case: `get_translation_snapshot/1` with nil values

**Function under test**: `get_translation_snapshot/1`  
**Scenario A**: User has no bits_balance  
**Assertion approach**:
```elixir
test "get_translation_snapshot/1 returns {nil, debit} when user has no balance" do
  # Arrange
  user = insert(:user, bits_balance: nil)
  insert(:bits_balance_debit, user: user)
  
  # Act
  {balance, debit} = Bits.get_translation_snapshot(user.id)
  
  # Assert
  assert is_nil(balance)
  assert not is_nil(debit)
end
```

**Scenario B**: User has no active debit  
**Assertion approach**:
```elixir
test "get_translation_snapshot/1 returns {balance, nil} when user has no active debit" do
  # Arrange
  user = insert(:user)
  # Don't insert any debit
  
  # Act
  {balance, debit} = Bits.get_translation_snapshot(user.id)
  
  # Assert
  assert not is_nil(balance)
  assert is_nil(debit)
end
```

**Why**: The function assumes both records might exist, but GraphQL resolvers need to handle missing data gracefully. Current implementation (line 178-182) doesn't fail, but behavior with nil values isn't explicitly tested.

---

## Broadcast Fix Verification Strategy

### Current Problem
Lines 42, 91-101, and 599-607 contain Phoenix broadcast calls **inside Ecto.Multi transaction boundaries**. This means:
- ✅ Broadcast fires if transaction succeeds
- ❌ **Phantom broadcast**: Broadcast fires even if a LATER step in Multi fails and rolls back
- ❌ Semantics change post-refactoring if broadcast moves to sub-context

### Recommended Verification Approach

**Option 1: Acceptance test with subscription listener** (preferred)
```elixir
test "activate_translations_for/1 broadcast only fires after full transaction success" do
  # Subscribe to the topic
  {:ok, _view, _html} = live_connected_socket(user_id: user.id)
  
  # Trigger activation
  {:ok, _} = Bits.activate_translations_for(user)
  
  # Assert broadcast was received
  assert_receive {:phoenix, :broadcast, {:captions_#{user.id}, "translationActivated", %{enabled: true, balance: 0}}}
end
```

**Option 2: Mock/spy on Endpoint.broadcast**
```elixir
test "activate_translations_for/1 calls Endpoint.broadcast with correct args" do
  # Mock StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast
  with_mock StreamClosedCaptionerPhoenixWeb.Endpoint, 
    [broadcast: fn _topic, _event, _payload -> :ok end] do
    
    {:ok, _} = Bits.activate_translations_for(user)
    
    # Verify it was called
    assert_called(
      StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
        "captions:#{user.id}",
        "translationActivated",
        %{enabled: true, balance: _}
      )
    )
  end
end
```

**Option 3: Database verification (pragmatic)**
- If broadcast call fails/is mocked out, DB state should still be correct
- Separate test: verify broadcast side-effect doesn't prevent transaction from succeeding
```elixir
test "activate_translations_for/1 succeeds even if broadcast fails" do
  # Mock broadcast to fail/raise
  with_mocks([
    {StreamClosedCaptionerPhoenixWeb.Endpoint, [], [broadcast: fn _, _, _ -> raise "broadcast error" end]}
  ]) do
    # Transaction should still succeed and DB should be updated
    # (This currently would fail; test would catch the issue)
    {:ok, _} = Bits.activate_translations_for(user)
    assert Bits.get_bits_balance!(user).balance == 0  # Balance deducted
  end
end
```

### Key Assertions for Broadcasting
1. **Broadcast is called** after transaction commits
2. **Topic is correct**: `"captions:#{user.id}"`
3. **Event type is correct**: `"translationActivated"` or `"transaction"`
4. **Payload is correct**: 
   - For `activate_translations_for`: `%{enabled: true, balance: new_balance}`
   - For `process_bits_transaction`: `%{balance: updated_balance}`
5. **No phantom broadcast**: If transaction rolls back, no broadcast should fire
   - (Currently this is a BUG because broadcast is inside Multi)

---

## Summary Table

| Function | Covered? | Gaps | Priority |
|----------|----------|------|----------|
| `activate_translations_for/1` | Partial (outcome) | ❌ Broadcast behavior | 🔴 CRITICAL |
| `process_bits_transaction/2` | Partial (outcome) | ❌ Broadcast behavior | 🔴 CRITICAL |
| `bits_transactions_and_debits_for_user/3` | ❌ Not tested | ❌ Pagination, ordering | 🟡 MEDIUM |
| `get_translation_snapshot/1` | Partial (cache only) | ❌ Nil handling | 🟡 MEDIUM |
| All other functions | ✅ Covered | None | ✅ LOW |

---

## Notes for Trinity's Refactoring (Issue #287)

When refactoring into `Bits.Balance`, `Bits.Debit`, and `Bits.Transaction` sub-contexts:

1. **Broadcast must remain post-commit**: Current code has broadcast inside `Ecto.Multi`, which is incorrect. When refactoring, consider moving broadcasts OUTSIDE the transaction or using `Ecto.Multi.append_hooks/2` to run them after commit.

2. **Facade delegation must preserve semantics**: The `Bits` module's `defdelegate` should preserve all current behavior, especially around:
   - Transaction ordering in `activate_translations_for`
   - Cache eviction side-effects
   - Audit logging

3. **Tests must be migration-compatible**: Current tests must pass BOTH before AND after refactoring. New broadcast tests should catch issues early.

