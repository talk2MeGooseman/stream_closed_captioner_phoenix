defmodule StreamClosedCaptionerPhoenixWeb.AuthAccessPipeline do
  use Guardian.Plug.Pipeline, otp_app: :stream_closed_captioner_phoenix

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true
end