# Gigalixir → Coolify Migration Plan

## Overview

This document covers the full transition from Gigalixir to a self-hosted Coolify
instance. The migration is designed to be zero-downtime: Gigalixir stays live and
fully serving traffic until DNS has fully propagated and the new host is verified.

**Goal:** Keep users unaffected. One failed check at any stage = stop and roll back.

---

## Prerequisites (Complete Before Migration Day)

- [ ] Coolify instance is running and accessible
- [ ] Self-hosted PostgreSQL is accessible from Coolify (already in place)
- [ ] App is deployed to Coolify and passing smoke tests on the Coolify temp domain
- [ ] All environment variables are set in Coolify (see list below)
- [ ] Access to your DNS provider (to update A/CNAME records)
- [ ] Access to [Twitch Developer Console](https://dev.twitch.tv/console) (to update OAuth redirect URIs)
- [ ] Domain registrar TTL can be edited

### Environment Variables Required in Coolify

```
DATABASE_URL                   # from your Coolify Postgres service
USE_SSL                        # true
POOL_SIZE                      # 5 (reduce from 10 on a smaller instance)
SECRET_KEY_BASE                # mix phx.gen.secret
LIVE_SIGNING_SALT              # mix phx.gen.secret 32
GUARDIAN_SECRET_KEY            # mix phx.gen.secret
HOST                           # your domain (e.g. stream-cc.gooseman.codes)
PORT                           # 4000
TWITCH_CLIENT_ID
TWITCH_CLIENT_SECRET
TWITCH_REDIRECT_URI            # https://<your-domain>/auth/twitch/callback
TWITCH_TOKEN_SECRET
TWITCH_CHAT_OAUTH
EVENTSUB_CALLBACK_URL          # https://<your-domain>/webhooks/twitch
SENDGRID_API_KEY
DEEPGRAM_TOKEN
NOTION_API_KEY
NOTION_VERSION
GRAPHQL_ENABLE_INTROSPECTION   # false
GRAPHQL_ENABLE_FIELD_SUGGESTIONS # false
CACHE_ALLOCATED_MEMORY         # 1073741824 for 4 GB host, 536870912 for 2 GB host
```

---

## Phase 1 — Staging Validation (1–3 Days Before Cutover)

Run all of these against the Coolify **temp domain** (not the live domain yet).

### 1.1 — Application health

- [ ] App responds with HTTP 200 on `/` 
- [ ] Phoenix LiveDashboard loads at `/dashboard` (requires login)
- [ ] No OOM kills or restart loops in Coolify logs

### 1.2 — Database

- [ ] Migrations ran cleanly during deploy (check Coolify deploy logs for `Running migrations...` with no errors)
- [ ] Can log in — this exercises the `users` table read path
- [ ] Visit admin panel (`/admin`) and confirm data is accessible

### 1.3 — Twitch integration (test with a secondary/test account)

Temporarily add the Coolify temp domain to Twitch Developer Console redirect URIs:

1. Go to [dev.twitch.tv/console](https://dev.twitch.tv/console) → your app → OAuth Redirect URLs
2. Add `https://<coolify-temp-domain>/auth/twitch/callback`
3. Test a full Twitch OAuth login flow on the temp domain
4. Remove the temp URL after testing

- [ ] Twitch OAuth login completes successfully
- [ ] User session persists across LiveView navigations

### 1.4 — Caption streaming

- [ ] Start a caption stream on the temp domain
- [ ] Deepgram WebSocket connects (check browser DevTools → Network → WS)
- [ ] Captions appear in the caption window

### 1.5 — Background jobs

- [ ] LiveDashboard → Oban jobs section shows queues are running (default, events)
- [ ] No jobs are stuck in `executing` state after 5 minutes

### 1.6 — Email

- [ ] Trigger a test email (e.g. sign up flow) and confirm it arrives via SendGrid

**Stop here if any check fails. Fix on Coolify before proceeding.**

---

## Phase 2 — DNS Preparation (24 Hours Before Cutover)

Lower your DNS TTL so the cutover propagates quickly. Do this at least 24 hours
before the planned cutover time, since the old high TTL may still be cached.

1. Log in to your DNS provider
2. Find the A record (or CNAME) for your domain (e.g. `stream-cc.gooseman.codes`)
3. Note the current TTL value — **write it down for rollback**
4. Change TTL to **300 seconds** (5 minutes)
5. Save — the old TTL must expire before the short TTL takes effect

Verify the TTL has propagated before cutover:
```bash
dig +short stream-cc.gooseman.codes
# or
nslookup stream-cc.gooseman.codes 8.8.8.8
```

---

## Phase 3 — Cutover (Migration Day)

Do this during low-traffic hours. Check your analytics for the quietest window.

### 3.1 — Final Gigalixir backup

```bash
# Take a database dump from Gigalixir's DB before any DNS changes
gigalixir pg:backups:create
gigalixir pg:backups:list
# Download the latest backup to local storage
gigalixir pg:backups:download <backup-id>
```

Store the backup somewhere safe outside of Gigalixir.

### 3.2 — Configure custom domain in Coolify

1. In Coolify → your app → Domains → Add Domain
2. Enter your domain (e.g. `https://stream-cc.gooseman.codes`)
3. Coolify will provision a Let's Encrypt certificate automatically once DNS points to it

### 3.3 — Update Twitch OAuth redirect URI

1. Go to [dev.twitch.tv/console](https://dev.twitch.tv/console) → your app → OAuth Redirect URLs
2. Add `https://<your-domain>/auth/twitch/callback` (pointing to new host)
3. **Do not remove the old Gigalixir URL yet** — keep both until DNS fully propagates

### 3.4 — Update DNS

In your DNS provider:

| Record | Type | Old value | New value |
|--------|------|-----------|-----------|
| `stream-cc.gooseman.codes` | A | Gigalixir IP | Coolify server IP |

Or if using CNAME:
| Record | Type | New value |
|--------|------|-----------|
| `stream-cc.gooseman.codes` | CNAME | `<coolify-server-hostname>` |

Save the change. TTL is now 300s, so propagation should complete within 5–10 minutes
globally, but allow up to 30 minutes for stubborn resolvers.

### 3.5 — Monitor propagation

Use multiple vantage points to confirm DNS has switched:

```bash
# Check from multiple resolvers
dig +short stream-cc.gooseman.codes @8.8.8.8        # Google
dig +short stream-cc.gooseman.codes @1.1.1.1        # Cloudflare
dig +short stream-cc.gooseman.codes @9.9.9.9        # Quad9
```

All three should return the Coolify server IP before you proceed.

You can also check global propagation at https://dnschecker.org

---

## Phase 4 — Post-Cutover Verification

Run these against the **real domain** (not the temp domain).

- [ ] `https://<your-domain>` loads and shows the correct app
- [ ] HTTPS certificate is valid (no browser warnings)
- [ ] Twitch OAuth login works end-to-end
- [ ] Caption stream starts and captions flow correctly
- [ ] Oban job queues are healthy (LiveDashboard)
- [ ] Check Coolify logs for any startup errors or crashes

### 3.6 — Clean up Twitch redirect URIs

Once the domain is confirmed working on Coolify:

1. Return to [dev.twitch.tv/console](https://dev.twitch.tv/console)
2. Remove the old Gigalixir redirect URI (the one ending in `.gigalixir.app` or similar)
3. Keep only the new domain URI

---

## Phase 5 — Decommission Gigalixir

**Wait at least 48 hours after successful cutover before this step.** This gives
time to catch any edge cases (background jobs, EventSub callbacks) that only
surface under real traffic.

```bash
# Scale down Gigalixir app to zero replicas first (preserves the app + config as backup)
gigalixir scale -r 0

# Monitor for 24-48 hours. If no issues:
gigalixir delete --app <app-name>

# Cancel Gigalixir subscription in their billing dashboard
```

Restore the DNS TTL to a normal value (e.g. 3600 seconds) after decommissioning.

---

## Rollback Plan

If anything goes wrong during or after cutover, rollback is fast because
**Gigalixir is never taken down until the final decommission step.**

### Rollback Triggers

Roll back immediately if any of these are observed:

- App returns 5xx errors for more than 2 minutes on the new host
- Twitch OAuth fails for all users
- Caption streaming is completely broken
- Database errors in Coolify logs (connection failure, migration errors)
- Memory/OOM kills causing restart loops

### Rollback Steps

1. **Revert DNS** — Change the A/CNAME record back to the old Gigalixir IP

   ```bash
   # Confirm the old Gigalixir IP (should still be in your DNS provider history)
   gigalixir domains
   ```

   DNS will propagate in ≤5 minutes at TTL 300.

2. **Verify Gigalixir is still live**

   ```bash
   curl -I https://<your-gigalixir-domain>.gigalixir.app
   # Should return HTTP 200
   ```

   Gigalixir keeps the app running until you explicitly scale down, so traffic
   will return to it as soon as DNS resolves back.

3. **Restore Twitch redirect URI** — Re-add the old URI in Twitch Developer Console
   if you already removed it.

4. **Investigate and fix** the issue on Coolify before attempting another cutover.

### What is NOT at risk

- **Database** — Your Coolify Postgres is independent. Gigalixir's DB has its own
  connection, so both old and new hosts can read/write without conflict during the
  overlap window. (There is a brief dual-write window during propagation; this is
  acceptable since the app is session-based and not event-sourced.)
- **User sessions** — Sessions are cookie-based. Existing browser sessions remain
  valid on whichever host they land on.

---

## Decision Checklist — Go / No-Go for Cutover

All of the following must be true before updating DNS:

| Check | Required State |
|-------|---------------|
| Phase 1 smoke tests | All passing on temp domain |
| DNS TTL lowered | ≥ 24 hours ago |
| DB backup downloaded | Confirmed locally |
| Coolify app uptime | Stable for ≥ 1 hour with no restarts |
| Twitch temp redirect added | Confirmed in dev console |
| Low-traffic window | Confirmed (check analytics) |
| Rollback plan reviewed | Team aware of revert steps |

If any row is not in the required state: **stop and reschedule**.

---

## Timing Reference

| Milestone | Estimated Time |
|-----------|---------------|
| Phase 1 staging validation | 30–60 min |
| DNS TTL reduction (soak) | 24 hours |
| DNS cutover propagation | 5–30 min |
| Phase 4 post-cutover verification | 15–20 min |
| Gigalixir decommission wait | 48 hours |
| **Total elapsed calendar time** | **~3 days** |
