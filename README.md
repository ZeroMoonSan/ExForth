# ExForth
**Forth-inspired stack language that compiles to Elixir**

ExForth is a custom programming language inspired by Forth and Factor, implemented in Elixir. It combines the elegance of stack-based programming with modern functional concepts, compiling directly to efficient Elixir modules.

## Features

- **Stack-based execution** - Classic Forth-style reverse Polish notation
- **Compiles to Elixir** - Transforms source code into efficient Elixir modules
- **Native extensions** - Define Elixir functions directly using `ex:`
- **Pattern matching** - Unique do-blocks inspired by Factor's combinators
- **First-class quotations** - Lambda expressions with `[ ... ]` syntax
- **Control structures** - IF/ELSE/THEN, BEGIN/UNTIL, DO/LOOP
- **Variables** - Global variables with `@` (fetch) and `!` (store)
- **Local variables** - Using `{ var1 var2 }` syntax
- **Modules** - Import other source files with `use`
- **Supervision** - Built on Elixir's OTP for robustness

## Installation

Add `exforth` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exforth, "~> 0.1.0"}  # or {:exforth, github: "ZeroMoonSan/ExForth"}
  ]
end
```

## Quick Start

```elixir
  def start(_type, _args) do
    children = [
      ExForth.Vars,
      ExForth.Cache,
      ExForth.FLoader,
    ]
# Load and compile a Forth file
iex(1)> ExForth/FLoader.load("path/to/your/file.fs")
{:ok, "ExForth.FLoader.Scripts.File"}
# Run the compiled module
iex(2)> ExForth.FLoader.Scripts.File.exec()
13
[]
iex(3)> 

```

## License

MIT License - see LICENSE file for details.
