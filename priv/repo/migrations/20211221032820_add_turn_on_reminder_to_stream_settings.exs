defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddTurnOnReminderToStreamSettings do
  use Ecto.Migration

  def change do
    alter table(:stream_settings) do
      add :turn_on_reminder, :boolean, default: false
    end
  end
end
