defmodule SystemMetrics do
  @moduledoc """

  Application that generates a servers as a worker for logging system metrics
  each minute.

  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # define workers and child supervisors to be supervised
    children = [
      worker(SystemMetrics.Monitor, [])
    ]

    opts = [strategy: :one_for_one, name: SystemMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
