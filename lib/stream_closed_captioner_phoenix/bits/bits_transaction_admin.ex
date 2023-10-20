defmodule StreamClosedCaptionerPhoenix.Bits.BitsTransactionAdmin do
  alias StreamClosedCaptionerPhoenix.Accounts

  def search_fields(_schema) do
    [
      user: [:username, :purchaser_uid, :sku, :transaction_id]
    ]
  end

  def ordering(_schema) do
    [desc: :id]
  end

  def get_user(%{user_id: id}) do
    id
    |> Accounts.get_user!()
    |> Map.get(:username)
  end

  def index(_) do
    [
      id: nil,
      user_id: %{name: "User", value: fn p -> get_user(p) end},
      amount: nil,
      display_name: nil,
      purchaser_uid: nil,
      sku: nil,
      time: nil,
      transaction_id: nil
    ]
  end
end
