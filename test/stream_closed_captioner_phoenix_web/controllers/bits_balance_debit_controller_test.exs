defmodule StreamClosedCaptionerPhoenixWeb.BitsBalanceDebitControllerTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase

  alias StreamClosedCaptionerPhoenix.Bits

  @create_attrs %{amount: 42, user_id: 42}
  @update_attrs %{amount: 43, user_id: 43}
  @invalid_attrs %{amount: nil, user_id: nil}

  def fixture(:bits_balance_debit) do
    {:ok, bits_balance_debit} = Bits.create_bits_balance_debit(@create_attrs)
    bits_balance_debit
  end

  describe "index" do
    test "lists all bits_balance_debits", %{conn: conn} do
      conn = get(conn, Routes.bits_balance_debit_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Bits balance debits"
    end
  end

  describe "show bits_balance_debit" do
    setup [:create_bits_balance_debit]

    test "redirects to show when data is valid", %{conn: conn, bits_balance_debit: bits_balance_debit} do
      conn = get(conn, Routes.bits_balance_debit_path(conn, :show, bits_balance_debit.id))
      assert html_response(conn, 200) =~ "Show Bits balance debit"
    end
  end

  defp create_bits_balance_debit(_) do
    bits_balance_debit = fixture(:bits_balance_debit)
    %{bits_balance_debit: bits_balance_debit}
  end
end
