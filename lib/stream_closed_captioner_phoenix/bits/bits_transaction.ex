defmodule StreamClosedCaptionerPhoenix.Bits.BitsTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bits_transactions" do
    field :amount, :integer
    field :display_name, :string
    field :purchaser_uid, :string
    field :sku, :string
    field :time, :naive_datetime
    field :transaction_id, :string
    belongs_to :user, StreamClosedCaptionerPhoenix.Accounts.User
  end

  @doc false
  def changeset(bits_transaction, attrs) do
    bits_transaction
    |> cast(attrs, [
      :transaction_id,
      :user_id,
      :time,
      :purchaser_uid,
      :sku,
      :amount,
      :display_name
    ])
    |> unique_constraint(:transaction_id, name: "index_bits_transactions_on_transaction_id")
    |> validate_required([
      :transaction_id,
      :user_id,
      :time,
      :purchaser_uid,
      :sku,
      :amount,
      :display_name
    ])
  end
end
