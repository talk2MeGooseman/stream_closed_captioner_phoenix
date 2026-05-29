defmodule StreamClosedCaptionerPhoenixWeb.Admin.AdminLiveTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import StreamClosedCaptionerPhoenix.AccountsFixtures
  import StreamClosedCaptionerPhoenix.TranscriptsFixtures

  alias StreamClosedCaptionerPhoenix.Admin
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalance
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

  @admin_uid "120750024"

  defp log_in_admin(%{conn: conn}) do
    {:ok, admin} = Admin.update_user(user_fixture(), %{uid: @admin_uid})
    %{conn: log_in_user(conn, admin), admin: admin}
  end

  describe "access control" do
    test "redirects non-admin users away from the dashboard", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin")
    end

    test "redirects non-admin users away from a resource page", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/users")
    end
  end

  describe "dashboard" do
    setup :log_in_admin

    test "renders the admin dashboard with resource cards", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin")
      assert html =~ "Admin Dashboard"
      assert html =~ "Users"
      assert html =~ "Bits Balances"
      assert html =~ "User Tokens"
    end
  end

  describe "resource index pages" do
    setup :log_in_admin

    test "every index renders successfully", %{conn: conn} do
      for path <- [
            ~p"/admin/users",
            ~p"/admin/announcements",
            ~p"/admin/bits-balances",
            ~p"/admin/bits-transactions",
            ~p"/admin/bits-balance-debits",
            ~p"/admin/transcripts",
            ~p"/admin/messages",
            ~p"/admin/stream-settings",
            ~p"/admin/translate-languages",
            ~p"/admin/eventsub-subscriptions",
            ~p"/admin/user-tokens"
          ] do
        assert {:ok, _view, _html} = live(conn, path)
      end
    end
  end

  describe "new form modals render (regression: stateful component root tag)" do
    setup :log_in_admin

    test "the new form modal renders for every resource that has one", %{conn: conn} do
      for path <- [
            ~p"/admin/users/new",
            ~p"/admin/announcements/new",
            ~p"/admin/bits-balances/new",
            ~p"/admin/bits-transactions/new",
            ~p"/admin/bits-balance-debits/new",
            ~p"/admin/transcripts/new",
            ~p"/admin/messages/new",
            ~p"/admin/stream-settings/new",
            ~p"/admin/translate-languages/new",
            ~p"/admin/eventsub-subscriptions/new"
          ] do
        assert {:ok, _view, html} = live(conn, path)
        assert html =~ "</form>"
      end
    end
  end

  describe "edit form modals render (regression: stateful component root tag)" do
    setup :log_in_admin

    test "edit forms render without crashing", %{conn: conn, admin: admin} do
      bits_balance = Repo.get_by!(BitsBalance, user_id: admin.id)
      stream_settings = Repo.get_by!(StreamSettings, user_id: admin.id)
      transcript = transcript_fixture()
      message = message_fixture(%{transcript_id: transcript.id})
      {:ok, announcement} = Admin.create_announcement(%{"message" => "edit me"})

      for path <- [
            ~p"/admin/users/#{admin.id}/edit",
            ~p"/admin/announcements/#{announcement.id}/edit",
            ~p"/admin/bits-balances/#{bits_balance.id}/edit",
            ~p"/admin/transcripts/#{transcript.id}/edit",
            ~p"/admin/messages/#{message.id}/edit",
            ~p"/admin/stream-settings/#{stream_settings.id}/edit"
          ] do
        assert {:ok, _view, html} = live(conn, path)
        assert html =~ "</form>"
      end
    end
  end

  describe "announcement lifecycle" do
    setup :log_in_admin

    test "creates an announcement through the modal form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/announcements/new")

      view
      |> form("#announcement-form-modal form", announcement: %{message: "Brand new announcement"})
      |> render_submit()

      assert render(view) =~ "Brand new announcement"
      assert Admin.count_announcements() == 1
    end

    test "edits an announcement through the modal form", %{conn: conn} do
      {:ok, announcement} = Admin.create_announcement(%{"message" => "Original message"})

      {:ok, view, _html} = live(conn, ~p"/admin/announcements/#{announcement.id}/edit")

      view
      |> form("#announcement-form-modal form", announcement: %{message: "Updated message"})
      |> render_submit()

      assert Admin.get_announcement!(announcement.id).message == "Updated message"
    end

    test "deletes an announcement from the index", %{conn: conn} do
      {:ok, announcement} = Admin.create_announcement(%{"message" => "Delete this announcement"})

      {:ok, view, html} = live(conn, ~p"/admin/announcements")
      assert html =~ "Delete this announcement"

      view
      |> element("#announcement-#{announcement.id} button", "Delete")
      |> render_click()

      refute render(view) =~ "Delete this announcement"
      assert Admin.count_announcements() == 0
    end
  end

  describe "bits balance lifecycle" do
    setup :log_in_admin

    test "edits a bits balance through the modal form", %{conn: conn, admin: admin} do
      bits_balance = Repo.get_by!(BitsBalance, user_id: admin.id)

      {:ok, view, _html} = live(conn, ~p"/admin/bits-balances/#{bits_balance.id}/edit")

      view
      |> form("#bits-balance-form-modal form", bits_balance: %{balance: 999})
      |> render_submit()

      assert Admin.get_bits_balance!(bits_balance.id).balance == 999
    end
  end

  describe "user hub show page" do
    setup :log_in_admin

    test "lists all related records for a user", %{conn: conn, admin: admin} do
      {:ok, _view, html} = live(conn, ~p"/admin/users/#{admin.id}")

      assert html =~ "User Details"
      assert html =~ "Bits Balance"
      assert html =~ "Stream Settings"
      assert html =~ "Transcripts"
      assert html =~ "EventSub Subscriptions"
    end

    test "the inline edit modal renders", %{conn: conn, admin: admin} do
      {:ok, _view, html} = live(conn, ~p"/admin/users/#{admin.id}/show/edit")
      assert html =~ "Edit User"
      assert html =~ "</form>"
    end
  end

  describe "transcript show page" do
    setup :log_in_admin

    test "renders transcript details and its messages", %{conn: conn} do
      transcript = transcript_fixture()
      _message = message_fixture(%{transcript_id: transcript.id, text: "a captioned line"})

      {:ok, _view, html} = live(conn, ~p"/admin/transcripts/#{transcript.id}")

      assert html =~ "Transcript Details"
      assert html =~ "Messages"
      assert html =~ "a captioned line"
    end

    test "the inline edit modal renders", %{conn: conn} do
      transcript = transcript_fixture()

      {:ok, _view, html} = live(conn, ~p"/admin/transcripts/#{transcript.id}/show/edit")
      assert html =~ "Edit Transcript"
      assert html =~ "</form>"
    end
  end
end
