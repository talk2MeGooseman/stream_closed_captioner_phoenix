defmodule StreamClosedCaptionerPhoenix.AccountsAzureKeyTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: true
  
  import StreamClosedCaptionerPhoenix.Factory
  alias StreamClosedCaptionerPhoenix.Accounts

  describe "change_user_azure_key/2" do
    test "returns a user changeset" do
      user = insert(:user)
      assert %Ecto.Changeset{} = Accounts.change_user_azure_key(user)
    end
  end

  describe "update_user_azure_key/2" do
    test "updates the azure service key" do
      user = insert(:user)
      assert {:ok, updated_user} = Accounts.update_user_azure_key(user, %{azure_service_key: "test-key-123"})
      assert updated_user.azure_service_key == "test-key-123"
    end

    test "validates azure service key length" do
      user = insert(:user)
      assert {:error, changeset} = Accounts.update_user_azure_key(user, %{azure_service_key: "short"})
      assert "should be between 10 and 256 characters" in errors_on(changeset).azure_service_key
    end

    test "accepts empty azure service key to clear it" do
      user = insert(:user, azure_service_key: "existing-key")
      assert {:ok, updated_user} = Accounts.update_user_azure_key(user, %{azure_service_key: ""})
      assert updated_user.azure_service_key == nil
    end
  end
end