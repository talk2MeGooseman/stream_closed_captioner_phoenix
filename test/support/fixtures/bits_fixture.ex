defmodule StreamClosedCaptionerPhoenix.BitsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StreamClosedCaptionerPhoenix.Bits` context.
  """

  import StreamClosedCaptionerPhoenix.AccountsFixtures

  def bits_balance_fixture(attrs \\ %{}) do
    {:ok, bits_balance} =
      attrs
      |> Enum.into(%{
        total: 0,
        user_id: user_fixture().id
      })
      |> StreamClosedCaptionerPhoenix.Bits.create_bits_balance()

    bits_balance
  end

  def bits_transactions_fixture(attrs \\ %{}) do
    {:ok, bits_transactions} =
      attrs
      |> Enum.into(%{
        amount: 42,
        display_name: "some display_name",
        purchaser_uid: "some purchaser_uid",
        sku: "some sku",
        time: ~N[2010-04-17 14:00:00],
        transaction_id: "some transaction_id",
        user_id: user_fixture().id
      })
      |> StreamClosedCaptionerPhoenix.Bits.create_bits_transactions()

    bits_transactions
  end
end
