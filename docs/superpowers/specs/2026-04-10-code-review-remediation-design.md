# Code Review Remediation — Design Spec

**Date:** 2026-04-10
**Status:** Approved
**Scope:** 23 issues from multi-agent code review, organized into 5 PRs by phase

## Context

A multi-agent code review of the captions pipeline identified 20 issues across `captions_channel.ex`, `captions_pipeline.ex`, `browser_compatibility.js`, and test files. Issues range from critical security vulnerabilities (SSRF, cross-user data leakage) to minor code cleanup.

### Key Decisions

- **Transcript feature is dead code** — remove entirely instead of fixing (eliminates items 1c, 1d, 3b)
- **Zoom integration is live** — requires careful SSRF fix with URL allowlisting
- **Shipping strategy** — one PR per phase (5 PRs total)
- **Test strategy** — introduce Mox for testable external boundaries (Zoom, TalkLikeAX)

---

## Phase 1: Critical Security (P0)

**PR scope:** 3 changes, focused on eliminating attack surfaces.

### 1a. SSRF Fix — Zoom URL Validation

**File:** `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`

The `:zoom` pipeline clause passes `message["zoom"]["url"]` directly to `Zoom.send_captions_to/3`, which performs `HTTPoison.post` to that URL with no validation. Any authenticated user can make the server HTTP-request arbitrary destinations.

**Fix:** Add a `validate_zoom_url/1` private function in `captions_pipeline.ex`:

- Parse URL with `URI.parse/1`
- Require `scheme == "https"`
- Require `host` ends with `.zoom.us`
- Return `{:ok, url}` or `{:error, :invalid_zoom_url}`
- Call before `Zoom.send_captions_to/3`
- Log rejected URLs at `:warning` level

```elixir
defp validate_zoom_url(url) when is_binary(url) do
  uri = URI.parse(url)

  cond do
    uri.scheme != "https" ->
      Logger.warning("Rejected non-HTTPS Zoom URL: #{inspect(uri.scheme)}")
      {:error, :invalid_zoom_url}

    not String.ends_with?(uri.host || "", ".zoom.us") ->
      Logger.warning("Rejected non-Zoom host: #{inspect(uri.host)}")
      {:error, :invalid_zoom_url}

    true ->
      {:ok, url}
  end
end

defp validate_zoom_url(_), do: {:error, :invalid_zoom_url}
```

### 1b. Routing Wildcard Fix

**File:** `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex` line 44

The second `handle_in` clause uses `_publish_state` as a wildcard pattern. Any event name with `%{"twitch" => %{"enabled" => true}}` in the payload matches, including `"active"` heartbeats.

**Fix:** Change `_publish_state` to `"publishFinal"`.

### 1c+1d+3b. Remove Dead Transcript Code

**Files:**
- `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex` — delete all 3 `FunWithFlags.enabled?(:caption_source, ...)` + `broadcast_from!` blocks
- `lib/stream_closed_captioner_phoenix_web/live/transcirpts_live/show.ex` — delete file
- `lib/stream_closed_captioner_phoenix_web/live/transcirpts_live/show.html.heex` — delete if exists
- Router — remove transcript route(s)
- Any transcript-related test files — delete

---

## Phase 2: Crash Prevention & Error Visibility (P1)

**PR scope:** 6 changes across 3 files.

### 2a. Pipeline Error Logging in Channel

**File:** `captions_channel.ex` — 3 `{:error, _}` branches (zoom, twitch, default handlers)

Capture and log the actual error reason before returning the generic reply:

```elixir
{:error, reason} ->
  Logger.error("Zoom pipeline failed for user #{user.id}: #{inspect(reason)}")
  # ... existing reply
```

### 2b. publishBlob Logging + Cleanup

**File:** `captions_channel.ex` lines 73-84

- Add `Logger.warning` to the error branch
- Restructure to clarify side-effect-only intent:

```elixir
def handle_in("publishBlob", {:binary, chunk}, socket) do
  if pid = socket.assigns[:wss_pid] do
    case WebSockex.send_frame(pid, {:binary, chunk}) do
      :ok -> :ok
      {:error, reason} ->
        Logger.warning("WebSockex send_frame failed: #{inspect(reason)}")
    end
  end

  {:noreply, socket}
end
```

### 2c. Timex.parse! Crash Fix

**File:** `captions_channel.ex` `time_to_complete/1` function

Replace bang version:

```elixir
defp time_to_complete(nil), do: 0
defp time_to_complete(sent_on) do
  case Timex.parse(sent_on, "{ISO:Extended}") do
    {:ok, parsed} -> DateTime.diff(Timex.now(), parsed, :millisecond)
    {:error, _} -> 0
  end
end
```

### 2d. Settings Bare Match → with

**File:** `captions_pipeline.ex` — all 3 `pipeline_to` clauses (lines 29, 41, 58)

Wrap each clause body with `with`:

```elixir
def pipeline_to(:default, %User{} = user, message) do
  with {:ok, stream_settings} <- Settings.get_stream_settings_by_user_id(user.id) do
    payload =
      CaptionsPayload.new(message)
      |> apply_censoring(stream_settings)
      |> apply_pirate_mode(stream_settings)

    {:ok, payload}
  else
    {:error, _} -> {:error, "Stream settings not found"}
  end
end
```

Apply same pattern to `:twitch` and `:zoom` clauses.

### 2e. Zoom Blocklist Gap

**File:** `captions_pipeline.ex` `:zoom` clause (line 65-68)

Add blocklist censoring before additional censoring:

```elixir
payload =
  CaptionsPayload.new(message)
  |> apply_users_blocklist_for(:final, stream_settings)
  |> maybe_additional_censoring_for(:final, stream_settings)
  |> maybe_pirate_mode_for(:final, stream_settings)
```

### 2f. isChromium() Fix

**File:** `assets/js/utils/browser_compatibility.js`

Add `return false;` after line 9:

```javascript
if (hasGoogleChromeBrand) {
  return true;
}
return false;
```

---

## Phase 3: Code Quality (P2)

**PR scope:** 5 changes (3b eliminated by Phase 1).

### 3a. Move UserTracker from Pipeline to Channel

**Pipeline (`captions_pipeline.ex`):**
- Remove the `tap(fn _ -> UserTracker.update(...) end)` from `pipeline_to(:twitch)`
- Remove `alias StreamClosedCaptionerPhoenixWeb.UserTracker`

**Channel (`captions_channel.ex`):**
- Add `UserTracker.update` call in the twitch `handle_in` clause before calling `pipeline_to`, matching how `"active"` already handles it

### 3c. Remove Shadowed Alias

**File:** `captions_pipeline.ex` line 5

Delete `alias Azure.Cognitive.Translations` — shadowed by line 8 and never used.

### 3d. Add @trace to Zoom Clause

**File:** `captions_pipeline.ex` before `:zoom` clause

Add `@trace :pipeline_to`.

### 3e. Fix message_map Typespec

**File:** `captions_pipeline.ex` lines 14-18

```elixir
@type message_map :: %{
        optional(String.t()) => String.t()
      }
```

### 3f. Fix Test Translation Assertions

**File:** `captions_pipeline_test.exs`

Investigate actual return shape from `Translations.maybe_translate/3`. Align all test assertions to match the real struct shape. One test wraps in `%Azure.Cognitive.Translations{}`, another uses a bare map — only one can be correct.

---

## Phase 4: Minor Cleanup (P3)

### 4a. Defensive Pirate Mode Handling

**File:** `captions_pipeline.ex` `maybe_pirate_mode_for/3`

```elixir
defp maybe_pirate_mode_for(payload, key, %StreamSettings{pirate_mode: true}) do
  case TalkLikeAX.translate(Map.get(payload, key)) do
    {:ok, text} -> Map.put(payload, key, text)
    {:error, reason} ->
      Logger.warning("Pirate mode translation failed: #{inspect(reason)}")
      payload
  end
end

defp maybe_pirate_mode_for(payload, _key, _stream_settings), do: payload
```

---

## Phase 5: Test Coverage

### Test Infrastructure Setup

- Add `{:mox, "~> 1.0", only: :test}` to `mix.exs`
- Create behaviours:
  - `StreamClosedCaptionerPhoenix.Services.ZoomBehaviour` — `send_captions_to/3`
  - `StreamClosedCaptionerPhoenix.Services.PirateBehaviour` — `translate/1`
- Define mocks in `test/support/mocks.ex`
- Configure mock implementations in `config/test.exs`
- Update production modules to use configurable implementations

### New Tests

**5a. Zoom channel handler:**
- Success path with valid Zoom URL
- SSRF rejection with non-Zoom URL
- SSRF rejection with HTTP (non-HTTPS) URL
- Pipeline error returns error reply

**5b. publishBlob handler:**
- With valid `wss_pid` — success path
- With valid `wss_pid` — error path (verify warning logged)
- Without `wss_pid` — noop

**5c. Pipeline error paths:**
- Mock pipeline to return `{:error, reason}`, assert `{:error, "Issue sending captions."}` reply for each handler

**5d. Malformed sentOn:**
- Push twitch payload with `"sentOn" => "not-a-date"`, verify channel does not crash, reply is still `:ok`

**5e. Missing stream settings:**
- Create user without stream settings, call `pipeline_to`, verify `{:error, "Stream settings not found"}`

**5f. isChromium JS:**
- Skip — no JS test infrastructure exists for this file. Note in PR description for manual verification.

---

## Files Changed (Summary)

| File | Phases | Changes |
|------|--------|---------|
| `captions_channel.ex` | 1, 2, 3 | Routing fix, remove transcript broadcasts, error logging, publishBlob cleanup, timex fix, add UserTracker call for twitch |
| `captions_pipeline.ex` | 1, 2, 3, 4 | SSRF validation, with clauses, zoom blocklist, remove UserTracker/alias, add @trace, fix typespec, pirate mode defensive |
| `browser_compatibility.js` | 2 | Add `return false` |
| `transcirpts_live/show.ex` | 1 | Delete |
| `router.ex` | 1 | Remove transcript route |
| `test/...channel_test.exs` | 5 | New tests for zoom, blob, errors, sentOn |
| `test/...pipeline_test.exs` | 3, 5 | Fix assertions, add missing settings test |
| `test/support/mocks.ex` | 5 | New file — Mox definitions |
| `mix.exs` | 5 | Add mox dependency |
| `config/test.exs` | 5 | Configure mock implementations |
