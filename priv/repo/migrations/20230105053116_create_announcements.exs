defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.CreateAnnouncements do
  use Ecto.Migration

  def change do
    create table(:announcements) do
      add :message, :text
      add :display, :boolean, default: false
    end
  end
end
