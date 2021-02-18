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

  describe "new bits_balance_debit" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.bits_balance_debit_path(conn, :new))
      assert html_response(conn, 200) =~ "New Bits balance debit"
    end
  end

  describe "create bits_balance_debit" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.bits_balance_debit_path(conn, :create), bits_balance_debit: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.bits_balance_debit_path(conn, :show, id)

      conn = get(conn, Routes.bits_balance_debit_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Bits balance debit"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.bits_balance_debit_path(conn, :create), bits_balance_debit: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Bits balance debit"
    end
  end

  describe "edit bits_balance_debit" do
    setup [:create_bits_balance_debit]

    test "renders form for editing chosen bits_balance_debit", %{conn: conn, bits_balance_debit: bits_balance_debit} do
      conn = get(conn, Routes.bits_balance_debit_path(conn, :edit, bits_balance_debit))
      assert html_response(conn, 200) =~ "Edit Bits balance debit"
    end
  end

  describe "update bits_balance_debit" do
    setup [:create_bits_balance_debit]

    test "redirects when data is valid", %{conn: conn, bits_balance_debit: bits_balance_debit} do
      conn = put(conn, Routes.bits_balance_debit_path(conn, :update, bits_balance_debit), bits_balance_debit: @update_attrs)
      assert redirected_to(conn) == Routes.bits_balance_debit_path(conn, :show, bits_balance_debit)

      conn = get(conn, Routes.bits_balance_debit_path(conn, :show, bits_balance_debit))
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, bits_balance_debit: bits_balance_debit} do
      conn = put(conn, Routes.bits_balance_debit_path(conn, :update, bits_balance_debit), bits_balance_debit: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Bits balance debit"
    end
  end

  describe "delete bits_balance_debit" do
    setup [:create_bits_balance_debit]

    test "deletes chosen bits_balance_debit", %{conn: conn, bits_balance_debit: bits_balance_debit} do
      conn = delete(conn, Routes.bits_balance_debit_path(conn, :delete, bits_balance_debit))
      assert redirected_to(conn) == Routes.bits_balance_debit_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.bits_balance_debit_path(conn, :show, bits_balance_debit))
      end
    end
  end

  defp create_bits_balance_debit(_) do
    bits_balance_debit = fixture(:bits_balance_debit)
    %{bits_balance_debit: bits_balance_debit}
  end
end
