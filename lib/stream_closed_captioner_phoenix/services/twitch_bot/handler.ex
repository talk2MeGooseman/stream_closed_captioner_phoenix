defmodule TwitchBot.Handler do
  use TMI.Handler

  def connect(channels \\ []) do
    config = [
      user: "StreamClosedCaptioner",
      pass: System.get_env("TWITCH_CHAT_OAUTH"),
      chats: channels,
      handler: TwitchBot.Handler,
      capabilities: ['membership']
    ]

    TMI.supervisor_start_link(config)
  end

  @impl true
  # def handle_message("!" <> command, sender, chat) do
  #   case command do
  #     "dice" -> TMI.message(chat, Enum.random(~w(⚀ ⚁ ⚂ ⚃ ⚄ ⚅)))
  #     "echo " <> rest -> TMI.message(chat, rest)
  #     "dance" -> TMI.action(chat, "dances for #{sender}")
  #     _ -> TMI.message(chat, "unrecognized command")
  #   end
  # end

  def handle_message(message, sender, chat) do
    Logger.debug("Message in #{chat} from #{sender}: #{message}")
  end
end
