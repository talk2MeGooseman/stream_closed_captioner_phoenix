# Session Log — Coolify Deploy Remediation Planning

**Timestamp:** 2026-04-28T04:49:40Z  
**Duration:** Planning phase  
**Participants:** Morpheus (lead), Oracle (security), Trinity (infra + fixes), Erik (stakeholder)

---

## Summary

Coolify stage deploy (2026-07-22) succeeded but surfaced 22 secret-leak warnings + minor issues. Planning session identified root causes and produced prioritized remediation plan.

**Key Findings:**
- **P0 (CRITICAL):** Coolify injects all env vars as build-args; secrets bake into layer metadata (recoverable via `docker history`). Fix: Coolify UI "Build vs Runtime" separation (Erik → Oracle validates).
- **P1 (MEDIUM):** Dead `:bot` config + TWITCH_CHAT_OAUTH ref in runtime.exs (TMI removed). Fix: Kill config block + doc ref (Trinity → Tank verifies).
- **P2 (LOW):** Dockerfile line 17 `as` vs `AS` casing. Fix: One-line uppercase change (Trinity, bundle with P1).
- **P3-P5:** Swappiness warning (host kernel, defer), orphan container (Coolify UI, defer), dep warnings (wait for upstream, no action).

**Effort:** ~1.5 hours active work (P0 + P1 + P2). P0 must be resolved before any registry push.

---

## Decisions Produced

4 orchestration logs drafted:
- Morpheus: Risk analysis + code review oversight
- Oracle: Security audit + stale config findings
- Trinity Infra: Coolify warning scoping
- Trinity Fixes: Implementation plan for config + Dockerfile changes

---

## Next Steps

1. **Erik** → Act on P0 (Coolify "Build vs Runtime" separation)
2. **Trinity** → Implement P1 + P2 (config + casing)
3. **Tank** → Verify compile + tests
4. **Scribe** → Merge decisions + commit logs
