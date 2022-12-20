defmodule StreamClosedCaptionerPhoenix.Accounts.EventsubSubscriptionQueries do
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts.EventsubSubscription

  def all(query \\ base()), do: query

  def with_user_id(query \\ base(), user_id) do
    query
    |> where([eventsub_subscription], eventsub_subscription.user_id == ^user_id)
  end

  def with_id(query \\ base(), id) do
    query
    |> where([eventsub_subscription], eventsub_subscription.id == ^id)
  end

  def with_subscription_id(query \\ base(), subscription_id) do
    query
    |> where([eventsub_subscription], eventsub_subscription.subscription_id == ^subscription_id)
  end

  def with_type(query \\ base(), type) do
    query
    |> where([eventsub_subscription], eventsub_subscription.type == ^type)
  end

  defp base do
    from(_ in EventsubSubscription, as: :eventsub_subscription)
  end
end
