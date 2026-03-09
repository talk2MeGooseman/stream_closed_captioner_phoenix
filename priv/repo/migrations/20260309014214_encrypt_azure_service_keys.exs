defmodule StreamClosedCaptionerPhoenix.Repo.Migrations.EncryptAzureServiceKeys do
  use Ecto.Migration

  def up do
    # Change column type from :string to :binary to store encrypted data
    # Use USING clause to convert existing data
    execute "ALTER TABLE users ALTER COLUMN azure_service_key TYPE bytea USING azure_service_key::bytea"
  end

  def down do
    # Revert back to string type
    # Note: This will lose any encrypted data
    execute "ALTER TABLE users ALTER COLUMN azure_service_key TYPE varchar USING encode(azure_service_key, 'escape')"
  end
end
