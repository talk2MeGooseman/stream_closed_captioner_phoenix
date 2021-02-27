defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddTemplateAndRedirectUrlToThesisPages do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:thesis_pages) do
      add :template, :string
      add :redirect_url, :string
    end
  end
end
