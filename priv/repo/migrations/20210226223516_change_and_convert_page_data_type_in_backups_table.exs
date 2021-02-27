defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.ChangeAndConvertPageDataTypeInBackupsTable do
  @moduledoc false
  use Ecto.Migration
  alias Thesis.Backup
  import Thesis.Config
  import Ecto.Changeset, only: [change: 1, force_change: 3]

  def change do
    case convert_and_map_page_data() do
      {:ok, backups} -> execute_migration(backups)
      _ -> raise "Something went wrong with backup conversion. Please check \
                  your thesis_backups table and re-run the migration."
    end
  end

  def convert_and_map_page_data() do
    backups = Enum.map(backups(), fn(b) ->
      %{b | page_data: decompress_page_data(b.page_data)}
    end)

    {:ok, backups}
  end

  def execute_migration(backups) do
    alter table(:thesis_backups) do
      modify :page_data, :text
    end

    flush()

    save_converted_page_data(backups)
  end

  def backups() do
    Thesis.Config.repo().all(Backup)
  end

  def decompress_page_data(page_data) do
    try do
      LZString.decompress(page_data)
    rescue
      _ -> page_data
    end
  end

  def save_converted_page_data(backups) do
    backups
    |> Enum.map(fn(b) -> conversion_changeset(b, :page_data, b.page_data) end)
    |> Enum.map(fn(b) -> Thesis.Config.repo().update!(b) end)
  end

  def conversion_changeset(backup, key, value) do
    backup
    |> change
    |> force_change(key, value)
  end

end
