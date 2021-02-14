defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddFileToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :avatar, :string
    end
  end
end