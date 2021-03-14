defmodule StreamClosedCaptionerPhoenixWeb.BitsBalanceDebitControllerTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenixWeb.ConnCase

  setup :register_and_log_in_user

  alias StreamClosedCaptionerPhoenix.Bits

  describe "index" do
    test "lists all bits_balance_debits", %{conn: conn} do
      conn = get(conn, Routes.bits_balance_debit_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Bits balance debits"
    end
  end

  describe "show bits_balance_debit" do
    setup [:create_bits_balance_debit]

    test "redirects to show when data is valid", %{
      conn: conn,
      bits_balance_debit: bits_balance_debit
    } do
      conn = get(conn, Routes.bits_balance_debit_path(conn, :show, bits_balance_debit.id))
      assert html_response(conn, 200) =~ "Show Bits balance debit"
    end
  end

  defp create_bits_balance_debit(%{user: user}) do
    bits_balance_debit = insert(:bits_balance_debit, user: user)
    %{bits_balance_debit: bits_balance_debit}
  end
end
