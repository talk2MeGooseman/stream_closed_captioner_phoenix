# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| {domain 1} | {Name} | {example tasks} |
| {domain 2} | {Name} | {example tasks} |
| {domain 3} | {Name} | {example tasks} |
| Code review | {Name} | Review PRs, check quality, suggest improvements |
| Testing | {Name} | Write tests, find edge cases, verify fixes |
| Scope & priorities | {Name} | What to build next, trade-offs, decisions |
| Session logging | Scribe | Automatic — never needs routing |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze, assign `squad:{member}` label | Lead |
| `squad:{name}` | Pick up and complete | Named member |

### How Issue Assignment Works

1. `squad` label → Lead triages, assigns `squad:{member}`, comments triage notes.
2. `squad:{member}` label applied → member picks up next session.
3. Members reassign by swapping labels.
4. `squad` = untriaged inbox.

## Rules

1. **Eager by default** — spawn all agents who could usefully start, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn agent for simple lookups.
4. **Two agents could handle it** → pick the one whose domain is primary.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** Spawn tester to write test cases from requirements simultaneously.
7. **Issue-labeled work** → `squad:{member}` routes to that member. Lead handles `squad` triage.
