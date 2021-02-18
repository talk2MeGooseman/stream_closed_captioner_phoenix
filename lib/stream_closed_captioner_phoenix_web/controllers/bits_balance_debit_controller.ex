defmodule StreamClosedCaptionerPhoenixWeb.BitsBalanceDebitController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit

  def index(conn, _params) do
    bits_balance_debits = Bits.list_bits_balance_debits()
    render(conn, "index.html", bits_balance_debits: bits_balance_debits)
  end

  def new(conn, _params) do
    changeset = Bits.change_bits_balance_debit(%BitsBalanceDebit{})
    render(conn, "new.html", changeset: changeset)
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

  def edit(conn, %{"id" => id}) do
    bits_balance_debit = Bits.get_bits_balance_debit!(id)
    changeset = Bits.change_bits_balance_debit(bits_balance_debit)
    render(conn, "edit.html", bits_balance_debit: bits_balance_debit, changeset: changeset)
  end

  def update(conn, %{"id" => id, "bits_balance_debit" => bits_balance_debit_params}) do
    bits_balance_debit = Bits.get_bits_balance_debit!(id)

    case Bits.update_bits_balance_debit(bits_balance_debit, bits_balance_debit_params) do
      {:ok, bits_balance_debit} ->
        conn
        |> put_flash(:info, "Bits balance debit updated successfully.")
        |> redirect(to: Routes.bits_balance_debit_path(conn, :show, bits_balance_debit))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", bits_balance_debit: bits_balance_debit, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    bits_balance_debit = Bits.get_bits_balance_debit!(id)
    {:ok, _bits_balance_debit} = Bits.delete_bits_balance_debit(bits_balance_debit)

    conn
    |> put_flash(:info, "Bits balance debit deleted successfully.")
    |> redirect(to: Routes.bits_balance_debit_path(conn, :index))
  end
end
