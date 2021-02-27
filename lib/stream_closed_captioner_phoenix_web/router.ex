defmodule StreamClosedCaptionerPhoenixWeb.Router do
  use StreamClosedCaptionerPhoenixWeb, :router
  use Kaffy.Routes, scope: "/admin", pipe_through: [:kaffy_browser]

  import StreamClosedCaptionerPhoenixWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {StreamClosedCaptionerPhoenixWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :kaffy_browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_authenticated do
    plug StreamClosedCaptionerPhoenixWeb.AuthAccessPipeline
  end

  pipeline :graphql do
    plug StreamClosedCaptionerPhoenixWeb.Context
  end

  scope "/api" do
    pipe_through :graphql

    forward "/", Absinthe.Plug, schema: StreamClosedCaptionerPhoenixWeb.Schema
  end

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through :browser

    live "/", PageLive, :index

    resources "/bits_balance_debits", BitsBalanceDebitController, only: [:index, :show]

    get "/privacy", PrivacyController, :index
    get "/terms", TermsController, :index
    get "/showcase", ShowcaseController, :index
    get "/supporters", SupportersController, :index

    get "/*path", PageController, :dynamic
  end

  # Other scopes may use custom stacks.
  # scope "/api", StreamClosedCaptionerPhoenixWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/live-dashboard",
        metrics: StreamClosedCaptionerPhoenixWeb.Telemetry,
        ecto_repos: [StreamClosedCaptionerPhoenix.Repo]
    end
  end

  ## Authentication routes

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated, :put_session_layout]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
    put "/users/settings/update_avatar", UserSettingsController, :update_avatar

    scope "/user/" do
      get "/stream_settings", StreamSettingsController, :edit
      put "/stream_settings", StreamSettingsController, :update
    end

    resources "/transcripts", TranscriptController, except: [:create, :new] do
      resources "/messages", MessageController, except: [:new, :create, :index]
    end

    get "/dashboard", DashboardController, :index
  end

  scope "/", StreamClosedCaptionerPhoenixWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  if Mix.env() == :dev do
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: StreamClosedCaptionerPhoenixWeb.Schema
  end

end
