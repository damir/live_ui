defmodule LiveUI.MixProject do
  use Mix.Project

  @source_url "https://github.com/damir/live_ui"
  @version "0.1.0"

  def project do
    [
      app: app(),
      name: "LiveUI",
      version: @version,
      source_url: @source_url,
      homepage_url: @source_url,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    # use config to start application when not a dependency
    if Application.get_env(app(), :start_application) do
      [
        mod: {LiveUI.Application, []},
        extra_applications: [:logger, :runtime_tools]
      ]
    else
      []
    end
  end

  defp app(), do: :live_ui

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/demo_app", "test/live_ui"]

  defp elixirc_paths(:prod) do
    # so we do not compile web stuff when used as dependency
    ["lib/live_ui", "lib/live_ui.ex"]
  end

  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "0.20.11"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:bandit, ">= 1.0.0"}
    ] ++ live_ui_deps() ++ demo_app_deps()
  end

  def live_ui_deps() do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.4"},
      {:ex_cldr_dates_times, "~> 2.0"},
      {:ex_cldr_plugs, "~> 1.2"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:ex_money, "~> 5.0"},
      {:faker, "~> 0.17", only: [:dev, :test]},
      {:flop_phoenix, "~> 0.22"},
      {:live_select, "1.3.3"},
      {:paper_trail, "~> 1.0.0"},
      {:petal_components, "~> 1.0"},
      {:tz, "~> 0.26"}
      # {:live_inspect, "~> 0.2"}, # too old
    ]
  end

  def demo_app_deps() do
    []
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/blob/main/CHANGELOG.md"
      },
      files: ~w(lib .formatter.exs mix.exs CHANGELOG* README* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: @version,
      formatters: ["html"],
      filter_modules:
        "LiveUI$|LiveUI.Router|LiveUI.Protocol.Utils$|LiveUI.Formatters|LiveUI.Components.Core",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_docs: [
        Components: &(&1[:section] == :components),
        Miscellaneous: &(&1[:section] == :miscellaneous)
      ]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ] ++ custom_aliases()
  end

  defp custom_aliases do
    [
      "phx.routes": "phx.routes LiveUIWeb.Router"
    ]
  end
end
