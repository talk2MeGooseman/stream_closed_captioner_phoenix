defmodule StreamClosedCaptionerPhoenixWeb.CORS do
  @moduledoc """
  Runtime origin allowlist for the GraphQL HTTP pipeline.

  CORSPlug options in the router are evaluated at compile time, so origins that
  depend on runtime config — the admin-only `LOCAL_EXT_TESTING_ORIGINS` used by
  the local extension testing page — are resolved here via a function CORSPlug
  calls per request. This keeps the websocket `check_origin` allowlist and the
  HTTP CORS allowlist in sync: a local dev build that can open the captions
  websocket can also run its GraphQL queries.
  """

  @static_origins [
    "http://localhost:4000",
    "https://localhost:4000",
    "https://localhost:8080",
    "http://localhost:8080",
    "https://h1ekceo16erc49snp0sine3k9ccbh9.ext-twitch.tv",
    "https://talk2megooseman-stream-closed-captioner-phoenix-x66w-4000.githubpreview.dev"
  ]

  def allowed_origins do
    @static_origins ++
      Application.get_env(:stream_closed_captioner_phoenix, :local_ext_testing_origins, [])
  end
end
