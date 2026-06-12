defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddCaptionSourceTokenToStreamSettings do
  use Ecto.Migration

  def change do
    alter table(:stream_settings) do
      add :caption_source_token, :string
    end

    create unique_index(:stream_settings, [:caption_source_token])
  end
end
