defmodule CashCrunch.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CashCrunchWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:cash_crunch, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CashCrunch.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CashCrunch.Finch},
      # Start a worker by calling: CashCrunch.Worker.start_link(arg)
      # {CashCrunch.Worker, arg},
      # Start to serve requests, typically the last entry
      CashCrunchWeb.Endpoint,
      # for salad ui
      TwMerge.Cache,
      CashCrunch.Repo
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CashCrunch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CashCrunchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
