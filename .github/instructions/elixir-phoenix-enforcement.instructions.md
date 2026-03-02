---
description: "Use when: enforcing Elixir and Phoenix best practices, reviewing architecture boundaries, and hardening maintainability in Elixir/Phoenix files"
applyTo: "**/*.ex, **/*.exs, **/*.heex"
---

# Elixir Phoenix Enforcement

Apply these rules when creating, editing, or reviewing Elixir/Phoenix code.

## Enforced Standards

- Keep controllers, LiveViews, and channels thin; delegate business logic to context modules.
- Keep public context APIs small, explicit, and documented with `@doc` where behavior is non-obvious.
- Prefer pattern matching and guard clauses in function heads over nested branching.
- Return tagged tuples (`{:ok, value}` / `{:error, reason}`) for fallible operations.
- Use `with` for sequential failure-prone flows to avoid deeply nested `case` blocks.
- Validate external or user-provided input with changesets or explicit validation modules.
- Keep side effects isolated (Repo writes, HTTP calls, PubSub, Oban enqueueing) and easy to test.
- Use `Ecto.Multi` for multi-step database state changes that must succeed atomically.
- Avoid N+1 queries and over-fetching; preload intentionally and keep query logic in contexts/query modules.
- Add meaningful telemetry/logging at boundaries, never `IO.inspect` in production code.
- Preserve security defaults: authorize before data access and never trust client-controlled fields.

## Review Checklist

- Is business logic located in contexts/services rather than web layer modules?
- Are function names and module boundaries clear and domain-oriented?
- Are error paths explicit and consistently shaped?
- Are queries efficient and transaction boundaries correct?
- Are tests updated for success and failure paths?
- Are public APIs and complex decisions documented?

## Scope Guidance

- Prefer focused changes over broad rewrites.
- Reuse existing project conventions and module patterns before introducing new abstractions.
- If a pattern already exists in nearby files, follow it unless there is a clear defect.
