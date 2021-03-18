defmodule StreamClosedCaptionerPhoenix.Repo do
  use EctoExtras.Repo
  use Ecto.Repo,
    otp_app: :stream_closed_captioner_phoenix,
    adapter: Ecto.Adapters.Postgres
end
