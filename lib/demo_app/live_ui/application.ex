defmodule LiveUI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LiveUIWeb.Telemetry,
      # Start the Ecto repository
      LiveUI.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveUI.PubSub},
      # Start Finch
      {Finch, name: LiveUI.Finch},
      # Start the Endpoint (http/https)
      LiveUIWeb.Endpoint
      # Start a worker by calling: LiveUI.Worker.start_link(arg)
      # {LiveUI.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveUI.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveUIWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
