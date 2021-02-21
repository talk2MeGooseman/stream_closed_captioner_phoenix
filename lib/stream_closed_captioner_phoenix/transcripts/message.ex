defmodule StreamClosedCaptionerPhoenix.Transcripts.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :text, :string
    belongs_to :transcript, StreamClosedCaptionerPhoenix.Transcripts.Transcript

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:transcript_id, :text])
    |> foreign_key_constraint(:transcript_id, [name: "fk_rails_832df11d70"])
    |> validate_required([:transcript_id, :text])
  end

  @doc false
  def update_changeset(message, attrs) do
    message
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end
end
