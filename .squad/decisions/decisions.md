# Architectural Decisions

## ADR: GraphQL N+1 Query Optimization with Dataloader

**Status:** Accepted  
**Date:** 2026-04-25  
**Reviewers:** Morpheus (Lead)  
**Branch:** feat/fix-graphql-n-plus-one  
**Related commits:** a8e92b8, dbe3fd4

### Context

The GraphQL layer had N+1 query issues when resolving `bits_balance` for users in `channelInfo` queries. Each `channel_info` resolution triggered a separate SQL query to fetch the associated `bits_balance`, leading to performance degradation when fetching multiple channels or when the same user is queried multiple times in a single GraphQL operation.

Additionally, the `get_me` resolver was performing an unnecessary database re-fetch of the authenticated user on every request, even though the user was already loaded and present in the request context from the authentication pipeline.

### Decision

**Accepted Changes:**
1. Introduce Dataloader.Ecto to batch association loads for `bits_balance`
2. Replace custom `Resolvers.Bits.bits_balance/3` with `dataloader(Repo, :bits_balance)`
3. Optimize `get_me/3` to return `current_user` directly from context without DB re-fetch
4. Add comprehensive integration and unit tests for the new behavior

**Implementation Details:**
- Added `dataloader ~> 2.0` dependency
- Wired `Dataloader.Ecto.new(Repo)` as a source in `Schema.context/1`
- Registered `Absinthe.Middleware.Dataloader` explicitly in `plugins/0` before `defaults()`
- Used dataloader callback to preserve nil-error behavior for missing bits_balance

### Rationale

**Why Dataloader for a single `has_one` association?**

While this specific case involves a single `has_one :bits_balance` relationship, the decision to use Dataloader is architecturally sound for several reasons:

1. **Future-proofing:** The GraphQL schema will inevitably grow to include more user associations (stream_settings, eventsub_subscriptions, transcripts, etc.). Establishing the Dataloader pattern now avoids N+1 issues as the schema expands.

2. **Request-level batching:** Even for a single association, if the same user appears multiple times in a single GraphQL request (e.g., batch queries, nested resolvers), Dataloader batches those queries into a single SQL call.

3. **Consistency:** Using Dataloader establishes a consistent pattern for all association resolution, making the codebase more predictable and maintainable.

4. **Minimal overhead:** For simple cases like this one, Dataloader's overhead is negligible compared to the N+1 prevention benefits.

**Trade-offs considered:**
- **Simple preload alternative:** Could have used `Repo.preload` in the parent resolver. Rejected because it doesn't batch across multiple users in the same request and requires manual association management.
- **Custom batching:** Could have implemented request-level caching manually. Rejected because Dataloader is the standard, well-tested solution in the Absinthe ecosystem.

### Architectural Concerns Addressed

#### 1. Plugin Duplication Risk
**Q:** Does adding `Absinthe.Middleware.Dataloader` explicitly before `defaults()` register it twice?

**A:** No, this is safe. `Absinthe.Plugin.defaults()` returns a list `[Absinthe.Middleware.Batch, Absinthe.Middleware.Async]` as of Absinthe 1.7+. The Dataloader middleware is NOT included by default. Explicit registration is required and correct.

**Evidence:** Checked Absinthe 1.7.x source - defaults() only includes Batch and Async plugins.

#### 2. Auth Pipeline Safety
**Q:** Is removing the DB re-fetch in `get_me/3` safe? Could there be stale data risk?

**A:** Safe. The flow is:
1. `Context` plug runs early in request pipeline
2. Fetches user via `get_user_by_session_token(token)` using validated session token
3. Sets `current_user` in Absinthe context
4. GraphQL resolvers execute
5. `get_me/3` returns the already-loaded user

**Stale data risk:** Minimal. Session tokens are validated on every request. If user data changes between requests, the next request will fetch the updated user. Within a single request, the user data is consistent. The old code's DB re-fetch provided no additional safety—it just added latency.

**Pattern confirmation:** This is the standard approach in Phoenix/Absinthe apps. The auth pipeline loads the user once per request.

#### 3. Breaking Changes
**Q:** Any downstream callers that expected `Resolvers.Bits.bits_balance/3` to exist?

**A:** None found. Grep search shows:
- Function was only called from Schema field resolver (now replaced with dataloader)
- No other references in lib/ or test/
- Function removal is safe

**Related function still exists:** `Bits.get_bits_balance_for_user/1` in the Bits context is still used by `CaptionsPipeline.Translations.maybe_translate/3`, so the domain logic remains intact.

#### 4. Fault Tolerance
**Q:** How does Dataloader surface errors (DB down, association missing)?

**A:** Comprehensive error handling:
- **DB connection errors:** Dataloader will propagate Ecto exceptions to Absinthe's error handling, resulting in a GraphQL error response
- **Missing association (nil bits_balance):** Explicitly handled via callback function that returns `{:error, "Bits balance not found"}`, surfaced as a field-level GraphQL error
- **Test coverage:** Integration test `channel_info_test.exs` validates nil bits_balance error path

**Error surface area:** Improved. The dataloader callback provides explicit error handling for the nil case, which is more robust than the previous resolver pattern that relied on a separate context function.

#### 5. Test Coverage
New tests added:
- `test/stream_closed_captioner_phoenix_web/resolvers/accounts_test.exs` - Unit tests for `get_me/3` logic
- `test/stream_closed_captioner_phoenix_web/graphql/channel_info_test.exs` - Integration tests for Dataloader behavior, including nil error path

### Consequences

**Positive:**
- ✅ Eliminates N+1 queries for bits_balance association
- ✅ Reduces latency by avoiding unnecessary DB re-fetch in `get_me`
- ✅ Establishes standard Dataloader pattern for future association loading
- ✅ Comprehensive test coverage for new behavior

**Negative:**
- ⚠️ Adds new dependency (dataloader ~> 2.0)
- ⚠️ Requires understanding of Dataloader mechanics for future maintenance
- ⚠️ One more moving part in the GraphQL resolution pipeline

**Neutral:**
- Dataloader batch behavior is transparent to resolvers
- Error handling semantics unchanged from caller perspective
- Performance improvement is incremental for single-user queries, significant for multi-user scenarios

### Future Considerations

1. **Expand Dataloader usage:** As the schema grows, apply the same pattern to other associations (stream_settings, eventsub_subscriptions, etc.)
2. **Monitor Dataloader performance:** Add New Relic tracing for Dataloader batches to ensure expected batching behavior
3. **Consider per-user caching:** If bits_balance queries become a bottleneck even with batching, consider request-scoped caching
4. **Document pattern:** Add to project conventions documentation that all GraphQL associations should use Dataloader

### Notes

- The `bare_user_factory` commit (c546515) was completed just before this work, ensuring test factories work correctly with the association changes
- The old `Resolvers.Bits.bits_balance/3` function removal is clean - no orphaned references
- `Bits.get_bits_balance_for_user/1` remains in use by `CaptionsPipeline.Translations` - this is correct, as that code path needs direct context access, not GraphQL batching

### Approval

This architectural change is **APPROVED** for merge.

The N+1 fix is well-implemented, follows Absinthe/Phoenix best practices, and includes appropriate test coverage. The decision to introduce Dataloader is sound for long-term maintainability, even though the immediate use case is a single association.

---

## Fix: get_user/3 Resolver Dead Code

**Date:** 2025-01-20  
**Author:** Trinity (Backend Dev)  
**Status:** Completed

### Problem

The `get_user/3` resolver in `Resolvers.Accounts` called `Accounts.get_user!(id)` (bang variant) but then used `case` to check for `nil`. The bang variant raises `Ecto.NoResultsError` when no record is found — it never returns `nil`. The nil branch was unreachable dead code.

### Investigation

Checked `Accounts` context (line 98) — only `get_user!(id)` exists. No non-bang variant available that returns `nil` on not-found.

### Solution

Applied rescue pattern to catch the exception:

```elixir
def get_user(_parent, %{id: id}, _resolution) do
  {:ok, Accounts.get_user!(id)}
rescue
  Ecto.NoResultsError -> {:error, "User ID #{id} not found"}
end
```

### Rationale

- Minimal surgical change: only modified the broken function
- Preserves existing error message contract
- Follows Elixir convention: bang functions raise, rescue handles exceptions
- No need to add non-bang variant to Accounts context for single use case

---

*Last updated: 2026-04-25*
