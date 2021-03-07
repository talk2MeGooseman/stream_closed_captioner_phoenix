defmodule StreamClosedCaptionerPhoenixWeb.BitsBalanceDebitController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Bits

  def index(conn, _params) do
    user = conn.assigns.current_user

    bits_balance_debits = Bits.list_users_bits_balance_debits(user)
    render(conn, "index.html", bits_balance_debits: bits_balance_debits)
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    bits_balance_debit = Bits.get_users_bits_balance_debit!(user, id)
    render(conn, "show.html", bits_balance_debit: bits_balance_debit)
  end
end
