defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.AccountsTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  alias StreamClosedCaptionerPhoenixWeb.Resolvers

  import StreamClosedCaptionerPhoenix.Factory

  describe "get_me/3" do
    test "returns current_user from context without a DB re-fetch" do
      user = insert(:user)
      resolution = %{context: %{current_user: user}}

      assert {:ok, returned_user} = Resolvers.Accounts.get_me(nil, %{}, resolution)
      assert returned_user.id == user.id
    end

    test "returns error when current_user is nil in context" do
      resolution = %{context: %{current_user: nil}}
      assert {:error, _msg} = Resolvers.Accounts.get_me(nil, %{}, resolution)
    end

    test "returns error when current_user is missing from context" do
      assert {:error, _msg} = Resolvers.Accounts.get_me(nil, %{}, %{context: %{}})
    end

    test "does not accept a non-User struct as current_user" do
      resolution = %{context: %{current_user: %{id: 1}}}
      assert {:error, _msg} = Resolvers.Accounts.get_me(nil, %{}, resolution)
    end
  end
end
