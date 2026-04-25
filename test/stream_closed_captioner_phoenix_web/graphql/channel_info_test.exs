defmodule StreamClosedCaptionerPhoenixWeb.GraphQL.ChannelInfoTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  alias StreamClosedCaptionerPhoenixWeb.Schema

  import StreamClosedCaptionerPhoenix.Factory

  # schema.context/1 is called by Absinthe.run/3 and sets up the loader,
  # so only decoded_token needs to be set here.
  defp graphql_context(uid) do
    %{decoded_token: %{"channel_id" => uid}}
  end

  @query """
  query ChannelInfo($id: ID!) {
    channelInfo(id: $id) {
      uid
      bitsBalance {
        balance
      }
    }
  }
  """

  describe "channelInfo query" do
    test "returns uid and bits_balance for a channel using Dataloader" do
      user = insert(:user, provider: "twitch")

      {:ok, result} =
        Absinthe.run(@query, Schema,
          context: graphql_context(user.uid),
          variables: %{"id" => user.uid}
        )

      refute Map.has_key?(result, :errors)
      assert result.data["channelInfo"]["uid"] == user.uid
      assert result.data["channelInfo"]["bitsBalance"]["balance"] == user.bits_balance.balance
    end

    test "returns error when channel is not found" do
      # get_channel_info/3 uses decoded_token["channel_id"], not the GraphQL id arg
      {:ok, result} =
        Absinthe.run(@query, Schema,
          context: graphql_context("nonexistent_uid_xyz"),
          variables: %{"id" => "nonexistent_uid_xyz"}
        )

      assert [%{message: "Channel nonexistent_uid_xyz not found"}] = result[:errors]
    end

    test "returns access denied without decoded_token in context" do
      user = insert(:user)

      {:ok, result} =
        Absinthe.run(@query, Schema,
          context: %{},
          variables: %{"id" => user.uid}
        )

      assert [%{message: msg}] = result[:errors]
      assert msg =~ "Access denied"
    end
  end
end
