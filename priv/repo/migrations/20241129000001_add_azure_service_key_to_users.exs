defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddAzureServiceKeyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :azure_service_key, :string
    end
  end
end