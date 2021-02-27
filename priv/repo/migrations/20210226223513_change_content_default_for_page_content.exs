defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.ChangeContentDefaultForPageContent do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:thesis_page_contents) do
      modify :content, :text, default: "", nil: false
    end
  end

  def down do
    alter table(:thesis_page_contents) do
      modify :content, :text, default: "Edit this content area", nil: true
    end
  end
end
