defmodule Exforth.MixProject do
  use Mix.Project

  def project do
    [
      app: :exforth,
      version: "0.1.4",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ExForth",
      description: "A transpiler from a Forth dialect to Elixir AST",
      package: package(),
      docs: docs(),
      elixirc_options: [warnings_as_errors: false],
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      # mod: {ExForth.App, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "config", "flib", "examples", "README.md", "GUIDE.md", "TODO.md", "WORDS.md", "mix.exs", "test", "LICENSE"],
      maintainers: ["zeromoonsan"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/ZeroMoonSan/ExForth"}
    ]
  end

  defp docs do
    [
      main: "ExForth.App",
      extras: [
        "README.md", 
        "GUIDE.md", 
        "WORDS.md",
        "TODO.md"
      ]
    ]
  end
end
