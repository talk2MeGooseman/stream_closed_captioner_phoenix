defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :action, :string, null: false
      add :resource_type, :string, null: false
      add :resource_id, :integer
      add :metadata, :map, default: %{}
      add :ip_address, :string
      add :user_agent, :string

      timestamps(updated_at: false, inserted_at: :created_at)
    end

    create index(:audit_logs, [:user_id])
    create index(:audit_logs, [:action])
    create index(:audit_logs, [:resource_type])
    create index(:audit_logs, [:created_at])
  end
end
