defmodule StreamClosedCaptionerPhoenix.Accounts.EventsubSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "eventsub_subscriptions" do
    field :subscription_id, :string
    field :type, :string
    belongs_to :user, StreamClosedCaptionerPhoenix.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(eventsub_subscription, attrs) do
    eventsub_subscription
    |> cast(attrs, [:type, :subscription_id, :user_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:subscription_id)
    |> validate_required([:type, :subscription_id, :user_id])
  end
end
