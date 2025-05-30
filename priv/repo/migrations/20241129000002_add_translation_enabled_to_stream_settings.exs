defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddTranslationEnabledToStreamSettings do
  use Ecto.Migration

  def change do
    alter table(:stream_settings) do
      add :translation_enabled, :boolean, default: false
    end
  end
end