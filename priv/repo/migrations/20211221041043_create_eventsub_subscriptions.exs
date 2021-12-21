defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.CreateEventsubSubscriptions do
  use Ecto.Migration

  def change do
    create table(:eventsub_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :type, :string
      add :subscription_id, :string

      timestamps()
    end

    create unique_index(:eventsub_subscriptions, [:subscription_id])
  end
end
