defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.CreateThesisBackupsTable do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:thesis_backups) do
      add :page_id, references(:thesis_pages, on_delete: :delete_all)
      add :page_revision, :integer
      add :page_data, :binary

      timestamps()
    end
  end
end
