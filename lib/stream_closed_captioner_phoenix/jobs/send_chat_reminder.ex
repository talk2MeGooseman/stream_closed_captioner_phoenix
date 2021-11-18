defmodule StreamClosedCaptionerPhoenix.Jobs.SendChatReminder do
  use Oban.Worker, queue: :default

  # %{channel: "talk2megooseman"}
  # |> StreamClosedCaptionerPhoenix.Jobs.SendChatReminder.new(schedule_in: 10)
  # |> Oban.insert()

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"channel" => channel}}) do
    # Check if channel has Stream CC active
    # If not, connect with TwitchBot
    TwitchBot.connect_to(channel)
    # and send reminder to channel
    # TwitchBot.say(
    #   channel,
    #   "Hey @#{channel}, here is your friendly reminder to turn on Stream Closed Captioner."
    # )
  end
end
