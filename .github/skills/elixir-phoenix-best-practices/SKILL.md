---
name: elixir-phoenix-best-practices
description: "Use when: enforcing Elixir and Phoenix best practices, reviewing contexts/controllers/liveviews, improving changesets/queries, and preparing production-ready Elixir code"
license: MIT
---

# Elixir Phoenix Best Practices

## Overview

Apply a repeatable workflow to audit and improve Elixir/Phoenix code quality without changing intended behavior.

## Use This Skill For

- Elixir/Phoenix code reviews
- Context/controller boundary checks
- Query and changeset quality checks
- Error handling consistency improvements
- Maintainability hardening before merge

## Workflow

1. Identify the touched modules and classify each as web layer, domain/context layer, data layer, or integration layer.
2. Verify architectural boundaries:
- Web layer delegates business decisions to context/service modules.
- Context APIs remain stable and explicit.
3. Verify correctness and reliability:
- Fallible flows return tagged tuples.
- Pattern matching and `with` are used for clarity in multi-step logic.
- External input is validated through changesets or dedicated validators.
4. Verify data access:
- Queries avoid N+1 patterns.
- Transactional writes use `Ecto.Multi` when atomicity is required.
5. Verify operational quality:
- Logging and telemetry are meaningful and not noisy.
- Tests cover key success and failure paths.
6. Apply minimal, surgical edits aligned with existing project conventions.

## Output Format

When using this skill, report findings in this order:

1. Critical correctness/security issues
2. Behavioral regression risks
3. Maintainability and clarity improvements
4. Missing tests or weak coverage areas
