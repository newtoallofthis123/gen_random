defmodule GenRandom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GenRandomWeb.Telemetry,
      GenRandom.Repo,
      {DNSCluster, query: Application.get_env(:gen_random, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GenRandom.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GenRandom.Finch},
      # Start a worker by calling: GenRandom.Worker.start_link(arg)
      # {GenRandom.Worker, arg},
      # Start to serve requests, typically the last entry
      GenRandomWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GenRandom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GenRandomWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
