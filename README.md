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
    {:exforth, "~> 0.1.0"}
  ]
end
```

## Quick Start

```elixir
# Load and compile a Forth file
FLoader.load("path/to/your/file.fs")

# Run the compiled module
YourModule.exec()
```

## Language Syntax

This is a Forth-inspired stack language with some unique features. The syntax combines classic Forth concepts with modern ideas from Factor.

### Basic Operations

```forth
: square dup * ;
5 square  # returns 25

: greeting ." Hello, World!" ;
greeting  # prints "Hello, World!"
```

### Variables

```forth
var counter
10 counter !
counter @  # returns 10
```

### Control Flow

```forth
: abs dup 0 < if negate then ;
-5 abs  # returns 5

: factorial
  dup 1 <= if drop 1 exit then
  dup
  1- factorial *
;
5 factorial  # returns 120
```

### Loops

```forth
: count-up
  0 5 do
    i .
  loop
;
# prints: 0 1 2 3 4

: sum
  0 swap 1+ 1 do
    i +
  loop
;
10 sum  # returns 55
```

### Begin/Until

```forth
: countdown
  5 begin
    dup . 1-
    dup 0=
  until
  drop
;
# prints: 5 4 3 2 1 0
```

### Quoted Words (Lambdas)

```forth
: call-with-5
  [ 5 ] call
;
call-with-5  # returns [5] on stack
```

### Do-Blocks (Pattern Matching - Unique to ExForth)

Inspired by Factor's combinators, do-blocks provide pattern matching:

```forth
: describe-number
  0 -> "zero"
  1 -> "one"
  2 -> "two"
  -> "many"
;
1 describe-number  # returns "one"
```

### Local Variables

```forth
: average { a b }
  a b + 2 /
;
10 20 average  # returns 15
```

## Native Extensions

Define Elixir functions directly in your code:

```forth
ex: add_two; stack = stack + 2;
ex: multiply = a * b; a * b;

10 add_two     # returns 12
3 4 multiply   # returns 12
```

## Architecture

```
┌─────────────────────────────────────────┐
│            FLoader (GenServer)          │
│  - Loads .fs files                      │
│  - Manages dependencies                 │
│  - Caches compiled modules              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         ExForth.Lexer (NimbleParsec)    │
│  - Tokenizes source code                │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│          ExForth.Parser                 │
│  - Builds AST from tokens               │
│  - Handles control structures           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│        ExForth.Translator              │
│  - Generates Elixir code                │
│  - Compiles to modules                  │
└─────────────────────────────────────────┘
```

## Modules

- `ExForth.App` - Application callback and supervision
- `ExForth.Vars` - Global variable storage
- `ExForth.Cache` - Compilation cache
- `ExForth.Lexer` - Tokenizer using NimbleParsec
- `ExForth.Parser` - AST builder
- `ExForth.Translator` - Code generator
- `FLoader` - File loader and compiler

## Running Tests

```bash
mix test
```

## Development

```bash
# Run the project
mix run -e "FLoader.load(\"core.fs\"); FLoader.load(\"math.fs\"); FLoader.load(\"test.fs\")"

# Generate documentation
mix docs
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
