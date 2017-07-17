defmodule Stockboard do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Stockboard.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Stockboard.Endpoint, []),
      worker(Stockboard.Main, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Stockboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Stockboard.Endpoint.config_change(changed, removed)
    :ok
  end
end
