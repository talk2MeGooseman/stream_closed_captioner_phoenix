defmodule StreamClosedCaptionerPhoenixWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :stream_closed_captioner_phoenix
  use Absinthe.Phoenix.Endpoint

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_stream_closed_captioner_phoenix_key",
    signing_salt: System.get_env("COOKIE_SIGNING_SALT", "0JfoiBDr")
  ]

  # Origin checks for WS connections outside of app
  socket "/socket", StreamClosedCaptionerPhoenixWeb.UserSocket,
    websocket: [
      check_origin: [
        "//localhost:4000",
        "//h1ekceo16erc49snp0sine3k9ccbh9.ext-twitch.tv",
        "//localhost:8080",
        "//stream-cc.gooseman.codes"
      ]
    ],
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/kaffy",
    from: :kaffy,
    gzip: false,
    only: ~w(assets)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :stream_closed_captioner_phoenix,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :stream_closed_captioner_phoenix
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Custom parser for handling webhook body
  plug :parse_body

  opts = [
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  ]

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug StreamClosedCaptionerPhoenixWeb.Router

  @parser_without_cache Plug.Parsers.init(opts)
  @parser_with_cache Plug.Parsers.init([body_reader: {BodyReader, :cache_raw_body, []}] ++ opts)

  # All endpoints that start with "webhooks" have their body cached.
  defp parse_body(%{path_info: ["webhooks" | _]} = conn, _),
    do: Plug.Parsers.call(conn, @parser_with_cache)

  defp parse_body(conn, _),
    do: Plug.Parsers.call(conn, @parser_without_cache)
end
