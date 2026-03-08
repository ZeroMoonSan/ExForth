defmodule Cfg do
  @moduledoc """
  Configuration helper for ExForth runtime settings.

  Provides convenient access to application environment variables
  for customizing ExForth behavior.
  """
  def get(key), do: Application.get_env(:exforth, key)
  def put(key, val), do: Application.put_env(:exforth, key, val)
end
