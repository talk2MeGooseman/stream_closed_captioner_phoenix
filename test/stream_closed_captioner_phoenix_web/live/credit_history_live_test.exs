defmodule StreamClosedCaptionerPhoenixWeb.CreditHistoryLiveTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import StreamClosedCaptionerPhoenix.Factory

  setup :register_and_log_in_user

  describe "mount" do
    test "renders credit history page with column headers", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/credit-history")

      assert html =~ "Action"
      assert html =~ "Amount"
      assert html =~ "Date"
    end

    test "renders with no transactions for a new user", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/credit-history")

      # Page should render without error; no transaction rows
      assert html =~ "Action"
    end

    test "shows bits transactions when user has purchase history", %{conn: conn, user: user} do
      insert(:bits_transaction, user: user, amount: 500)

      {:ok, _view, html} = live(conn, "/users/credit-history")

      assert html =~ "purchase"
      assert html =~ "500"
    end

    test "shows debit entries when user has been debited", %{conn: conn, user: user} do
      insert(:bits_balance_debit, user: user)

      {:ok, _view, html} = live(conn, "/users/credit-history")

      assert html =~ "debit"
    end
  end
end
