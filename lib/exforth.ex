defmodule ExForth.App do
  @moduledoc """
  Application callback module for ExForth.

  Starts the supervision tree containing:
  - ExForth.Vars (variable storage)
  - ExForth.Cache (compilation cache)
  - FLoader (file loader)

  Note: For library usage, you can start these components manually
  or include ExForth in your supervision tree.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExForth.Vars,
      ExForth.Cache,
      ExForth.FLoader,
    ]
    opts = [strategy: :one_for_one, name: ExForth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
