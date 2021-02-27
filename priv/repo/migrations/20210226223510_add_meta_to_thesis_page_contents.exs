defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddMetaToThesisPageContents do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:thesis_page_contents) do
      add :meta, :text
    end
  end
end
