# Squad Decisions

## Active Decisions

### Pragmatic Programmer Methodologies — Team Standard

**By:** Erik Guzman (via Copilot)
**Date:** 2026-04-21
**Category:** Process & Philosophy

All team members should read and follow *The Pragmatic Programmer* methodologies as core development practices for this project.

**Key Principles:**
- **DRY (Don't Repeat Yourself)** — eliminate duplication in code and logic
- **Fail Fast & Handle Errors Gracefully** — explicit error messaging over silent failures
- **Invest in Tooling** — leverage linting, testing, automation, CI/CD effectively
- **Refactor Ruthlessly** — continuously improve code structure and clarity
- **Know Your Domain** — master Twitch API, Phoenix patterns, Elixir idioms
- **Communicate Clearly** — code should be readable; tests should document behavior
- **Automate Tests** — catch issues early; prioritize test coverage
- **Estimate Carefully** — be realistic about complexity and dependencies

**Impact on Review:** Code reviews evaluate adherence to these principles. PRs that violate DRY, fail to handle errors gracefully, or lack clarity are sent back for refinement.

**Status:** ✅ Adopted as team standard

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
