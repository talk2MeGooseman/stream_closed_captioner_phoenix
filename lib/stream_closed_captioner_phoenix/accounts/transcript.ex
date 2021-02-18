defmodule StreamClosedCaptionerPhoenix.Accounts.Transcript do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transcripts" do
    field :name, :string
    field :session, :string
    field :user_id, :integer
    has_many :messages, StreamClosedCaptionerPhoenix.Accounts.Message

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(transcript, attrs) do
    transcript
    |> cast(attrs, [:user_id, :name, :session])
    |> validate_required([:user_id, :name, :session])
  end
end
