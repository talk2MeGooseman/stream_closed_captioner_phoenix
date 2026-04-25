# Squad Superpowers Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the superpowers skills system into every squad agent's workflow via a shared contract doc and agent-specific charter updates.

**Architecture:** Create `.squad/superpowers.md` as a shared skills reference (read at session start alongside `decisions.md`), then update each agent charter with a `## Skills` section and hard-gate callouts in `## How I Work`.

**Tech Stack:** Markdown file edits only — no code changes.

---

## File Map

| File | Action | What changes |
|------|--------|--------------|
| `.squad/superpowers.md` | Create | New shared skills contract |
| `.squad/agents/morpheus/charter.md` | Modify | Add `## Skills`, update `## How I Work`, update `## Collaboration` |
| `.squad/agents/trinity/charter.md` | Modify | Add `## Skills`, update `## How I Work`, update `## Collaboration` |
| `.squad/agents/neo/charter.md` | Modify | Add `## Skills`, update `## How I Work`, update `## Collaboration` |
| `.squad/agents/tank/charter.md` | Modify | Add `## Skills`, update `## How I Work`, update `## Collaboration` |
| `.squad/agents/oracle/charter.md` | Modify | Add `## Skills`, update `## Collaboration` |
| `.squad/agents/scribe/charter.md` | Modify | Add `## Skills`, update `## Work Style` |
| `.squad/agents/ralph/charter.md` | Modify | Add `## Skills`, update `## Work Style` |

---

## Task 1: Create `.squad/superpowers.md`

**Files:**
- Create: `.squad/superpowers.md`

- [ ] **Step 1: Create the file**

Create `.squad/superpowers.md` with this exact content:

```markdown
# Superpowers — Skills Contract

Read this at the start of every session alongside `.squad/decisions.md`.

## The Hard Gate Rule

Check for skills before any action. If there is even a **1% chance** a skill applies, invoke it. Do not start work, ask clarifying questions, or explore the codebase before checking.

## How to Invoke

Use the `skill` tool:

```
skill("skill-name")
```

The skill content loads and you follow it exactly.

## Subagent Note

When dispatched as a subagent with a specific task, skip `using-superpowers`. All other skills still apply — check for relevant skills before starting your task.

## Priority Rule

**Process skills before implementation skills:**

1. **Process first** — `brainstorming`, `test-driven-development` — establish *how* to approach the work
2. **Implementation second** — domain-specific skills — guide *how* to execute

## Skills Catalog

### Workflow Skills

| Skill | Purpose | Invoke when |
|-------|---------|-------------|
| `brainstorming` | Explores intent and design before building | Before any creative work — new features, components, behavior changes, architecture decisions |
| `test-driven-development` | Enforces TDD workflow | Before writing any implementation code |
| `writing-plans` | Creates bite-sized implementation plans from a spec | After brainstorming is complete, before implementation begins |
| `requesting-code-review` | Reviews completed work against plan and coding standards | After completing a logical chunk of work, before declaring done |
| `find-skills` | Discovers available skills for an unfamiliar task type | When you don't know which skill applies |

### Communication Skills

| Skill | Purpose | Invoke when |
|-------|---------|-------------|
| `caveman` | Ultra-compressed output (~75% fewer tokens) | When user requests brevity or token efficiency |
| `caveman-review` | Compressed code review comments | When reviewing PRs or diffs |
| `caveman-compress` | Compresses memory/preference files to caveman format | When compressing CLAUDE.md or similar files |

### Project Skills

| Skill | Purpose | Invoke when |
|-------|---------|-------------|
| `elixir-phoenix-best-practices` | Enforces Elixir/Phoenix coding standards | When writing or reviewing Elixir/Phoenix code |
| `refactor` | Surgical code refactoring without behavior change | When improving code quality without adding features |

## Agent-Specific Rules

Each agent's charter has a `## Skills` section with domain-specific trigger rules. Your charter is the authoritative source for which skills you invoke and when.
```

- [ ] **Step 2: Verify the file was created**

```bash
cat .squad/superpowers.md
```

Expected: Full content renders correctly with all three skill tables visible.

- [ ] **Step 3: Commit**

```bash
git add .squad/superpowers.md
git commit -m "squad: add superpowers skills contract

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: Update Morpheus Charter

**Files:**
- Modify: `.squad/agents/morpheus/charter.md`

- [ ] **Step 1: Add hard-gate callouts to `## How I Work`**

In `.squad/agents/morpheus/charter.md`, find the `## How I Work` section:

```markdown
## How I Work

- Read `.squad/decisions.md` before every task — team decisions are the architecture's memory
- Think in fault domains: what breaks, does it fail gracefully?
- Make trade-offs explicit rather than hiding them in implementation
- Write ADR-style decisions to `.squad/decisions/inbox/` for lasting choices
```

Replace with:

```markdown
## How I Work

- Invoke `brainstorming` skill before any architecture decision or feature scoping — **hard gate**
- Invoke `requesting-code-review` skill before declaring any review work done — **hard gate**
- Read `.squad/decisions.md` before every task — team decisions are the architecture's memory
- Think in fault domains: what breaks, does it fail gracefully?
- Make trade-offs explicit rather than hiding them in implementation
- Write ADR-style decisions to `.squad/decisions/inbox/` for lasting choices
```

- [ ] **Step 2: Add `## Skills` section after `## How I Work`**

Insert the following block between `## How I Work` and `## Boundaries`:

```markdown
## Skills

| Skill | Trigger | Gate |
|-------|---------|------|
| `brainstorming` | Before any architecture decision, feature scoping, or design work | **Hard** — must invoke before proceeding |
| `writing-plans` | Before breaking down complex multi-step work for the team | Soft — invoke when scope is multi-file or multi-session |
| `requesting-code-review` | After completing architecture/design review, before declaring done | **Hard** — must invoke before proceeding |

Use: `skill("brainstorming")`, `skill("writing-plans")`, `skill("requesting-code-review")`.

```

- [ ] **Step 3: Update `## Collaboration` to reference `superpowers.md`**

Find:

```markdown
Read `.squad/decisions.md` before starting.
```

Replace with:

```markdown
Read `.squad/decisions.md` before starting.
Read `.squad/superpowers.md` before starting.
```

- [ ] **Step 4: Verify**

```bash
grep -n "superpowers\|brainstorming\|requesting-code-review\|## Skills" .squad/agents/morpheus/charter.md
```

Expected: Lines for the `## Skills` heading, both hard-gate entries in How I Work, and the superpowers.md reference in Collaboration.

- [ ] **Step 5: Commit**

```bash
git add .squad/agents/morpheus/charter.md
git commit -m "squad(morpheus): wire superpowers skills into charter

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: Update Trinity Charter

**Files:**
- Modify: `.squad/agents/trinity/charter.md`

- [ ] **Step 1: Add hard-gate callout to `## How I Work`**

Find the `## How I Work` section opening:

```markdown
## How I Work

- Thin-controller pattern — business logic in contexts, not channels or resolvers
```

Replace with:

```markdown
## How I Work

- Invoke `test-driven-development` skill before writing any new feature code — **hard gate**
- Thin-controller pattern — business logic in contexts, not channels or resolvers
```

- [ ] **Step 2: Add `## Skills` section after `## How I Work`**

Insert between `## How I Work` and `## Boundaries`:

```markdown
## Skills

| Skill | Trigger | Gate |
|-------|---------|------|
| `test-driven-development` | Before writing any new feature code | **Hard** — must invoke before writing implementation |
| `brainstorming` | Before designing complex backend patterns (new pipeline stages, major context rewrites) | Soft — invoke when the design is non-obvious |

Use: `skill("test-driven-development")`, `skill("brainstorming")`.

```

- [ ] **Step 3: Update `## Collaboration`**

Find:

```markdown
Read `.squad/decisions.md` before starting.
```

Replace with:

```markdown
Read `.squad/decisions.md` before starting.
Read `.squad/superpowers.md` before starting.
```

- [ ] **Step 4: Verify**

```bash
grep -n "superpowers\|test-driven-development\|## Skills" .squad/agents/trinity/charter.md
```

Expected: Hard-gate line in How I Work, `## Skills` section, superpowers.md reference in Collaboration.

- [ ] **Step 5: Commit**

```bash
git add .squad/agents/trinity/charter.md
git commit -m "squad(trinity): wire superpowers skills into charter

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: Update Neo Charter

**Files:**
- Modify: `.squad/agents/neo/charter.md`

- [ ] **Step 1: Add hard-gate callout to `## How I Work`**

Find:

```markdown
## How I Work

- Use `phx-*` bindings for LiveView; avoid JS for things LiveView handles natively
```

Replace with:

```markdown
## How I Work

- Invoke `test-driven-development` skill before writing any new LiveView or JS code — **hard gate**
- Use `phx-*` bindings for LiveView; avoid JS for things LiveView handles natively
```

- [ ] **Step 2: Add `## Skills` section after `## How I Work`**

Insert between `## How I Work` and `## Boundaries`:

```markdown
## Skills

| Skill | Trigger | Gate |
|-------|---------|------|
| `test-driven-development` | Before writing any new LiveView or JS code | **Hard** — must invoke before writing implementation |
| `brainstorming` | Before building new UI flows or components with significant user interaction | Soft — invoke when the UX design is non-obvious |

Use: `skill("test-driven-development")`, `skill("brainstorming")`.

```

- [ ] **Step 3: Update `## Collaboration`**

Find:

```markdown
Read `.squad/decisions.md` before starting.
```

Replace with:

```markdown
Read `.squad/decisions.md` before starting.
Read `.squad/superpowers.md` before starting.
```

- [ ] **Step 4: Verify**

```bash
grep -n "superpowers\|test-driven-development\|## Skills" .squad/agents/neo/charter.md
```

Expected: Hard-gate line in How I Work, `## Skills` section, superpowers.md reference in Collaboration.

- [ ] **Step 5: Commit**

```bash
git add .squad/agents/neo/charter.md
git commit -m "squad(neo): wire superpowers skills into charter

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 5: Update Tank Charter

**Files:**
- Modify: `.squad/agents/tank/charter.md`

- [ ] **Step 1: Add hard-gate callout to `## How I Work`**

Find:

```markdown
## How I Work

- `DataCase` for context/schema logic, `ConnCase` for controllers/LiveView/GraphQL, `ChannelCase` for channels
```

Replace with:

```markdown
## How I Work

- Invoke `test-driven-development` skill at the start of every testing task — **hard gate**, this skill drives Tank's primary workflow
- `DataCase` for context/schema logic, `ConnCase` for controllers/LiveView/GraphQL, `ChannelCase` for channels
```

- [ ] **Step 2: Add `## Skills` section after `## How I Work`**

Insert between `## How I Work` and `## Boundaries`:

```markdown
## Skills

| Skill | Trigger | Gate |
|-------|---------|------|
| `test-driven-development` | At the start of every testing task | **Hard** — this skill IS Tank's primary workflow; always invoke first |

Use: `skill("test-driven-development")`.

```

- [ ] **Step 3: Update `## Collaboration`**

Find:

```markdown
Read `.squad/decisions.md` before starting.
```

Replace with:

```markdown
Read `.squad/decisions.md` before starting.
Read `.squad/superpowers.md` before starting.
```

- [ ] **Step 4: Verify**

```bash
grep -n "superpowers\|test-driven-development\|## Skills" .squad/agents/tank/charter.md
```

Expected: Hard-gate line in How I Work, `## Skills` section, superpowers.md reference in Collaboration.

- [ ] **Step 5: Commit**

```bash
git add .squad/agents/tank/charter.md
git commit -m "squad(tank): wire superpowers skills into charter

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 6: Update Oracle Charter

**Files:**
- Modify: `.squad/agents/oracle/charter.md`

- [ ] **Step 1: Add `## Skills` section after `## How I Work`**

Oracle's `## How I Work` ends before `## Merge-Blocking Criteria`. Insert between `## How I Work` and `## Merge-Blocking Criteria`:

```markdown
## Skills

| Skill | Trigger | Gate |
|-------|---------|------|
| `requesting-code-review` | After completing security audit, before issuing merge approval or block decision | **Hard** — must invoke before issuing final verdict |

Use: `skill("requesting-code-review")`.

```

- [ ] **Step 2: Update `## Collaboration`**

Find:

```markdown
Read `.squad/decisions.md` before starting.
```

Replace with:

```markdown
Read `.squad/decisions.md` before starting.
Read `.squad/superpowers.md` before starting.
```

- [ ] **Step 3: Verify**

```bash
grep -n "superpowers\|requesting-code-review\|## Skills" .squad/agents/oracle/charter.md
```

Expected: `## Skills` section with requesting-code-review, superpowers.md reference in Collaboration.

- [ ] **Step 4: Commit**

```bash
git add .squad/agents/oracle/charter.md
git commit -m "squad(oracle): wire superpowers skills into charter

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 7: Update Scribe Charter

**Files:**
- Modify: `.squad/agents/scribe/charter.md`

- [ ] **Step 1: Add `## Skills` section and update `## Work Style`**

Find the `## Work Style` section:

```markdown
## Work Style

- Read project context and decisions before starting
- Communicate clearly with team
- Follow established patterns and conventions
```

Replace with:

```markdown
## Work Style

- Read project context and decisions before starting
- Read `.squad/superpowers.md` before starting
- Communicate clearly with team
- Follow established patterns and conventions

## Skills

| Skill | Trigger | Gate |
|-------|---------|------|
| `writing-plans` | When tasked with complex documentation or multi-file decision consolidation | Soft — invoke when the scope spans multiple documents or sessions |

Use: `skill("writing-plans")`.
```

- [ ] **Step 2: Verify**

```bash
grep -n "superpowers\|writing-plans\|## Skills" .squad/agents/scribe/charter.md
```

Expected: superpowers.md reference in Work Style, `## Skills` section with writing-plans.

- [ ] **Step 3: Commit**

```bash
git add .squad/agents/scribe/charter.md
git commit -m "squad(scribe): wire superpowers skills into charter

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 8: Update Ralph Charter

**Files:**
- Modify: `.squad/agents/ralph/charter.md`

- [ ] **Step 1: Add `## Skills` section and update `## Work Style`**

Find the `## Work Style` section:

```markdown
## Work Style

- Read project context and decisions before starting
- Communicate clearly with team
- Follow established patterns and conventions
```

Replace with:

```markdown
## Work Style

- Read project context and decisions before starting
- Read `.squad/superpowers.md` before starting
- Communicate clearly with team
- Follow established patterns and conventions

## Skills

| Skill | Trigger | Gate |
|-------|---------|------|
| `find-skills` | When encountering an unfamiliar task type | Soft — invoke to discover which skill applies |

Use: `skill("find-skills")`.
```

- [ ] **Step 2: Verify**

```bash
grep -n "superpowers\|find-skills\|## Skills" .squad/agents/ralph/charter.md
```

Expected: superpowers.md reference in Work Style, `## Skills` section with find-skills.

- [ ] **Step 3: Commit**

```bash
git add .squad/agents/ralph/charter.md
git commit -m "squad(ralph): wire superpowers skills into charter

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Final Verification

- [ ] **Confirm all charters reference `superpowers.md`**

```bash
grep -l "superpowers" .squad/agents/*/charter.md
```

Expected: All 7 charter files listed.

- [ ] **Confirm all hard-gate skills appear in `## How I Work` sections**

```bash
grep -n "hard gate" .squad/agents/*/charter.md
```

Expected: morpheus (2 lines), trinity (1 line), neo (1 line), tank (1 line).

- [ ] **Confirm `.squad/superpowers.md` exists and has the catalog**

```bash
grep -c "^|" .squad/superpowers.md
```

Expected: 10 or more (counts table rows across all three catalog tables).
