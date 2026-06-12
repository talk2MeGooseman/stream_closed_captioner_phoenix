defmodule StreamClosedCaptionerPhoenixWeb.CaptionSourceLiveTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.Settings
  alias Twitch.Extension.CaptionsPayload

  defp create_caption_source(_context) do
    stream_settings =
      insert(:stream_settings, user: build(:bare_user))
      |> Settings.get_or_generate_caption_source_token!()

    %{stream_settings: stream_settings, token: stream_settings.caption_source_token}
  end

  defp broadcast_caption(stream_settings, payload) do
    Phoenix.PubSub.broadcast(
      StreamClosedCaptionerPhoenix.PubSub,
      "caption_source:#{stream_settings.user_id}",
      {:caption_source_payload, payload}
    )
  end

  describe "mount" do
    setup :create_caption_source

    test "renders the empty overlay for a valid token", %{conn: conn, token: token} do
      {:ok, view, html} = live(conn, "/captions/#{token}")

      assert html =~ "caption-source"
      refute html =~ "no longer valid"
      # no caption box until the first payload arrives
      refute has_element?(view, "#caption-box")
    end

    test "a regenerated token renders the overlay at its new URL", %{
      conn: conn,
      stream_settings: stream_settings
    } do
      {:ok, stream_settings} = Settings.regenerate_caption_source_token(stream_settings)

      {:ok, _view, html} = live(conn, "/captions/#{stream_settings.caption_source_token}")

      assert html =~ "caption-source"
      refute html =~ "no longer valid"
    end

    test "renders an invalid-URL notice for an unknown token", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/captions/not-a-real-token")

      assert html =~ "caption source URL is no longer valid"
      assert html =~ "caption settings"
    end

    test "regenerating the token invalidates the old URL with a visible notice", %{
      conn: conn,
      stream_settings: stream_settings,
      token: old_token
    } do
      {:ok, _stream_settings} = Settings.regenerate_caption_source_token(stream_settings)

      {:ok, _view, html} = live(conn, "/captions/#{old_token}")

      assert html =~ "caption source URL is no longer valid"
    end

    test "does not render site chrome", %{conn: conn, token: token} do
      html = conn |> get("/captions/#{token}") |> html_response(200)

      assert html =~ "background: transparent"
      refute html =~ "<nav"
    end
  end

  describe "receiving captions" do
    setup :create_caption_source

    test "renders interim and final text from a broadcast", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      broadcast_caption(stream_settings, %CaptionsPayload{
        interim: "and then",
        final: "hello world"
      })

      assert render(view) =~ "hello world"
      assert render(view) =~ "and then"
    end

    test "appends successive final texts (rolling captions)", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "first part"})
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "second part"})

      html = render(view)
      assert html =~ "first part second part"
    end

    test "trims old text once the rolling buffer exceeds the cap", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      long_text = String.duplicate("oldword ", 80) |> String.trim()

      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: long_text})
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "newest words"})

      html = render(view)
      assert html =~ "newest words"
      # 80 * 8 chars > 500-char cap, so the front of the buffer must be gone
      refute html =~ long_text
    end

    test "empty final keeps the existing text and updates interim", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hello world"})
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "more coming", final: ""})

      html = render(view)
      assert html =~ "hello world"
      assert html =~ "more coming"
    end
  end

  describe "style query params" do
    setup :create_caption_source

    test "applies defaults with no params", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hi"})

      html = render(view)
      assert html =~ "font-size: 32px"
      assert html =~ "rgb(255, 255, 255)"
      assert html =~ "rgba(0, 0, 0, 0.7)"
      assert html =~ "text-align: left"
      assert html =~ "text-transform: none"
    end

    test "applies valid params", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      {:ok, view, _html} =
        live(
          conn,
          "/captions/#{token}?font_size=40&color=00ff00&bg=112233&bg_opacity=50&align=center&uppercase=true&font=mono"
        )

      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hi"})

      html = render(view)
      assert html =~ "font-size: 40px"
      assert html =~ "rgb(0, 255, 0)"
      assert html =~ "rgba(17, 34, 51, 0.5)"
      assert html =~ "text-align: center"
      assert html =~ "text-transform: uppercase"
      assert html =~ "monospace"
    end

    test "clamps out-of-range numbers and rejects bad values", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      {:ok, view, _html} =
        live(
          conn,
          "/captions/#{token}?font_size=9999&bg_opacity=-5&align=diagonal&color=red;}body{display:none"
        )

      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hi"})

      html = render(view)
      assert html =~ "font-size: 120px"
      assert html =~ "rgba(0, 0, 0, 0.0)"
      assert html =~ "text-align: left"
      assert html =~ "rgb(255, 255, 255)"
      refute html =~ "display:none"
    end

    test "clips text on a padding-free inner element so no partial extra line shows", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      # lines=2 rather than the parse_int default of 3, so this fails if the
      # param stops being plumbed through.
      {:ok, view, _html} = live(conn, "/captions/#{token}?lines=2")
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hi"})
      render(view)

      # overflow: hidden clips at the padding box, so clipping on the padded
      # caption box lets the tail of an extra line paint inside the top
      # padding; the clip container must be an unpadded element sized to
      # exactly N line-heights.
      assert has_element?(view, ~s{#caption-clip[style*="max-height: calc(2 * 1.4em)"]})
      assert has_element?(view, ~s{#caption-clip[style*="overflow: hidden"]})
      refute has_element?(view, ~s{#caption-clip[style*="padding"]})
      refute has_element?(view, ~s{#caption-box[style*="overflow: hidden"]})
      refute has_element?(view, ~s{#caption-box[style*="max-height"]})
    end

    test "clamps lines to the 1..10 bounds", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}?lines=0")
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hi"})
      render(view)
      assert has_element?(view, ~s{#caption-clip[style*="max-height: calc(1 * 1.4em)"]})

      {:ok, view, _html} = live(conn, "/captions/#{token}?lines=99")
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hi"})
      render(view)
      assert has_element?(view, ~s{#caption-clip[style*="max-height: calc(10 * 1.4em)"]})
    end

    test "uppercase defaults from the streamer's text_uppercase setting", %{conn: conn} do
      stream_settings =
        insert(:stream_settings, user: build(:bare_user), text_uppercase: true)
        |> Settings.get_or_generate_caption_source_token!()

      {:ok, view, _html} = live(conn, "/captions/#{stream_settings.caption_source_token}")
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hi"})

      assert render(view) =~ "text-transform: uppercase"
    end
  end

  describe "settings tool visibility" do
    setup :create_caption_source

    test "gear button is available by default in a normal browser", %{conn: conn, token: token} do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      assert has_element?(view, "#settings-gear")
    end

    test "settings=0 hides the tool entirely", %{conn: conn, token: token} do
      {:ok, view, _html} = live(conn, "/captions/#{token}?settings=0")

      refute has_element?(view, "#caption-settings-ui")
      refute has_element?(view, "#settings-gear")
    end

    # Routing render_hook through the element pins phx-hook="ObsDetect" in the
    # rendered HTML — the testable half of the OBS-hiding boundary (the JS
    # side of the hook is not reachable from ExUnit).
    test "obs detection hides the tool by default", %{conn: conn, token: token} do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      view
      |> element(~s{#caption-settings-ui[phx-hook="ObsDetect"]})
      |> render_hook("obs_detected", %{})

      refute has_element?(view, "#settings-gear")
    end

    test "settings=1 keeps the tool available even when OBS is detected", %{
      conn: conn,
      token: token
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}?settings=1")

      view
      |> element(~s{#caption-settings-ui[phx-hook="ObsDetect"]})
      |> render_hook("obs_detected", %{})

      assert has_element?(view, "#settings-gear")
    end

    test "obs detection closes an already-open panel", %{conn: conn, token: token} do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      view |> element("#settings-gear") |> render_click()
      assert has_element?(view, "#settings-panel")

      view
      |> element(~s{#caption-settings-ui[phx-hook="ObsDetect"]})
      |> render_hook("obs_detected", %{})

      refute has_element?(view, "#settings-panel")
    end
  end

  describe "settings panel dummy text" do
    setup :create_caption_source

    test "dummy text never renders while the panel is closed", %{conn: conn, token: token} do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      refute render(view) =~ "quick brown fox"
      refute has_element?(view, "#caption-box")
    end

    test "opening the panel shows dummy caption text in the caption box", %{
      conn: conn,
      token: token
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      view |> element("#settings-gear") |> render_click()

      assert has_element?(view, "#settings-panel")
      assert has_element?(view, "#caption-box")
      assert render(view) =~ "quick brown fox"
    end

    test "real captions are held back while the panel is open and restored on close", %{
      conn: conn,
      token: token,
      stream_settings: stream_settings
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      view |> element("#settings-gear") |> render_click()
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hello world"})

      html = render(view)
      assert html =~ "quick brown fox"
      refute html =~ "hello world"

      view |> element("#settings-close") |> render_click()

      html = render(view)
      refute html =~ "quick brown fox"
      assert html =~ "hello world"
    end
  end

  describe "settings panel URL sync" do
    setup :create_caption_source

    test "changing a setting patches the URL and applies the style", %{
      conn: conn,
      token: token
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      view |> element("#settings-gear") |> render_click()

      view
      |> element("#settings-form")
      |> render_change(%{"font_size" => "48", "color" => "#00ff00"})

      path = assert_patch(view)
      assert path =~ "font_size=48"
      assert path =~ "color=00FF00"

      html = render(view)
      assert html =~ "font-size: 48px"
      assert html =~ "rgb(0, 255, 0)"

      # the copy-URL field must hold the freshly patched URL
      assert has_element?(view, ~s{#overlay-url[value*="font_size=48"]})
    end

    test "default values are omitted from the patched URL", %{conn: conn, token: token} do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      view |> element("#settings-gear") |> render_click()

      view
      |> element("#settings-form")
      |> render_change(%{
        "font_size" => "48",
        "color" => "#ffffff",
        "bg" => "#000000",
        "bg_opacity" => "70",
        "align" => "left",
        "lines" => "3",
        "font" => "sans",
        "uppercase" => "false"
      })

      path = assert_patch(view)
      assert path =~ "font_size=48"
      refute path =~ "color="
      refute path =~ "bg="
      refute path =~ "align="
      refute path =~ "lines="
      refute path =~ "font="
      refute path =~ "uppercase="
    end

    test "switching off uppercase for an uppercase-default streamer emits uppercase=false", %{
      conn: conn
    } do
      stream_settings =
        insert(:stream_settings, user: build(:bare_user), text_uppercase: true)
        |> Settings.get_or_generate_caption_source_token!()

      {:ok, view, _html} = live(conn, "/captions/#{stream_settings.caption_source_token}")

      view |> element("#settings-gear") |> render_click()

      view
      |> element("#settings-form")
      |> render_change(%{"uppercase" => "false"})

      # the default is the streamer's text_uppercase, not a static false, so
      # turning uppercase off is a non-default value and must be in the URL
      path = assert_patch(view)
      assert path =~ "uppercase=false"
      assert render(view) =~ "text-transform: none"
    end

    test "uppercase submitted as a list (hidden input + checked checkbox) uses the last value", %{
      conn: conn,
      token: token
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      view |> element("#settings-gear") |> render_click()

      render_change(view, "update_settings", %{"uppercase" => ["false", "true"]})

      path = assert_patch(view)
      assert path =~ "uppercase=true"
      assert render(view) =~ "text-transform: uppercase"
    end

    test "the settings=1 override survives setting changes", %{conn: conn, token: token} do
      {:ok, view, _html} = live(conn, "/captions/#{token}?settings=1")

      view |> element("#settings-gear") |> render_click()

      view
      |> element("#settings-form")
      |> render_change(%{"font_size" => "48"})

      path = assert_patch(view)
      assert path =~ "settings=1"
      assert has_element?(view, "#settings-panel")
    end

    test "the panel offers a copy button wired to the CopyToClipboard hook", %{
      conn: conn,
      token: token
    } do
      {:ok, view, _html} = live(conn, "/captions/#{token}")

      view |> element("#settings-gear") |> render_click()

      assert has_element?(view, "#overlay-url")

      assert has_element?(
               view,
               ~s{#overlay-url-copy[phx-hook="CopyToClipboard"][data-copy-target="overlay-url"]}
             )
    end
  end

  describe "caption delay" do
    test "defers rendering when caption_delay is set", %{conn: conn} do
      # 60s delay: long enough that the deferred timer cannot fire during the
      # test, so the refute below is deterministic under any load.
      stream_settings =
        insert(:stream_settings, user: build(:bare_user), caption_delay: 60)
        |> Settings.get_or_generate_caption_source_token!()

      {:ok, view, _html} = live(conn, "/captions/#{stream_settings.caption_source_token}")

      payload = %CaptionsPayload{interim: "", final: "delayed text"}
      broadcast_caption(stream_settings, payload)

      # render/1 is a synchronous call into the LiveView process, so the
      # broadcast has been handled by the time it returns; if the delay were
      # ignored and captions applied immediately, this would fail.
      refute render(view) =~ "delayed text"

      # Fire the deferred-apply message ourselves instead of sleeping out the
      # Process.send_after timer.
      send(view.pid, {:apply_caption, payload})
      assert render(view) =~ "delayed text"
    end

    test "the scheduled timer itself applies captions after the delay", %{conn: conn} do
      # Companion to the test above: that one pins the deferred-message
      # handler, this one pins the scheduling — if the delay branch dropped
      # the payload instead of calling Process.send_after, only this fails.
      # The generous assert-side wait has no refute-style race; it can only
      # flake if the machine stalls for 3s+.
      stream_settings =
        insert(:stream_settings, user: build(:bare_user), caption_delay: 1)
        |> Settings.get_or_generate_caption_source_token!()

      {:ok, view, _html} = live(conn, "/captions/#{stream_settings.caption_source_token}")
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "delayed text"})

      unless render_eventually?(view, "delayed text", 3_000) do
        flunk("expected the deferred caption to render within 3s of the broadcast")
      end
    end
  end

  defp render_eventually?(view, text, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    poll_render(view, text, deadline)
  end

  defp poll_render(view, text, deadline) do
    cond do
      render(view) =~ text ->
        true

      System.monotonic_time(:millisecond) >= deadline ->
        false

      true ->
        Process.sleep(50)
        poll_render(view, text, deadline)
    end
  end
end
