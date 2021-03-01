defmodule StreamClosedCaptionerPhoenix.Bits.BitsBalance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bits_balances" do
    field :total, :integer, source: :balance
    belongs_to :user, StreamClosedCaptionerPhoenix.Accounts.User

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(bits_balance, attrs) do
    bits_balance
    |> cast(attrs, [:user_id, :total])
    |> unique_constraint(:user_id, name: "index_bits_balances_on_user_id")
    |> validate_required([:user_id, :total])
  end

  @doc false
  def update_changeset(bits_balance, attrs) do
    bits_balance
    |> cast(attrs, [:total])
    |> validate_required([:total])
  end
end
