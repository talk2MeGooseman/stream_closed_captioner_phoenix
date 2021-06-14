defmodule StreamClosedCaptionerPhoenix.Bits.BitsBalanceAdmin do
  alias StreamClosedCaptionerPhoenix.Accounts

  def search_fields(_schema) do
    [
      user: [:email, :username, :uid]
    ]
  end

  def ordering(_schema) do
    [desc: :updated_at]
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
      balance: nil,
      created_at: nil,
      updated_at: nil
    ]
  end
end
