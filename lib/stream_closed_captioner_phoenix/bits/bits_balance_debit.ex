defmodule StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bits_balance_debits" do
    field :amount, :integer
    belongs_to :user, StreamClosedCaptionerPhoenix.Accounts.User

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(bits_balance_debit, attrs) do
    bits_balance_debit
    |> cast(attrs, [:user_id, :amount])
    |> validate_required([:user_id, :amount])
  end
end
