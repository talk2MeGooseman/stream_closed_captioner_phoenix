defmodule StreamClosedCaptionerPhoenix.Bits.BitsBalance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bits_balances" do
    field :balance, :integer, default: 0
    belongs_to :user, StreamClosedCaptionerPhoenix.Accounts.User

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(bits_balance, attrs) do
    bits_balance
    |> cast(attrs, [:user_id, :balance])
    |> foreign_key_constraint(:user_id, name: "fk_rails_1a2fa97ecf")
    |> unique_constraint(:user_id, name: "index_bits_balances_on_user_id")
    |> validate_required([:user_id])
  end

  @doc false
  def update_changeset(bits_balance, attrs) do
    bits_balance
    |> cast(attrs, [:balance])
    |> validate_required([:balance])
  end
end
