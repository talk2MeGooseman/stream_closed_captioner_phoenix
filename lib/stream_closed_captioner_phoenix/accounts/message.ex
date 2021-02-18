defmodule StreamClosedCaptionerPhoenix.Accounts.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :text, :string
    field :transcript_id, :integer

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:transcript_id, :text])
    |> validate_required([:transcript_id, :text])
  end
end
