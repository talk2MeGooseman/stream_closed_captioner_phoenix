defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.CreateThesisTables do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:thesis_pages) do
      add :slug, :string
      add :title, :string
      add :description, :string

      timestamps()
    end

    create table(:thesis_page_contents) do
      add :page_id, :integer
      add :name, :string, nil: false
      add :content, :text,  default: "Edit this content area"
      add :content_type, :string, default: "html"

      timestamps
    end
  end
end
