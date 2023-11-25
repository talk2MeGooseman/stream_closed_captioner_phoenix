defmodule StreamClosedCaptionerPhoenix.Jobs.SendChatReminderTest do
  import Mox
  use StreamClosedCaptionerPhoenix.DataCase, async: true
  use Oban.Testing, repo: StreamClosedCaptionerPhoenix.Repo

  alias StreamClosedCaptionerPhoenix.Jobs.SendChatReminder
  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  test "it sends a chat message to the broadcaster if the channel is not active" do
    Twitch.MockHelix
    |> expect(:send_extension_chat_message, fn _creds, "123", message ->
      assert message ==
               "Hey @talk2megooseman, here is your friendly reminder to turn on Stream Closed Captioner."

      {:ok, %{}}
    end)

    # Enqueue a job
    assert :ok =
             Oban.Testing.perform_job(
               SendChatReminder,
               %{broadcaster_user_id: "123", broadcaster_user_login: "talk2megooseman"},
               []
             )

    verify!()
  end

  test "it does not send a chat message to the broadcaster if the channel is active" do
    UserTracker.track(self(), "active_channels", "123", %{})

    # Enqueue a job
    assert :ok =
             Oban.Testing.perform_job(
               SendChatReminder,
               %{broadcaster_user_id: "123", broadcaster_user_login: "talk2megooseman"},
               []
             )
  end
end
