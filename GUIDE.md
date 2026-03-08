# ExForth Guide

## Copy flibs
```bash
mkdir flib
cp deps/exforth/flib/* flib/
```

## Language Syntax

This is a Forth-inspired stack language with some unique features. The syntax combines classic Forth concepts with modern ideas from Factor.

### Import Lib
```forth
use flib/core
use flib/math
```

### Basic Operations
```forth
: square dup mul ;
5 square  \ returns 25

: greeting "Hello, World!" . ;
greeting  \ prints Hello, World!
```

### Variables
```forth
var counter
10 counter!
counter@  \ returns 10
```

### Control Flow
```forth
: abs dup 0 lt if negate then ;
-5 abs  \ returns 5

: factorial
  dup 1 <= if drop 1 exit then
  dup
  1- factorial mul
;
5 factorial  \ returns 120
```

### Loops
```forth
: count-up
  0 5 0 do
    i .
  loop
;
\ prints: 0 1 2 3 4

: sum
  0 swap 1+ 1 do
    i add
  loop
;
10 sum  \ returns 55
```

### Begin/Until
```forth
: countdown
  5 begin
    dup . 1-
    dup 0 eq
  until
  drop
;
\ prints: 5 4 3 2 1 0
```

### Quoted Words (Lambdas)
```forth
: inc [ 1+ ] call ;
5 inc  \ returns 6

: apply-twice dup dip call ;
```

### Pattern Matching
```forth
: describe-number
  0 -> "zero"
  1 -> "one"
  2 -> "two"
  _ -> "many"
;
1 describe-number  \ returns "one"
```

### Local Variables
```forth
: average { a b } a b add 2 div_ ;
10 20 average  \ returns 15
```

### do-blocks (Elixir interop)

Call any Elixir block-form function with Forth bodies in each clause:
```forth
: wait
  receive do
    42 -> "got 42" .
    _  ->
  end
;
```

With timeout:
```forth
: wait-or-timeout
  receive do
    42 -> "got it" .
  after
    5000 -> "timeout" .
  end
;
```

### Inline Elixir Code

Insert raw Elixir directly into the generated module or word body:
```forth
<{
  require Logger
  alias MyApp.Repo
}>

: log-something
  <{ Logger.info("called") }>
  42
;
```

## Native Extensions

Define Elixir pattern-matching functions directly:
```forth
ex: dup ( x -- x x )
  [x | rest] = stack
  [x, x | rest]
ex;

ex: + ( a b -- n )
  [a, b | rest] = stack
  [a + b | rest]
ex;

ex: . ( x -- )
  [x | rest] = stack
  IO.puts(x)
  rest
ex;
```

## Architecture
```
┌─────────────────────────────────────────┐
│            ExForth.FLoader (GenServet)  │
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
│        ExForth.Translator               │
│  - Generates Elixir code                │
│  - Compiles to modules                  │
└─────────────────────────────────────────┘
```

## Modules
- `ExForth.Runtime` - Standard stack primitives (`push`)
- `ExForth.Vars` - Global variable storage (Agent-based key-value store)
- `ExForth.Cache` - Compilation cache (prevents recompiling loaded files)
- `ExForth.Lexer` - Tokenizer using NimbleParsec
- `ExForth.Parser` - AST builder (groups flat tokens into nested structures)
- `ExForth.Translator` - Code generator (compiles AST to Elixir modules)
- `ExForth.FLoader` - File loader and compiler (resolves `use` dependencies)

## Running Tests
```bash
mix test
```

## Development
```bash
# Run the project
iex -S mix
ExForth.FLoader.load("main.fs")

# Generate documentation
mix docs
```
