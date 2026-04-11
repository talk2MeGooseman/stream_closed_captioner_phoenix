defmodule StreamClosedCaptionerPhoenix.AccountsAzureKeyTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  import StreamClosedCaptionerPhoenix.Factory
  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Audit

  describe "change_user_azure_key/2" do
    test "returns a user changeset" do
      user = insert(:user)
      assert %Ecto.Changeset{} = Accounts.change_user_azure_key(user)
    end
  end

  describe "update_user_azure_key/2" do
    test "updates the azure service key with valid hex format" do
      user = insert(:user)
      valid_key = "a1b2c3d4e5f6789012345678901234ab"

      assert {:ok, updated_user} =
               Accounts.update_user_azure_key(user, %{azure_service_key: valid_key})

      assert updated_user.azure_service_key == valid_key
    end

    test "validates azure service key minimum length" do
      user = insert(:user)

      assert {:error, changeset} =
               Accounts.update_user_azure_key(user, %{azure_service_key: "short"})

      assert "must be at least 10 characters" in errors_on(changeset).azure_service_key
    end

    test "validates azure service key maximum length" do
      user = insert(:user)
      long_key = String.duplicate("a", 257)

      assert {:error, changeset} =
               Accounts.update_user_azure_key(user, %{azure_service_key: long_key})

      assert "must be at most 256 characters" in errors_on(changeset).azure_service_key
    end

    test "validates azure service key format for 32-char hex" do
      user = insert(:user)
      valid_hex_key = "a1b2c3d4e5f6789012345678901234ab"

      assert {:ok, updated_user} =
               Accounts.update_user_azure_key(user, %{azure_service_key: valid_hex_key})

      assert updated_user.azure_service_key == valid_hex_key
    end

    test "validates azure service key format for base64-like strings" do
      user = insert(:user)
      valid_base64_key = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnop=="

      assert {:ok, updated_user} =
               Accounts.update_user_azure_key(user, %{azure_service_key: valid_base64_key})

      assert updated_user.azure_service_key == valid_base64_key
    end

    test "rejects keys with invalid format" do
      user = insert(:user)
      invalid_key = "invalid@key#format!"

      assert {:error, changeset} =
               Accounts.update_user_azure_key(user, %{azure_service_key: invalid_key})

      errors = errors_on(changeset).azure_service_key
      assert Enum.any?(errors, fn error -> 
        String.contains?(error, "does not match expected Azure API key format")
      end)
    end

    test "accepts empty azure service key to clear it" do
      user = insert(:user, azure_service_key: "existing-key")
      assert {:ok, updated_user} = Accounts.update_user_azure_key(user, %{azure_service_key: ""})
      assert updated_user.azure_service_key == nil
    end

    test "logs azure_key_created when key is added" do
      user = insert(:user)

      assert {:ok, _updated_user} =
               Accounts.update_user_azure_key(user, %{
                 azure_service_key: "a1b2c3d4e5f6789012345678901234ab"
               })

      logs = Audit.list_user_audit_logs(user.id)
      assert length(logs) == 1
      assert List.first(logs).action == "azure_key_created"
    end

    test "logs azure_key_updated when key is changed" do
      user = insert(:user, azure_service_key: "a1b2c3d4e5f6789012345678901234ab")

      assert {:ok, _updated_user} =
               Accounts.update_user_azure_key(user, %{
                 azure_service_key: "b2c3d4e5f6789012345678901234abcd"
               })

      logs = Audit.list_user_audit_logs(user.id)
      assert length(logs) == 1
      assert List.first(logs).action == "azure_key_updated"
    end

    test "logs azure_key_deleted when key is cleared" do
      user = insert(:user, azure_service_key: "existing-key")

      assert {:ok, _updated_user} =
               Accounts.update_user_azure_key(user, %{azure_service_key: ""})

      logs = Audit.list_user_audit_logs(user.id)
      assert length(logs) == 1
      assert List.first(logs).action == "azure_key_deleted"
    end
  end

  describe "clear_user_azure_key/1" do
    test "clears the azure service key and logs action" do
      user = insert(:user, azure_service_key: "existing-key")

      assert {:ok, updated_user} = Accounts.clear_user_azure_key(user)
      assert updated_user.azure_service_key == nil

      logs = Audit.list_user_audit_logs(user.id)
      assert length(logs) == 1
      assert List.first(logs).action == "azure_key_deleted"
    end
  end
end
