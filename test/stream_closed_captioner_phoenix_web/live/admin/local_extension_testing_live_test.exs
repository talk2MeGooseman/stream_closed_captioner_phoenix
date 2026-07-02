defmodule StreamClosedCaptionerPhoenixWeb.Admin.LocalExtensionTestingLiveTest do
  # Not async: this module logs in by updating a fixture user to the shared,
  # unique admin uid, which would contend with other async admin tests doing
  # the same update.
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import StreamClosedCaptionerPhoenix.AccountsFixtures

  alias StreamClosedCaptionerPhoenix.Admin
  alias StreamClosedCaptionerPhoenixWeb.Endpoint

  @admin_uid "120750024"

  defp log_in_admin(%{conn: conn}) do
    {:ok, admin} = Admin.update_user(user_fixture(), %{uid: @admin_uid})
    %{conn: log_in_user(conn, admin)}
  end

  describe "access control" do
    test "redirects non-admin users away", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())

      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/admin/local-extension-testing")
    end
  end

  describe "page" do
    setup :log_in_admin

    test "renders the helper with the token field and empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/local-extension-testing")

      assert has_element?(view, "h1", "Local Extension Testing")
      assert has_element?(view, "code", "LOCAL_EXT_TESTING_ORIGINS")
      assert has_element?(view, "p", "No channels are currently captioning")
      assert has_element?(view, ~s(#local-dev-form input[name="local_base"]))
      assert has_element?(view, ~s(#local-dev-form input[name="manual_channel"]))
      assert has_element?(view, "textarea#socket_token[readonly]")
    end

    test "builds per-channel dev links for a manually entered channel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/local-extension-testing")

      html =
        view
        |> form("#local-dev-form", %{
          "local_base" => "http://localhost:9000/",
          "manual_channel" => "  12345  "
        })
        |> render_change()

      # Base is normalized (trailing slash trimmed) and the overlay link carries
      # the platform param Twitch itself sends, so the extension's
      # isVideoOverlay() check holds when testing overlay behavior.
      assert has_element?(
               view,
               ~s(a[href^="http://localhost:9000/?anchor=video_overlay&platform=web"][href*="scc_dev_token="])
             )

      assert has_element?(
               view,
               ~s(a[href^="http://localhost:9000/?anchor=mobile&platform=mobile"][href*="scc_dev_token="])
             )

      # The fragment carries the (trimmed) channel id and this deploy's origin,
      # so the local build knows which backend to talk to.
      assert has_element?(view, ~s(a[href*="scc_dev_channel=12345"]))

      backend = URI.encode_www_form(Endpoint.url())
      assert has_element?(view, ~s(a[href*="scc_dev_backend=#{backend}"]))

      # The link token verifies against our signer and is minted for the link's
      # channel, so channel-scoped GraphQL resolvers (which read the token's
      # channel_id claim) return the channel under test, not the admin's.
      [_, token] = Regex.run(~r/scc_dev_token=([A-Za-z0-9_.\-]+)/, html)
      assert {:ok, claims} = Twitch.Jwt.verify_and_validate(token)
      assert claims["channel_id"] == "12345"
    end

    test "prefixes scheme-less bases instead of silently using the default", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/local-extension-testing")

      view
      |> form("#local-dev-form", %{
        "local_base" => "localhost:9000",
        "manual_channel" => "42"
      })
      |> render_change()

      assert has_element?(view, ~s(a[href^="http://localhost:9000/?anchor="]))
    end

    test "falls back to the default base for non-http(s) input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/local-extension-testing")

      view
      |> form("#local-dev-form", %{
        "local_base" => "javascript:alert(1)",
        "manual_channel" => "12345"
      })
      |> render_change()

      # The unsafe scheme is never used as a link target; links use the default.
      refute has_element?(view, ~s(a[href^="javascript:"]))
      assert has_element?(view, ~s(a[href^="http://localhost:8080/?anchor=video_overlay"]))
    end

    test "reconstructs a clean origin, dropping userinfo/path/fragment", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/local-extension-testing")

      view
      |> form("#local-dev-form", %{
        "local_base" => "http://user@localhost:9000/some/path#frag",
        "manual_channel" => "999"
      })
      |> render_change()

      # Links use the clean scheme://host:port; userinfo/path/fragment are gone.
      assert has_element?(view, ~s(a[href^="http://localhost:9000/?anchor="]))
      refute has_element?(view, ~s(a[href*="user@"]))
      refute has_element?(view, ~s(a[href*="/some/path"]))
    end

    test "regenerate token re-renders without crashing", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/local-extension-testing")

      view |> element("button", "Regenerate token") |> render_click()

      assert has_element?(view, "textarea#socket_token")
    end
  end
end
