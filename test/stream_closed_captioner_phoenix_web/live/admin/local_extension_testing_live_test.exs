defmodule StreamClosedCaptionerPhoenixWeb.Admin.LocalExtensionTestingLiveTest do
  # Not async: this module logs in by updating a fixture user to the shared,
  # unique admin uid, which would contend with other async admin tests doing
  # the same update.
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import StreamClosedCaptionerPhoenix.AccountsFixtures

  alias StreamClosedCaptionerPhoenix.Admin

  @admin_uid "120750024"

  # A JWT in the link fragment: scoped to `scc_dev_token=` so it can't be
  # satisfied by the unrelated `data-phx-session` token elsewhere in the page.
  @token_in_link ~r{scc_dev_token=[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+}

  defp log_in_admin(%{conn: conn}) do
    {:ok, admin} = Admin.update_user(user_fixture(), %{uid: @admin_uid})
    %{conn: log_in_user(conn, admin), admin: admin}
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
      {:ok, _view, html} = live(conn, ~p"/admin/local-extension-testing")

      assert html =~ "Local Extension Testing"
      assert html =~ "http://localhost:8080"
      assert html =~ "LOCAL_EXT_TESTING_ORIGINS"
      assert html =~ "No channels are currently captioning"
      assert html =~ "Socket token"
      assert html =~ ~s(id="socket_token")
    end

    test "builds dev links for a manually entered channel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/local-extension-testing")

      html =
        view
        |> form("#local-dev-form", %{
          "local_base" => "http://localhost:9000/",
          "manual_channel" => "  12345  "
        })
        |> render_change()

      # Base is normalized (trailing slash trimmed) and the link carries a real
      # minted JWT plus the (trimmed) channel id in the fragment.
      assert html =~ "http://localhost:9000/?anchor=video_overlay#scc_dev_token="
      assert html =~ "scc_dev_channel=12345"
      assert html =~ "anchor=mobile"
      assert Regex.match?(@token_in_link, html)

      # The token isn't just JWT-shaped — it actually verifies against our signer.
      [_, token] = Regex.run(~r/scc_dev_token=([A-Za-z0-9_.\-]+)/, html)
      assert {:ok, _claims} = Twitch.Jwt.verify_and_validate(token)
    end

    test "falls back to the default base for non-http(s) input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/local-extension-testing")

      html =
        view
        |> form("#local-dev-form", %{
          "local_base" => "javascript:alert(1)",
          "manual_channel" => "12345"
        })
        |> render_change()

      # The unsafe scheme is never used as a link target; links use the default.
      refute html =~ "javascript:alert(1)/?anchor="
      assert html =~ "http://localhost:8080/?anchor=video_overlay#scc_dev_token="
    end

    test "regenerate token re-renders without crashing", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/local-extension-testing")

      html = view |> element("button", "Regenerate token") |> render_click()

      assert html =~ "Socket token"
      assert html =~ ~s(id="socket_token")
    end
  end
end
