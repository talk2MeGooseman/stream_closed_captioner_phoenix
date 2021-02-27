defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddIndexToTables do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:thesis_pages) do
      modify :title,        :string, size: 512
      modify :description,  :string, size: 1024
    end

    # Index page slugs, since we're searching on those
    create index(:thesis_pages, [:slug])

    # Create foreign key constraint for page_contents -> page
    alter table(:thesis_page_contents) do
      modify :page_id, references(:thesis_pages, on_delete: :delete_all)
    end
  end

  def down do
    alter table(:thesis_pages) do
      modify :title,        :string
      modify :description,  :string
    end

    remove index(:thesis_pages, [:slug])
  end
end
