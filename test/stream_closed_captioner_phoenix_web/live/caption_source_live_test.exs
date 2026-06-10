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
      # no caption box until the first payload arrives
      refute has_element?(view, "#caption-box")
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

      broadcast_caption(stream_settings, %CaptionsPayload{interim: "and then", final: "hello world"})

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
      {:ok, view, _html} = live(conn, "/captions/#{token}?lines=3")
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "hi"})
      render(view)

      # overflow: hidden clips at the padding box, so clipping on the padded
      # caption box lets the tail of an extra line paint inside the top
      # padding; the clip container must be an unpadded element sized to
      # exactly N line-heights.
      assert has_element?(view, ~s{#caption-clip[style*="max-height: calc(3 * 1.4em)"]})
      assert has_element?(view, ~s{#caption-clip[style*="overflow: hidden"]})
      refute has_element?(view, ~s{#caption-box[style*="overflow: hidden"]})
      refute has_element?(view, ~s{#caption-box[style*="max-height"]})
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

  describe "caption delay" do
    test "defers rendering when caption_delay is set", %{conn: conn} do
      stream_settings =
        insert(:stream_settings, user: build(:bare_user), caption_delay: 1)
        |> Settings.get_or_generate_caption_source_token!()

      {:ok, view, _html} = live(conn, "/captions/#{stream_settings.caption_source_token}")
      broadcast_caption(stream_settings, %CaptionsPayload{interim: "", final: "delayed text"})

      refute render(view) =~ "delayed text"

      Process.sleep(1100)
      assert render(view) =~ "delayed text"
    end
  end
end
