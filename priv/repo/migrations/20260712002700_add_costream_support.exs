defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddCostreamSupport do
  use Ecto.Migration

  def change do
    create table(:costream_guests) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :muted, :boolean, default: false, null: false
      add :revoked_at, :utc_datetime

      timestamps()
    end

    create index(:costream_guests, [:user_id])

    alter table(:stream_settings) do
      add :costream_enabled, :boolean, default: true, null: false
    end
  end
end
