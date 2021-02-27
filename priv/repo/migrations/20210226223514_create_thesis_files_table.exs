defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.CreateThesisFilesTable do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:thesis_files) do
      add :slug, :string
      add :content_type, :string
      add :filename, :string
      add :data, :binary

      timestamps()
    end
    create unique_index(:thesis_files, [:slug])
  end
end
