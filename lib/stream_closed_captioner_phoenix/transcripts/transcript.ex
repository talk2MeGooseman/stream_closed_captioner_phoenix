defmodule StreamClosedCaptionerPhoenix.Transcripts.Transcript do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transcripts" do
    field :name, :string
    field :session, :string

    belongs_to :user, StreamClosedCaptionerPhoenix.Accounts.User
    has_many :messages, StreamClosedCaptionerPhoenix.Transcripts.Message

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(transcript, attrs) do
    transcript
    |> cast(attrs, [:user_id, :name, :session])
    |> foreign_key_constraint(:user_id, [name: "fk_rails_d177bec369"])
    |> validate_required([:user_id, :name, :session])
  end

  @doc false
  def update_changeset(transcript, attrs) do
    transcript
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
