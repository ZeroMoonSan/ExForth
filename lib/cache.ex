defmodule ExForth.Cache do
  @moduledoc """
  Cache for storing already-compiled ExForth source paths.

  This module prevents redundant recompilation of source files
  by tracking which files have already been compiled in the current session.
  """

  use Agent

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> MapSet.new() end, name: __MODULE__)
  end

  def compiled?(path) do
    Agent.get(__MODULE__, &MapSet.member?(&1, path))
  end

  def mark_compiled(path) do
    Agent.update(__MODULE__, &MapSet.put(&1, path))
  end
end

