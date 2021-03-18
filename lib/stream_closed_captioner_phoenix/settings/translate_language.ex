defmodule StreamClosedCaptionerPhoenix.Settings.TranslateLanguage do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Repo

  schema "translate_languages" do
    field :language, :string
    belongs_to :user, StreamClosedCaptionerPhoenix.Accounts.User

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(translate_language, attrs) do
    translate_language
    |> cast(attrs, [:user_id, :language])
    |> foreign_key_constraint(:user_id, name: "fk_rails_e519515539")
    |> unique_constraint([:language, :user_id],
      name: "index_translate_languages_on_user_id_and_language"
    )
    |> validate_required([:user_id, :language])
    |> validate_inclusion(:language, StreamClosedCaptionerPhoenix.Settings.valid_language_codes())
    |> validate_language_count()
  end

  @doc false
  def update_changeset(translate_language, attrs) do
    translate_language
    |> cast(attrs, [:language])
    |> validate_required([:language])
    |> unique_constraint([:language, :user_id],
      name: "index_translate_languages_on_user_id_and_language"
    )
    |> validate_language_count()
    |> validate_inclusion(:language, StreamClosedCaptionerPhoenix.Settings.valid_language_codes())
  end

  @doc false
  defp validate_language_count(changeset) do
    %{user_id: user_id} = changeset.data

    count =
      StreamClosedCaptionerPhoenix.Settings.TranslateLanguage
      |> where(user_id: ^user_id)
      |> Repo.count()

    if count >= 3 do
      add_error(changeset, :user_id, "cannot have more than 3 languages")
    else
      changeset
    end
  end
end
