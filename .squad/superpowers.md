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
