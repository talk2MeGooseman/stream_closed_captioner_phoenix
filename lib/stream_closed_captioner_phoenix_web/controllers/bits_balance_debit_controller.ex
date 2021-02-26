defmodule StreamClosedCaptionerPhoenixWeb.BitsBalanceDebitController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Bits

  def index(conn, _params) do
    bits_balance_debits = Bits.list_bits_balance_debits()
    render(conn, "index.html", bits_balance_debits: bits_balance_debits)
  end

  def create(conn, %{"bits_balance_debit" => bits_balance_debit_params}) do
    case Bits.create_bits_balance_debit(bits_balance_debit_params) do
      {:ok, bits_balance_debit} ->
        conn
        |> put_flash(:info, "Bits balance debit created successfully.")
        |> redirect(to: Routes.bits_balance_debit_path(conn, :show, bits_balance_debit))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    bits_balance_debit = Bits.get_bits_balance_debit!(id)
    render(conn, "show.html", bits_balance_debit: bits_balance_debit)
  end
end
