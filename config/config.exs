import Config

# live ui
config :live_ui,
  debug: true,
  repo: LiveUI.Repo,
  cldr: LiveUI.Cldr,
  ignored_fields: [:token, :hashed_password, :first_version_id, :current_version_id]

# petal components
config :petal_components, :error_translator_function, {LiveUIWeb.CoreComponents, :translate_error}

# flop
config :flop, repo: LiveUI.Repo, default_limit: 10, max_limit: 100

# cldr
config :ex_cldr, default_backend: LiveUI.Cldr
config :live_ui, LiveUI.Cldr, locales: ["en"]

# paper trail
config :paper_trail,
  repo: LiveUI.Repo,
  originator: [name: :user, model: LiveUI.Admin.User],
  strict_mode: true

# flag to start application when not a dependency
config :live_ui, :start_application, true

# default phoenix config
config :live_ui, ecto_repos: [LiveUI.Repo]

# Configures the endpoint
config :live_ui, LiveUIWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: LiveUIWeb.ErrorHTML, json: LiveUIWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LiveUI.PubSub,
  live_view: [signing_salt: "AfBg5nvJ"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :live_ui, LiveUI.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.1",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
