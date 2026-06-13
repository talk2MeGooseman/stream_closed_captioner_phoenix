defmodule StreamClosedCaptionerPhoenix.Jobs.SendChatReminderTest do
  import Mox
  use StreamClosedCaptionerPhoenix.DataCase, async: true
  use Oban.Testing, repo: StreamClosedCaptionerPhoenix.Repo

  alias StreamClosedCaptionerPhoenix.Jobs.SendChatReminder
  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  setup do
    UserTracker.untrack(self(), "active_channels", "123")
  end

  # ---------------------------------------------------------------------------
  # Worker configuration assertions
  # These verify the module-level Oban options match the intended isolation
  # design, giving a clear failure message if someone accidentally reverts them.
  # ---------------------------------------------------------------------------

  describe "worker configuration" do
    test "routes jobs through the dedicated chat_reminders queue" do
      assert SendChatReminder.__opts__()[:queue] == :chat_reminders
    end

    test "limits retry attempts to 3" do
      assert SendChatReminder.__opts__()[:max_attempts] == 3
    end

    test "enforces uniqueness by args and queue to prevent duplicate reminders" do
      unique_opts = SendChatReminder.__opts__()[:unique]
      assert is_list(unique_opts), "expected unique opts to be present"
      assert :args in unique_opts[:fields], "expected :args to be a uniqueness field"
      assert :queue in unique_opts[:fields], "expected :queue to be a uniqueness field"
    end
  end

  # ---------------------------------------------------------------------------
  # perform/1 behavioural assertions
  # ---------------------------------------------------------------------------

  describe "perform/1" do
    test "sends a chat message to the broadcaster when the channel is not active" do
      Twitch.MockHelix
      |> expect(:send_extension_chat_message, fn _creds, "123", message ->
        assert message ==
                 "Hey @talk2megooseman, here is your friendly reminder to turn on Stream Closed Captioner."

        {:ok, %{}}
      end)

      assert :ok =
               Oban.Testing.perform_job(
                 SendChatReminder,
                 %{broadcaster_user_id: "123", broadcaster_user_login: "talk2megooseman"},
                 []
               )

      verify!()
    end

    test "does not send a chat message when the channel is already active" do
      UserTracker.track(self(), "active_channels", "123", %{
        last_publish: System.system_time(:second)
      })

      assert :ok =
               Oban.Testing.perform_job(
                 SendChatReminder,
                 %{broadcaster_user_id: "123", broadcaster_user_login: "talk2megooseman"},
                 []
               )
    end

    test "cancels the job without sending when there are prior errors" do
      # On a prior-error the worker returns {:cancel, reason} so Oban discards the job
      # rather than letting it exhaust all attempts with a known-bad state.
      assert {:cancel, _reason} =
               Oban.Testing.perform_job(
                 SendChatReminder,
                 %{broadcaster_user_id: "123", broadcaster_user_login: "talk2megooseman"},
                 errors: [
                   %{"attempt" => 1, "error" => "prior failure", "at" => DateTime.utc_now()}
                 ]
               )
    end
  end
end
