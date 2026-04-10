# Code Review Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 20 issues from multi-agent code review across captions pipeline, channel, and browser compatibility — organized into 5 phase-based PRs.

**Architecture:** Surgical fixes to existing files. No new features. Transcript dead code is removed. Zoom URL validation added. Error handling improved throughout. Tests added for new error paths and edge cases.

**Tech Stack:** Elixir/Phoenix, ExUnit, Mox (already in project), JavaScript

---

## Task 1: SSRF Fix — Zoom URL Validation (Phase 1)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex:57-85`

- [ ] **Step 1: Add `validate_zoom_url/1` private function**

Add the following after `maybe_pirate_mode_for` (after line 143) in `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`:

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

- [ ] **Step 2: Wire validation into the `:zoom` pipeline clause**

In `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`, replace lines 70-73 (the `zoom_text` and `url` extraction + case block) with:

```elixir
    zoom_text = Map.get(payload, :final)

    with {:ok, url} <- validate_zoom_url(get_in(message, ["zoom", "url"])),
         result <- Zoom.send_captions_to(url, zoom_text, params) do
      case result do
        {:ok, %HTTPoison.Response{status_code: 200}} ->
          {:ok, payload}

        {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
          Logger.debug("Request was rejected code: #{code} body: #{body}")
          {:error, body}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.debug("Request was error")
          {:error, reason}
      end
    end
```

- [ ] **Step 3: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Compiles with no errors.

- [ ] **Step 4: Run existing tests to confirm no regressions**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`
Expected: All existing tests pass.

---

## Task 2: Fix Routing Wildcard (Phase 1)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex:44`

- [ ] **Step 1: Change `_publish_state` to `"publishFinal"`**

In `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`, change line 44 from:

```elixir
  def handle_in(_publish_state, %{"twitch" => %{"enabled" => true}} = payload, socket) do
```

to:

```elixir
  def handle_in("publishFinal", %{"twitch" => %{"enabled" => true}} = payload, socket) do
```

- [ ] **Step 2: Verify compilation and tests**

Run: `mix compile --warnings-as-errors && mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_test.exs`
Expected: Compiles cleanly, all channel tests pass.

---

## Task 3: Remove Dead Transcript Code (Phase 1)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex` (3 broadcast blocks)
- Modify: `lib/stream_closed_captioner_phoenix_web/router.ex:26-28,145-149`
- Delete: `lib/stream_closed_captioner_phoenix_web/live/transcirpts_live/show.ex`
- Delete: `lib/stream_closed_captioner_phoenix_web/live/transcirpts_live/show.html.heex`

- [ ] **Step 1: Remove FunWithFlags broadcast block from zoom handler**

In `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`, delete lines 26-33 (the `if FunWithFlags.enabled?` block inside the zoom `handle_in`):

```elixir
        if FunWithFlags.enabled?(:caption_source, for: socket.assigns.current_user) do
          StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast_from!(
            self(),
            "transcript:1",
            "new_msg",
            payload
          )
        end
```

- [ ] **Step 2: Remove FunWithFlags broadcast block from twitch handler**

In the same file, delete lines 55-62 (the `if FunWithFlags.enabled?` block inside the twitch `handle_in`):

```elixir
        if FunWithFlags.enabled?(:caption_source, for: socket.assigns.current_user) do
          StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast_from!(
            self(),
            "transcript:1",
            "new_msg",
            sent_payload
          )
        end
```

- [ ] **Step 3: Remove unconditional broadcast from default handler**

In the same file, delete lines 102-107 (the `broadcast_from!` call in the default `handle_in`):

```elixir
        StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast_from!(
          self(),
          "transcript:1",
          "new_msg",
          payload
        )
```

- [ ] **Step 4: Delete transcript LiveView files**

Run:
```bash
rm lib/stream_closed_captioner_phoenix_web/live/transcirpts_live/show.ex
rm lib/stream_closed_captioner_phoenix_web/live/transcirpts_live/show.html.heex
rmdir lib/stream_closed_captioner_phoenix_web/live/transcirpts_live/
```

- [ ] **Step 5: Remove transcript route and pipeline from router**

In `lib/stream_closed_captioner_phoenix_web/router.ex`, delete the `transcript_ui` pipeline (lines 26-28):

```elixir
  pipeline :transcript_ui do
    plug(:put_root_layout, {StreamClosedCaptionerPhoenixWeb.Layouts, :transcript})
  end
```

And delete the transcript scope (lines 145-149):

```elixir
  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through([:browser, :admin_protected, :transcript_ui])

    live "/transcripts/:id", TranscirptsLive.Show, :show
  end
```

- [ ] **Step 6: Verify compilation and full test suite**

Run: `mix compile --warnings-as-errors && mix test`
Expected: No compilation errors (no remaining references to deleted modules). All tests pass.

- [ ] **Step 7: Commit Phase 1**

```bash
git add -A
git commit -m "security: Fix SSRF, routing wildcard, and remove dead transcript code

- Add Zoom URL validation (allowlist *.zoom.us, require HTTPS)
- Fix _publish_state wildcard to explicitly match 'publishFinal'
- Remove dead transcript broadcasting and TranscirptsLive.Show

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: Add Error Logging to Pipeline Error Paths (Phase 2)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`

Note: After Phase 1, line numbers will have shifted. Find the `{:error, _}` branches by their content.

- [ ] **Step 1: Add logging to zoom handler error branch**

In `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`, in the zoom `handle_in`, change:

```elixir
      {:error, _} ->
        NewRelic.stop_transaction()
        {:reply, {:error, "Issue sending captions."}, socket}
```

to:

```elixir
      {:error, reason} ->
        Logger.error("Zoom pipeline failed for user #{user.id}: #{inspect(reason)}")
        NewRelic.stop_transaction()
        {:reply, {:error, "Issue sending captions."}, socket}
```

- [ ] **Step 2: Add logging to twitch handler error branch**

In the twitch `handle_in`, change:

```elixir
      {:error, _} ->
        new_relic_track(:error, user, sent_on_time)
        {:reply, {:error, "Issue sending captions."}, socket}
```

to:

```elixir
      {:error, reason} ->
        Logger.error("Twitch pipeline failed for user #{user.id}: #{inspect(reason)}")
        new_relic_track(:error, user, sent_on_time)
        {:reply, {:error, "Issue sending captions."}, socket}
```

- [ ] **Step 3: Add logging to default handler error branch**

In the default `handle_in`, change:

```elixir
      {:error, _} ->
        {:reply, {:error, "Issue sending captions."}, socket}
```

to:

```elixir
      {:error, reason} ->
        Logger.error("Default pipeline failed for user #{user.id}: #{inspect(reason)}")
        {:reply, {:error, "Issue sending captions."}, socket}
```

- [ ] **Step 4: Add `require Logger` at the top of the module**

In `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`, add after line 3 (`use NewRelic.Tracer`):

```elixir
  require Logger
```

- [ ] **Step 5: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Compiles cleanly.

---

## Task 5: Fix publishBlob Silent Error + Dead Returns (Phase 2)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`

- [ ] **Step 1: Replace the publishBlob handler**

Find the `handle_in("publishBlob", ...)` function and replace the entire function with:

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

- [ ] **Step 2: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Compiles cleanly.

---

## Task 6: Fix Timex.parse! Crash (Phase 2)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`

- [ ] **Step 1: Replace `time_to_complete/1`**

Find the two `time_to_complete` function clauses and replace both with:

```elixir
  defp time_to_complete(nil), do: 0

  defp time_to_complete(sent_on) do
    case Timex.parse(sent_on, "{ISO:Extended}") do
      {:ok, parsed} -> DateTime.diff(Timex.now(), parsed, :millisecond)
      {:error, _} -> 0
    end
  end
```

- [ ] **Step 2: Verify compilation and tests**

Run: `mix compile --warnings-as-errors && mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_test.exs`
Expected: All pass.

---

## Task 7: Fix Settings Bare Match → with (Phase 2)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`

- [ ] **Step 1: Wrap `:default` clause with `with`**

Replace the body of `pipeline_to(:default, ...)`:

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

- [ ] **Step 2: Wrap `:twitch` clause with `with`**

Replace the body of `pipeline_to(:twitch, ...)`:

```elixir
  def pipeline_to(:twitch, %User{} = user, message) do
    with {:ok, stream_settings} <- Settings.get_stream_settings_by_user_id(user.id) do
      payload =
        CaptionsPayload.new(message)
        |> tap(fn _ ->
          UserTracker.update(self(), "active_channels", user.uid, %{
            last_publish: System.system_time(:second)
          })
        end)
        |> apply_censoring(stream_settings)
        |> Translations.maybe_translate(:final, user)
        |> apply_pirate_mode(stream_settings)

      {:ok, payload}
    else
      {:error, _} -> {:error, "Stream settings not found"}
    end
  end
```

- [ ] **Step 3: Wrap `:zoom` clause with `with`**

Replace the body of `pipeline_to(:zoom, ...)`. Note: this should already include the SSRF validation from Task 1:

```elixir
  def pipeline_to(:zoom, %User{} = user, message) do
    with {:ok, stream_settings} <- Settings.get_stream_settings_by_user_id(user.id) do
      params = %Zoom.Params{
        seq: get_in(message, ["zoom", "seq"]),
        lang: stream_settings.language
      }

      payload =
        CaptionsPayload.new(message)
        |> apply_users_blocklist_for(:final, stream_settings)
        |> maybe_additional_censoring_for(:final, stream_settings)
        |> maybe_pirate_mode_for(:final, stream_settings)

      zoom_text = Map.get(payload, :final)

      with {:ok, url} <- validate_zoom_url(get_in(message, ["zoom", "url"])),
           result <- Zoom.send_captions_to(url, zoom_text, params) do
        case result do
          {:ok, %HTTPoison.Response{status_code: 200}} ->
            {:ok, payload}

          {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
            Logger.debug("Request was rejected code: #{code} body: #{body}")
            {:error, body}

          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.debug("Request was error")
            {:error, reason}
        end
      end
    else
      {:error, _} -> {:error, "Stream settings not found"}
    end
  end
```

Note: This also includes the blocklist fix (2e) — `apply_users_blocklist_for(:final, stream_settings)` is added to the zoom pipeline here.

- [ ] **Step 4: Verify compilation and tests**

Run: `mix compile --warnings-as-errors && mix test test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`
Expected: All pass.

---

## Task 8: Fix isChromium() Missing Return (Phase 2)

**Files:**
- Modify: `assets/js/utils/browser_compatibility.js:7-9`

- [ ] **Step 1: Add `return false` after the brand check**

In `assets/js/utils/browser_compatibility.js`, change lines 7-9 from:

```javascript
    if (hasGoogleChromeBrand) {
      return true;
    }
```

to:

```javascript
    if (hasGoogleChromeBrand) {
      return true;
    }
    return false;
```

- [ ] **Step 2: Commit Phase 2**

```bash
git add -A
git commit -m "fix: Improve error handling, logging, and crash prevention

- Add error logging to all pipeline error paths in channel
- Fix publishBlob silent error swallowing with Logger.warning
- Replace Timex.parse! with non-bang parse + fallback
- Wrap pipeline_to settings lookup with 'with' for graceful errors
- Add blocklist censoring to zoom pipeline
- Fix isChromium() missing return false for non-Chrome Chromium

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 9: Move UserTracker from Pipeline to Channel (Phase 3)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`
- Modify: `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`

- [ ] **Step 1: Remove UserTracker from pipeline**

In `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`:

1. Delete the alias line:
```elixir
  alias StreamClosedCaptionerPhoenixWeb.UserTracker
```

2. In the `pipeline_to(:twitch, ...)` clause, remove the `tap` call. Change:
```elixir
      payload =
        CaptionsPayload.new(message)
        |> tap(fn _ ->
          UserTracker.update(self(), "active_channels", user.uid, %{
            last_publish: System.system_time(:second)
          })
        end)
        |> apply_censoring(stream_settings)
```

to:

```elixir
      payload =
        CaptionsPayload.new(message)
        |> apply_censoring(stream_settings)
```

- [ ] **Step 2: Add UserTracker call to twitch handler in channel**

In `lib/stream_closed_captioner_phoenix_web/channels/captions_channel.ex`, in the twitch `handle_in("publishFinal", ...)`, add after `user = socket.assigns.current_user`:

```elixir
    UserTracker.update(self(), "active_channels", user.uid, %{
      last_publish: System.system_time(:second)
    })
```

- [ ] **Step 3: Verify compilation and tests**

Run: `mix compile --warnings-as-errors && mix test`
Expected: All pass.

---

## Task 10: Pipeline Cleanup — Alias, Trace, Typespec (Phase 3)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`

- [ ] **Step 1: Remove shadowed alias**

Delete line 5:
```elixir
  alias Azure.Cognitive.Translations
```

- [ ] **Step 2: Add @trace to zoom clause**

Add `@trace :pipeline_to` before `def pipeline_to(:zoom, ...)`:

```elixir
  @trace :pipeline_to
  def pipeline_to(:zoom, %User{} = user, message) do
```

- [ ] **Step 3: Fix message_map typespec**

Replace the `@type message_map` block:

```elixir
  @type message_map :: %{optional(String.t()) => String.t()}
```

- [ ] **Step 4: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Compiles cleanly.

---

## Task 11: Fix Test Translation Assertions (Phase 3)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`
- Read: `lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex`

- [ ] **Step 1: Investigate actual translation return shape**

Run: `grep -n "translations:" lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex | head -10`

Check what `Translations.maybe_translate/3` actually puts into `payload.translations`. Compare with the two different assertion shapes in the test file.

- [ ] **Step 2: Align all translation test assertions to match the real shape**

After determining the correct struct shape, update any mismatched assertion. Both "enough bits activates translations" and "active translation debit" tests must assert the same struct shape for `translations`.

- [ ] **Step 3: Run tests to verify**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`
Expected: All pass.

- [ ] **Step 4: Commit Phase 3**

```bash
git add -A
git commit -m "refactor: Fix service boundary, dead alias, trace, and typespec

- Move UserTracker.update from pipeline to channel (fix boundary violation)
- Remove shadowed Azure.Cognitive.Translations alias
- Add @trace :pipeline_to to zoom clause
- Fix message_map typespec to use string keys
- Align test translation struct assertions

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 12: Defensive Pirate Mode Handling (Phase 4)

**Files:**
- Modify: `lib/stream_closed_captioner_phoenix/captions_pipeline.ex`

- [ ] **Step 1: Replace `maybe_pirate_mode_for/3`**

Replace the entire function (both clauses if the Phase 3 change to use pattern matching hasn't been applied yet):

```elixir
  defp maybe_pirate_mode_for(payload, key, %StreamSettings{pirate_mode: true}) do
    case TalkLikeAX.translate(Map.get(payload, key)) do
      {:ok, text} ->
        Map.put(payload, key, text)

      {:error, reason} ->
        Logger.warning("Pirate mode translation failed: #{inspect(reason)}")
        payload
    end
  end

  defp maybe_pirate_mode_for(payload, _key, _stream_settings), do: payload
```

- [ ] **Step 2: Verify existing pirate mode tests still pass**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_test.exs --trace`
Expected: All pass, including "when pirate mode is active" test.

- [ ] **Step 3: Commit Phase 4**

```bash
git add -A
git commit -m "fix: Add defensive error handling to pirate mode translation

Replace bare pattern match with case + fallback on TalkLikeAX error.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 13: Test Coverage — Zoom URL Validation (Phase 5)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`

- [ ] **Step 1: Write test for SSRF rejection of non-Zoom URL**

Add to the pipeline test file:

```elixir
  describe "pipeline_to(:zoom) URL validation" do
    test "rejects non-Zoom host URL" do
      user = insert(:user)

      result =
        CaptionsPipeline.pipeline_to(:zoom, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "abc",
          "zoom" => %{
            "enabled" => true,
            "url" => "https://evil.example.com/callback",
            "seq" => 1
          }
        })

      assert {:error, :invalid_zoom_url} = result
    end

    test "rejects non-HTTPS Zoom URL" do
      user = insert(:user)

      result =
        CaptionsPipeline.pipeline_to(:zoom, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "abc",
          "zoom" => %{
            "enabled" => true,
            "url" => "http://us02web.zoom.us/closedcaption",
            "seq" => 1
          }
        })

      assert {:error, :invalid_zoom_url} = result
    end

    test "rejects nil URL" do
      user = insert(:user)

      result =
        CaptionsPipeline.pipeline_to(:zoom, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "abc",
          "zoom" => %{
            "enabled" => true,
            "url" => nil,
            "seq" => 1
          }
        })

      assert {:error, :invalid_zoom_url} = result
    end
  end
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_test.exs --trace`
Expected: New URL validation tests pass (rely on `validate_zoom_url/1` from Task 1).

---

## Task 14: Test Coverage — Pipeline Missing Settings (Phase 5)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix/captions_pipeline_test.exs`

- [ ] **Step 1: Write test for missing stream settings**

Add to the test file:

```elixir
  describe "pipeline_to with missing stream settings" do
    test "returns error when user has no stream settings" do
      # Create user without stream_settings association
      user = insert(:user, stream_settings: nil)

      # Delete any stream_settings that the factory might have created
      import Ecto.Query
      StreamClosedCaptionerPhoenix.Repo.delete_all(
        from ss in StreamClosedCaptionerPhoenix.Settings.StreamSettings,
          where: ss.user_id == ^user.id
      )

      result =
        CaptionsPipeline.pipeline_to(:default, user, %{
          "interim" => "Hello",
          "final" => "World",
          "session" => "abc123"
        })

      assert {:error, "Stream settings not found"} = result
    end
  end
```

- [ ] **Step 2: Run the test to verify it passes**

Run: `mix test test/stream_closed_captioner_phoenix/captions_pipeline_test.exs --trace`
Expected: New test passes (relies on the `with` clause from Task 7).

---

## Task 15: Test Coverage — Channel Tests (Phase 5)

**Files:**
- Modify: `test/stream_closed_captioner_phoenix_web/channels/captions_channel_test.exs`

- [ ] **Step 1: Add test for malformed sentOn (no crash)**

Add to the channel test file:

```elixir
  test "publishFinal with malformed sentOn does not crash", %{socket: socket} do
    ref =
      push(socket, "publishFinal", %{
        "interim" => "hello",
        "final" => "world",
        "session" => "abc",
        "twitch" => %{"enabled" => true},
        "sentOn" => "not-a-valid-date"
      })

    assert_reply ref, :ok, %{final: "world", interim: "hello"}
  end
```

- [ ] **Step 2: Add test for pipeline error reply**

Add to the channel test file:

```elixir
  test "publishFinal returns error when pipeline fails", %{user: user} do
    # Create a second socket for a user with no stream settings
    bad_user = insert(:user, stream_settings: nil)

    import Ecto.Query
    StreamClosedCaptionerPhoenix.Repo.delete_all(
      from ss in StreamClosedCaptionerPhoenix.Settings.StreamSettings,
        where: ss.user_id == ^bad_user.id
    )

    {:ok, _, bad_socket} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: bad_user})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{bad_user.id}"
      )

    ref =
      push(bad_socket, "publishFinal", %{
        "interim" => "hello",
        "final" => "world",
        "session" => "abc"
      })

    assert_reply ref, :error, "Issue sending captions."
  end
```

- [ ] **Step 3: Run all channel tests**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_test.exs --trace`
Expected: All tests pass including the new ones.

- [ ] **Step 4: Add test for publishBlob without wss_pid (noop)**

Add to the channel test file:

```elixir
  test "publishBlob without wss_pid is a noop", %{socket: socket} do
    ref = push(socket, "publishBlob", {:binary, <<1, 2, 3>>})
    refute_reply ref, :ok
  end
```

- [ ] **Step 5: Run all channel tests**

Run: `mix test test/stream_closed_captioner_phoenix_web/channels/captions_channel_test.exs --trace`
Expected: All tests pass including the new ones.

- [ ] **Step 6: Commit Phase 5**

```bash
git add -A
git commit -m "test: Add coverage for URL validation, error paths, and edge cases

- Test SSRF rejection for non-Zoom and non-HTTPS URLs
- Test pipeline_to with missing stream settings returns error
- Test channel handles malformed sentOn without crashing
- Test channel returns error reply when pipeline fails
- Test publishBlob noop without wss_pid

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 16: Final Verification

- [ ] **Step 1: Run the full test suite**

Run: `mix test --trace`
Expected: All tests pass.

- [ ] **Step 2: Run compiler warnings check**

Run: `mix compile --warnings-as-errors`
Expected: No warnings.

- [ ] **Step 3: Run credo (if configured)**

Run: `mix credo --strict`
Expected: No new issues introduced.
