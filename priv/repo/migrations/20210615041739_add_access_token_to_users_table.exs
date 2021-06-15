defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.AddAccessTokenToUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :access_token, :string
      add :refresh_token, :string
    end
  end
end
