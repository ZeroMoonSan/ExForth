defmodule ExForth.Vars do
  @moduledoc """
  Agent for storing ExForth variables.

  This module provides a simple key-value store using Elixir's Agent
  to maintain global variables across ExForth word executions.
  """

  use Agent

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(name) do
    Agent.get(__MODULE__, &Map.get(&1, name))
  end

  def set(name, val) do
    Agent.update(__MODULE__, &Map.put(&1, name, val))
  end
end
