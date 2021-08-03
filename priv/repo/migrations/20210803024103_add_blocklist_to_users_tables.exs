defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddBlocklistToUsersTables do
  use Ecto.Migration

  def change do
    alter table(:stream_settings) do
      add :blocklist, {:array, :string}
    end
  end
end
