defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddAutoOffCaptionsToUserSettings do
  use Ecto.Migration

  def change do
    alter table(:stream_settings) do
      add :auto_off_captions, :boolean, default: false
    end
  end
end
