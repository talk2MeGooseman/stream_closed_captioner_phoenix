defmodule StreamClosedCaptionerPhoenixWeb.ActivePresence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence, otp_app: :stream_closed_captioner_phoenix,
                        pubsub_server: StreamClosedCaptionerPhoenix.PubSub
end
