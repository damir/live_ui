defmodule LiveUIWeb.Router do
  use LiveUIWeb, :router

  import LiveUIWeb.UserAuth
  import LiveUI.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug Cldr.Plug.AcceptLanguage, cldr_backend: LiveUI.Cldr
    plug Cldr.Plug.PutLocale, apps: [cldr: LiveUI.Cldr, gettext: LiveUIWeb.Gettext]
    plug Cldr.Plug.PutSession, as: :string
    plug :fetch_live_flash
    plug :put_root_layout, {LiveUIWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", LiveUIWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveUIWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:live_ui, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: LiveUIWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ### public
  scope "/", LiveUIWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LiveUIWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live("/users/register", UserRegistrationLive, :new)
      live("/users/log_in", UserLoginLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/log_in", UserSessionController, :create)
  end

  ### member
  scope "/", LiveUIWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [{LiveUIWeb.UserAuth, :ensure_authenticated}] do
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)

      # live ui
      scope "/member", Member do
        live_ui("/contacts", ContactLive, LiveUI.Member.Contact)
      end
    end
  end

  ### admin
  scope "/admin", LiveUIWeb.Admin do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_admin_user,
      on_mount: [{LiveUIWeb.UserAuth, :ensure_authenticated}, {LiveUIWeb.UserAuth, :ensure_admin}] do
      live_ui("/companies", CompanyLive, LiveUI.Admin.Company)
      live_ui("/contacts", ContactLive, LiveUI.Admin.Contact)
      live_ui("/products", ProductLive, LiveUI.Admin.Product)
      live_ui("/departments", DepartmentLive, LiveUI.Admin.Department)
      live_ui("/sessions", SessionLive, LiveUI.Admin.Session)
      live_ui("/users", UserLive, LiveUI.Admin.User)
    end
  end

  scope "/", LiveUIWeb do
    pipe_through([:browser])

    delete("/users/log_out", UserSessionController, :delete)

    live_session :current_user,
      on_mount: [{LiveUIWeb.UserAuth, :mount_current_user}] do
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end
end
