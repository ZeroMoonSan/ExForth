*   `[` ( -- quotation ) – start quotation
*   `]` ( -- ) – end quotation
*   `{` ( -- ) – begin local variables
*   `}` ( -- ) – end local variables
*   `@` ( addr -- value ) – fetch global variable
*   `!` ( value addr -- ) – store global variable
*   `if` ( flag -- ) – start conditional
*   `else` ( -- ) – alternative branch
*   `then` ( -- ) – end conditional
*   `begin` ( -- ) – start indefinite loop
*   `until` ( flag -- ) – end indefinite loop
*   `do` ( limit start -- ) – start counted loop
*   `loop` ( -- ) – end counted loop
*   `use` ( "filename" -- ) – import file
*   `ex:` ( -- ) – define word with Elixir
*   `dup` ( x -- x x ) – duplicate top (core.fs)
*   `drop` ( x -- ) – remove top (core.fs)
*   `swap` ( a b -- b a ) – swap top two (core.fs)
*   `over` ( a b -- a b a ) – copy second to top (core.fs)
*   `<` ( a b -- flag ) – a < b (core.fs)
*   `>` ( a b -- flag ) – a > b (core.fs)
*   `=` ( a b -- flag ) – a == b (core.fs)
*   `negate` ( n -- -n ) – change sign (core.fs)
*   `lte` ( a b -- flag ) – a <= b (core.fs)
*   `.` ( x -- ) – print x (math.fs)
*   `+` ( a b -- sum ) – add (math.fs)
*   `-` ( a b -- diff ) – subtract (a - b) (math.fs)
*   `*` ( a b -- prod ) – multiply (math.fs)
*   `/` ( a b -- quot ) – integer division (b / a) (math.fs)
*   `square` ( x -- x² ) – square (math.fs)
*   `sqrt` ( a -- a² ) – square (not sqrt) (math.fs)
*   `cube` ( a -- a³ ) – cube (math.fs)

## Name sanitization mapping
*   `.` → `dot`
*   `+` → `add`
*   `-` → `sub`
*   `*` → `mul`
*   `/` → `div_`
*   `^` → `pow`
*   `<` → `lt`
*   `>` → `gt`
*   `=` → `eq`
*   `<=` → `lte`
*   `>=` → `gte`
*   `!=` → `neq`
*   `abs` → `abs_`
*   any other string → replace `-` with `_`
