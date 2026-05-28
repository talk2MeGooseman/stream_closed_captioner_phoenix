# Design: Pin kaffy to ~> 0.10 (Unblock Build, Align Epic #248)

**Date:** 2026-05-14  
**Status:** Approved

## Problem

`kaffy 0.11.0` (already in `mix.exs`) requires `phoenix_html ~> 4.0`, but the app currently pins `phoenix_html ~> 3.0`. This blocks `mix deps.get`. The modernization epic (#248) plans the `phoenix_html 4.x` upgrade in Phase 3f (sub-issue #257) — several phases away. Kaffy is not mentioned anywhere in the epic.

## Approach

Pin kaffy back to `~> 0.10` to unblock the build immediately. Mark the future intent with an inline TODO comment and add kaffy ~> 0.11 as an explicit co-deliverable on epic sub-issue #257.

## Changes

### 1. `mix.exs`

```elixir
# Before:
{:kaffy, "0.11.0"},

# After:
# TODO: upgrade to ~> 0.11 when phoenix_html 4.x lands (Phase 3f, issue #257)
{:kaffy, "~> 0.10"},
```

### 2. Verify

```bash
mix deps.get
mix test
git commit -m "chore(deps): pin kaffy to ~> 0.10 until phoenix_html 4.x upgrade (phase 3f)"
```

### 3. GitHub issue #257

Add a note that kaffy `~> 0.11` must also be bumped as part of Phase 3f, since it is the primary driver of the phoenix_html 4.x requirement.

## Out of Scope

- No other dependency changes
- No phoenix_html or phoenix_live_view upgrade
- No changes to existing functionality
