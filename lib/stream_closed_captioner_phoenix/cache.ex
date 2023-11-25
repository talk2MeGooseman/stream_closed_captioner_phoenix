defmodule StreamClosedCaptionerPhoenix.Cache do
  use Nebulex.Cache,
    otp_app: :stream_closed_captioner_phoenix,
    adapter: Nebulex.Adapters.Local
end
