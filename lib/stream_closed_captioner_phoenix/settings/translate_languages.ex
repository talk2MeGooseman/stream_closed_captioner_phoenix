defmodule StreamClosedCaptionerPhoenix.Settings.TranslateLanguages do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translate_languages" do
    field :language, :string
    belongs_to :user, StreamClosedCaptionerPhoenix.Accounts.User

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(translate_languages, attrs) do
    translate_languages
    |> cast(attrs, [:user_id, :language])
    |> foreign_key_constraint(:user_id, name: "fk_rails_e519515539")
    |> validate_required([:user_id, :language])
    |> validate_inclusion(:language, StreamClosedCaptionerPhoenix.Settings.valid_language_codes())
  end

  @doc false
  def update_changeset(translate_languages, attrs) do
    translate_languages
    |> cast(attrs, [:language])
    |> validate_required([:language])
  end
end
