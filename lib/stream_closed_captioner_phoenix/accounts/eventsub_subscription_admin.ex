defmodule StreamClosedCaptionerPhoenix.Accounts.EventsubSubscriptionAdmin do
  alias StreamClosedCaptionerPhoenix.Accounts

  def search_fields(_schema) do
    [
      user: [:email, :username, :uid]
    ]
  end

  def widgets(_schema, _conn) do
    [
      %{
        type: "tidbit",
        title: "Active EventSub Subscriptions",
        content: Twitch.get_event_subscriptions("") |> Enum.count(),
        order: 1,
        width: 3,
        icon: ''
      }
    ]
  end

  def get_user(%{user_id: id}) do
    id
    |> Accounts.get_user!()
    |> Map.get(:username)
  end

  def index(_) do
    [
      user_id: %{name: "User", value: fn p -> get_user(p) end},
      subscription_id: nil,
      type: nil
    ]
  end
end
