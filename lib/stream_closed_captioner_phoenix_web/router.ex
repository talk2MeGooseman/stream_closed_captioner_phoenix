defmodule StreamClosedCaptionerPhoenixWeb.Router do
  use StreamClosedCaptionerPhoenixWeb, :router
  require Ueberauth

  import StreamClosedCaptionerPhoenixWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {StreamClosedCaptionerPhoenixWeb.Layouts, :root})
    plug(:protect_from_forgery)

    plug(:put_secure_browser_headers)

    plug(:fetch_current_user)
    plug(StreamClosedCaptionerPhoenixWeb.Maintenance)
    plug(:put_socket_token)
  end

  pipeline :logged_in do
    plug(:put_root_layout, {StreamClosedCaptionerPhoenixWeb.Layouts, :logged_in})
  end

  pipeline :admin_protected do
    plug(:fetch_current_user)
    plug(:redirect_if_not_admin)
  end

  pipeline :admin_layout do
    plug(:put_root_layout, {StreamClosedCaptionerPhoenixWeb.Layouts, :admin})
  end

  scope path: "/feature-flags" do
    pipe_through([:browser, :admin_protected])
    forward("/", FunWithFlags.UI.Router, namespace: "feature-flags")
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :webhook do
    plug(:accepts, ["json"])
    plug(StreamClosedCaptionerPhoenixWeb.HTTPSignature)
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
        "https://h1ekceo16erc49snp0sine3k9ccbh9.ext-twitch.tv",
        "https://talk2megooseman-stream-closed-captioner-phoenix-x66w-4000.githubpreview.dev"
      ]
    )
  end

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)

    forward("/graphiql", Absinthe.Plug.GraphiQL,
      schema: StreamClosedCaptionerPhoenixWeb.Schema,
      socket: StreamClosedCaptionerPhoenixWeb.UserSocket
    )
  end

  scope "/api" do
    pipe_through(:graphql)

    forward(
      "/",
      Absinthe.Plug,
      StreamClosedCaptionerPhoenixWeb.GqlConfig.configuration()
    )

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

    forward("/monitoring", HeartCheck.Plug,
      heartcheck: StreamClosedCaptionerPhoenixWeb.HeartCheck
    )
  end

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through(:webhook)

    post("/webhooks", WebhooksController, :create)
  end

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through(:browser)

    live_session :home,
      root_layout: {StreamClosedCaptionerPhoenixWeb.Layouts, :home_root},
      layout: false,
      on_mount: [{StreamClosedCaptionerPhoenixWeb.AdminHooks, :assign_current_user}] do
      live("/", PageLive, :index)
    end

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
      metrics: StreamClosedCaptionerPhoenixWeb.Telemetry
    )
  end

  scope "/admin", StreamClosedCaptionerPhoenixWeb.Admin, as: :admin do
    pipe_through([:browser, :admin_protected, :admin_layout])

    live_session :admin,
      root_layout: {StreamClosedCaptionerPhoenixWeb.Layouts, :admin},
      on_mount: [{StreamClosedCaptionerPhoenixWeb.AdminHooks, :assign_current_user}] do
      live("/", HomeLive, :index)

      live("/users", UserLive.Index, :index)
      live("/users/new", UserLive.Index, :new)
      live("/users/:id/edit", UserLive.Index, :edit)
      live("/users/:id", UserLive.Show, :show)
      live("/users/:id/show/edit", UserLive.Show, :edit)

      live("/announcements", AnnouncementLive.Index, :index)
      live("/announcements/new", AnnouncementLive.Index, :new)
      live("/announcements/:id/edit", AnnouncementLive.Index, :edit)

      live("/bits-balances", BitsBalanceLive.Index, :index)
      live("/bits-balances/new", BitsBalanceLive.Index, :new)
      live("/bits-balances/:id/edit", BitsBalanceLive.Index, :edit)

      live("/bits-transactions", BitsTransactionLive.Index, :index)
      live("/bits-transactions/new", BitsTransactionLive.Index, :new)
      live("/bits-transactions/:id/edit", BitsTransactionLive.Index, :edit)

      live("/bits-balance-debits", BitsBalanceDebitLive.Index, :index)
      live("/bits-balance-debits/new", BitsBalanceDebitLive.Index, :new)
      live("/bits-balance-debits/:id/edit", BitsBalanceDebitLive.Index, :edit)

      live("/transcripts", TranscriptLive.Index, :index)
      live("/transcripts/new", TranscriptLive.Index, :new)
      live("/transcripts/:id/edit", TranscriptLive.Index, :edit)
      live("/transcripts/:id", TranscriptLive.Show, :show)
      live("/transcripts/:id/show/edit", TranscriptLive.Show, :edit)

      live("/messages", MessageLive.Index, :index)
      live("/messages/new", MessageLive.Index, :new)
      live("/messages/:id/edit", MessageLive.Index, :edit)

      live("/stream-settings", StreamSettingsLive.Index, :index)
      live("/stream-settings/new", StreamSettingsLive.Index, :new)
      live("/stream-settings/:id/edit", StreamSettingsLive.Index, :edit)

      live("/translate-languages", TranslateLanguageLive.Index, :index)
      live("/translate-languages/new", TranslateLanguageLive.Index, :new)
      live("/translate-languages/:id/edit", TranslateLanguageLive.Index, :edit)

      live("/eventsub-subscriptions", EventsubSubscriptionLive.Index, :index)
      live("/eventsub-subscriptions/new", EventsubSubscriptionLive.Index, :new)
      live("/eventsub-subscriptions/:id/edit", EventsubSubscriptionLive.Index, :edit)

      live("/user-tokens", UserTokenLive.Index, :index)
    end
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
      delete("/register", UserRegistrationController, :delete)

      get("/settings", UserSettingsController, :edit)
      put("/settings", UserSettingsController, :update)
      get("/settings/confirm_email/:token", UserSettingsController, :confirm_email)

      live("/caption-settings", CaptionSettingsLive.Index, :show)
      live("/credit-history", CreditHistoryLive)
    end

    resources("/bits_balance_debits", BitsBalanceDebitController, only: [:index, :show])
    resources("/dashboard", DashboardController, only: [:index])
  end
end
