defmodule StreamClosedCaptionerPhoenixWeb.GraphQL.ChannelInfoCostreamTest do
  # async: false because FunWithFlags keeps flag state in a shared in-memory cache.
  use StreamClosedCaptionerPhoenix.DataCase, async: false

  alias StreamClosedCaptionerPhoenix.Costream
  alias StreamClosedCaptionerPhoenixWeb.Schema

  import StreamClosedCaptionerPhoenix.Factory

  @query """
  query ChannelInfo($id: ID!) {
    channelInfo(id: $id) {
      costreamEnabled
    }
  }
  """

  setup do
    # DB toggle rows roll back with the sandbox; flush only the shared cache.
    on_exit(fn -> FunWithFlags.Store.Cache.flush() end)
    %{user: insert(:user, provider: "twitch")}
  end

  defp run_query(user) do
    {:ok, result} =
      Absinthe.run(@query, Schema,
        context: %{decoded_token: %{"channel_id" => user.uid}},
        variables: %{"id" => user.uid}
      )

    result
  end

  test "is false for channels outside the rollout", %{user: user} do
    FunWithFlags.disable(Costream.feature_flag())

    result = run_query(user)
    assert result[:errors] == nil
    assert result.data["channelInfo"]["costreamEnabled"] == false
  end

  test "is true when the flag is enabled for the channel", %{user: user} do
    FunWithFlags.disable(Costream.feature_flag())
    FunWithFlags.enable(Costream.feature_flag(), for_actor: user)

    assert run_query(user).data["channelInfo"]["costreamEnabled"] == true
  end

  test "ignores the host's live kill switch", %{user: user} do
    FunWithFlags.enable(Costream.feature_flag(), for_actor: user)

    StreamClosedCaptionerPhoenix.Settings.update_stream_settings(user.stream_settings, %{
      costream_enabled: false
    })

    assert run_query(user).data["channelInfo"]["costreamEnabled"] == true
  end
end
