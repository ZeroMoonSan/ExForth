defmodule Exforth.MixProject do
  use Mix.Project

  def project do
    [
      app: :exforth,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ExForth",
      description: "A transpiler from a Forth dialect to Elixir AST",
      package: package(),
      docs: docs()
    ]
  end

  # Library configuration (not an application)
  def application do
    [
      extra_applications: [:logger]
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
      files: ["lib", "core.fs", "math.fs", "README.md", "LICENSE"],
      maintainers: ["Your Name"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/ZeroMoonSan/ExForth"}
    ]
  end

  defp docs do
    [
      main: "ExForth",
      extras: [
        "README.md",
        "core.fs",
        "math.fs"
      ]
    ]
  end
end
