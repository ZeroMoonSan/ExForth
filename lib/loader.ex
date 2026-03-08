defmodule ExForth.FLoader do
  @moduledoc """
  GenServer for loading and compiling ExForth source files.

  This module handles loading ExForth source files (.fs), compiling them
  to Elixir code, and managing dependencies between modules using the
  `use` directive. It caches compiled paths to avoid redundant recompilation.
  """

  use GenServer
  require Logger

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def load(path) do
    # нормализуем путь
    path = resolve_path(path)

    if ExForth.Cache.compiled?(path) do
      Logger.debug("Already compiled: #{path}, skipping")
      :ok
    else
      do_load(path)
    end
  end

  defp do_load(path) do
    source_code = File.read!(path)
    mod_name    = path_to_mod(path)
    Logger.debug("Compiling: #{path} -> #{mod_name}")

    {:ok, raw_tokens, _, _, _, _} = ExForth.Lexer.tokenize(source_code)
    tokens = ExForth.Parser.parse(raw_tokens)

    # зависимости
    for {:use, dep_path} <- tokens do
      dep_path |> resolve_path() |> load()
    end

    elixir_code = ExForth.Translator.translate(tokens, mod_name)
    Logger.debug("Generated code:\n#{elixir_code}")
    
    Code.compile_string(elixir_code)
    ExForth.Cache.mark_compiled(path)
    {:ok, mod_name}
  end

  # "stdlib" или "stdlib.fs" -> полный путь
  defp resolve_path(path) do
    cond do
      String.starts_with?(path, "/") -> path
      String.ends_with?(path, ".fs") -> path
      true                           -> path <> ".fs"
    end
  end

  defp path_to_mod(path) do
    name =
      path
      |> Path.basename()
      |> String.replace_suffix(".fs", "")
      |> Macro.camelize()
    "ExForth.FLoader.Scripts.#{name}"
  end
end
