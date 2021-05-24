defmodule StreamClosedCaptionerPhoenixWeb.Router do
  use StreamClosedCaptionerPhoenixWeb, :router
  use Kaffy.Routes, scope: "/admin", pipe_through: [:admin_protected]
  require Ueberauth

  import StreamClosedCaptionerPhoenixWeb.UserAuth

  use BoomNotifier,
    notifier: BoomNotifier.MailNotifier,
    notification_trigger: :exponential,
    options: [
      mailer: StreamClosedCaptionerPhoenix.Mailer,
      from: "erik.guzman@guzman.codes",
      to: "erik.guzman@guzman.codes",
      subject: "BOOM error caught"
    ]

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {StreamClosedCaptionerPhoenixWeb.LayoutView, :root})
    plug(:protect_from_forgery)

    plug(:put_secure_browser_headers)

    plug(:fetch_current_user)
    plug(StreamClosedCaptionerPhoenixWeb.Maintenance)
    plug(:put_socket_token)
  end

  pipeline :logged_in do
    plug(:put_root_layout, {StreamClosedCaptionerPhoenixWeb.LayoutView, :logged_in})
  end

  pipeline :admin_protected do
    plug(:fetch_current_user)
    plug(:redirect_if_not_admin)
  end

  pipeline :kaffy_browser do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :mounted_apps do
    plug(:accepts, ["html"])
    plug(:put_secure_browser_headers)
  end

  scope path: "/feature-flags" do
    pipe_through(:mounted_apps)
    forward("/", FunWithFlags.UI.Router, namespace: "feature-flags")
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :api_authenticated do
    plug(StreamClosedCaptionerPhoenixWeb.AuthAccessPipeline)
  end

  pipeline :graphql do
    # Gets user and validates token
    plug(StreamClosedCaptionerPhoenixWeb.Context)

    plug(CORSPlug,
      origin: [
        "http://localhost:4000",
        "https://localhost:4000",
        "https://localhost:8080",
        "http://localhost:8080",
        "https://h1ekceo16erc49snp0sine3k9ccbh9.ext-twitch.tv"
      ]
    )
  end

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
    forward("/graphiql", Absinthe.Plug.GraphiQL, schema: StreamClosedCaptionerPhoenixWeb.Schema)
  end

  scope "/api" do
    pipe_through(:graphql)

    forward("/", Absinthe.Plug, schema: StreamClosedCaptionerPhoenixWeb.Schema)
    options("/", Absinthe.Plug, :options)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    scope "/" do
      pipe_through(:browser)
    end
  end

  scope "/" do
    pipe_through(:browser)

    forward("/monitoring", HeartCheck.Plug, heartcheck: StreamClosedCaptionerPhoenixWeb.HeartCheck)
  end

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through(:browser)

    live("/", PageLive, :index)

    get("/privacy", PrivacyController, :index)
    get("/terms", TermsController, :index)
    get("/showcase", ShowcaseController, :index)
    get("/supporters", SupportersController, :index)
    get("/announcements", AnnouncementsController, :index)

    delete("/users/log_out", UserSessionController, :delete)
    get("/users/confirm", UserConfirmationController, :new)
    post("/users/confirm", UserConfirmationController, :create)
    get("/users/confirm/:token", UserConfirmationController, :confirm)
  end

  ## Authentication routes

  import Phoenix.LiveDashboard.Router

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through([:browser, :admin_protected])

    live_dashboard("/live-dashboard",
      ecto_repos: [StreamClosedCaptionerPhoenix.Repo],
      metrics: StreamClosedCaptionerPhoenixWeb.Telemetry,
      metrics_history: {StreamClosedCaptionerPhoenix.MyStorage, :metrics_history, []}
    )
  end

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated, :put_session_layout])

    get("/users/register", UserRegistrationController, :new)
    post("/users/register", UserRegistrationController, :create)
    get("/users/log_in", UserSessionController, :new)
    post("/users/log_in", UserSessionController, :create)
    get("/users/reset_password", UserResetPasswordController, :new)
    post("/users/reset_password", UserResetPasswordController, :create)
    get("/users/reset_password/:token", UserResetPasswordController, :edit)
    put("/users/reset_password/:token", UserResetPasswordController, :update)
  end

  scope "/auth", StreamClosedCaptionerPhoenixWeb do
    pipe_through([:browser, :put_session_layout])

    get("/:provider", UserSessionController, :request)
    get("/:provider/callback", UserSessionController, :callback)
  end

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through([:browser, :require_authenticated_user, :logged_in])

    scope "/users/" do
      get("/stream_settings", StreamSettingsController, :edit)
      put("/stream_settings", StreamSettingsController, :update)

      delete("/register", UserRegistrationController, :delete)

      get("/settings", UserSettingsController, :edit)
      put("/settings", UserSettingsController, :update)
      get("/settings/confirm_email/:token", UserSettingsController, :confirm_email)

      live("/captions-settings", StreamSettingsLive.Index, :update)
    end

    resources "/transcripts", TranscriptController, except: [:create, :new] do
      resources("/messages", MessageController, except: [:new, :create, :index])
    end

    resources("/bits_balance_debits", BitsBalanceDebitController, only: [:index, :show])
    resources("/dashboard", DashboardController, only: [:index])
  end
end
