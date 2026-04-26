# Work Routing

How decide who do what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| {domain 1} | {Name} | {example tasks} |
| {domain 2} | {Name} | {example tasks} |
| {domain 3} | {Name} | {example tasks} |
| Code review | {Name} | Review PRs, check quality, suggest improvements |
| Testing | {Name} | Write tests, find edge cases, verify fixes |
| Scope & priorities | {Name} | What build next, trade-offs, decisions |
| Session logging | Scribe | Automatic — never need routing |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze, assign `squad:{member}` label | Lead |
| `squad:{name}` | Pick up and complete | Named member |

### How Issue Assignment Works

1. `squad` label → Lead triage, assign `squad:{member}`, comment triage notes.
2. `squad:{member}` label applied → member grab next session.
3. Members reassign by swap labels.
4. `squad` = untriaged inbox.

## Rules

1. **Eager by default** — spawn all agents who could usefully start, include anticipatory downstream work.
2. **Scribe always run** after substantial work, always `mode: "background"`. Never block.
3. **Quick facts → coordinator answer direct.** No spawn agent for simple lookups.
4. **Two agents could handle it** → pick one whose domain primary.
5. **"Team, ..." → fan-out.** Spawn all relevant agents parallel as `mode: "background"`.
6. **Anticipate downstream work.** Spawn tester write test cases from requirements same time.
7. **Issue-labeled work** → `squad:{member}` route to that member. Lead handle `squad` triage.