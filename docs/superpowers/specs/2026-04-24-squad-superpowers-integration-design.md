# Squad Superpowers Integration

**Date:** 2026-04-24
**Status:** Approved

## Problem

The squad agents have well-defined charters for their domains but no guidance on when to invoke superpowers skills. Skills like `test-driven-development`, `brainstorming`, and `requesting-code-review` exist to enforce discipline at key workflow gates, but agents have no mechanism to discover or apply them.

## Approach

Two-part integration:

1. **Shared contract** — `.squad/superpowers.md` lists all available skills, the hard gate rule, and invocation mechanics. All agents read it at session start alongside `.squad/decisions.md`.
2. **Agent-specific rules** — Each charter gets a `## Skills` section with domain-specific trigger conditions, plus targeted additions to `## How I Work` and `## Collaboration`.

## Shared Contract: `.squad/superpowers.md`

Contains:

- **Hard gate rule** — Check for skills before any action. Even 1% chance means invoke.
- **Invocation** — Use the `skill` tool (Copilot CLI).
- **Skills catalog** — All available skills with one-line descriptions and trigger conditions.
- **Priority rule** — Process skills (brainstorming, test-driven-development) before implementation skills.
- **Subagent note** — `using-superpowers` is skipped when dispatched as a subagent. All other skills still apply.

## Charter Updates

### Structure of changes per charter

Each charter receives:

1. A new `## Skills` section between `## How I Work` and `## Boundaries` listing skill triggers specific to that agent's domain.
2. A one-line addition to `## Collaboration`: `Read .squad/superpowers.md before starting.`
3. Where a skill is a hard gate for a core workflow step, a note is added to the relevant step in `## How I Work`.

### Agent Skill Mappings

| Agent | Skill | Trigger | Gate strength |
|-------|-------|---------|---------------|
| Morpheus | `brainstorming` | Before any architecture decision or new feature scoping | Hard |
| Morpheus | `writing-plans` | Before breaking down complex multi-step work for the team | Soft |
| Morpheus | `requesting-code-review` | After completing architecture/design review, before declaring done | Hard |
| Trinity | `test-driven-development` | Before writing any new feature code | Hard |
| Trinity | `brainstorming` | Before designing complex backend patterns (new pipeline stages, major context rewrites) | Soft |
| Neo | `test-driven-development` | Before writing any new LiveView or JS code | Hard |
| Neo | `brainstorming` | Before building new UI flows or components with significant user interaction | Soft |
| Tank | `test-driven-development` | Invoke at the start of every testing task — this IS Tank's primary workflow | Hard |
| Oracle | `requesting-code-review` | After completing security audit, before issuing merge/block decision | Hard |
| Scribe | `writing-plans` | When tasked with complex documentation or multi-file decision consolidation | Soft |
| Ralph | `find-skills` | When encountering an unfamiliar task type | Soft |

**Gate strength:**
- **Hard** — Must invoke before proceeding. Skipping is a workflow violation.
- **Soft** — Invoke when the situation clearly matches. Use judgment for edge cases.

## Files Changed

| File | Change |
|------|--------|
| `.squad/superpowers.md` | New file — shared skills contract |
| `.squad/agents/morpheus/charter.md` | Add `## Skills`, update `## Collaboration`, update `## How I Work` |
| `.squad/agents/trinity/charter.md` | Add `## Skills`, update `## Collaboration`, update `## How I Work` |
| `.squad/agents/neo/charter.md` | Add `## Skills`, update `## Collaboration`, update `## How I Work` |
| `.squad/agents/tank/charter.md` | Add `## Skills`, update `## Collaboration`, update `## How I Work` |
| `.squad/agents/oracle/charter.md` | Add `## Skills`, update `## Collaboration` |
| `.squad/agents/scribe/charter.md` | Add `## Skills`, update `## Collaboration` |
| `.squad/agents/ralph/charter.md` | Add `## Skills`, update `## Collaboration` |

## Success Criteria

- Every agent charter explicitly states which skills to invoke and when
- `.squad/superpowers.md` is a self-contained reference an agent can read cold
- Hard gate skills appear in the workflow steps where they apply, not just in a standalone section
- Agents reading `decisions.md` and `superpowers.md` at session start have everything they need to apply skills correctly
