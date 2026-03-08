# ExForth Words

## Keywords
* `[` ( -- ) – start quotation
* `]` ( -- ) – end quotation
* `{` ( -- ) – begin local variables
* `}` ( -- ) – end local variables
* `if` ( flag -- ) – start conditional
* `else` ( -- ) – alternative branch
* `then` / `end` ( -- ) – end conditional
* `begin` ( -- ) – start indefinite loop
* `until` ( flag -- ) – end indefinite loop
* `do` ( from to -- ) – start counted loop
* `loop` ( -- ) – end counted loop
* `i` ( -- n ) – current loop index
* `exit` ( -- ) – early return from word
* `1+` ( n -- n+1 ) – increment
* `1-` ( n -- n-1 ) – decrement
* `->` ( -- ) – pattern match clause
* `after` ( -- ) – timeout clause in do-block
* `call` ( quot -- ) – call quotation

## Declarations
* `use` ( "filename" -- ) – import .fs file
* `var` ( "name" -- ) – declare global variable
* `ex:` ( -- ) – define native Elixir word
* `:` ... `;` ( -- ) – define user word
* `<{ }>` ( -- ) – inline raw Elixir code

## Variable Access
* `name!` ( value -- ) – store global variable
* `name@` ( -- value ) – fetch global variable

## core.fs
* `dup` ( x -- x x ) – duplicate top
* `drop` ( x -- ) – remove top
* `swap` ( a b -- b a ) – swap top two
* `over` ( a b -- a b a ) – copy second to top
* `negate` ( n -- -n ) – change sign
* `<` ( a b -- flag ) – less than
* `>` ( a b -- flag ) – greater than
* `=` ( a b -- flag ) – equal
* `<=` ( a b -- flag ) – less than or equal

## math.fs
* `.` ( x -- ) – print x
* `+` ( a b -- n ) – add
* `-` ( a b -- n ) – subtract (a - b)
* `*` ( a b -- n ) – multiply
* `/` ( a b -- n ) – integer division (b / a)
* `square` ( x -- x² ) – square
* `cube` ( x -- x³ ) – cube

## Name sanitization
* `.` → `dot`
* `+` → `add`
* `-` → `sub`
* `*` → `mul`
* `/` → `div_`
* `^` → `pow`
* `<` → `lt`
* `>` → `gt`
* `=` → `eq`
* `<=` → `lte`
* `>=` → `gte`
* `!=` → `neq`
* `abs` → `abs_`
* `-` in names → `_` (e.g. `describe-number` → `describe_number`)
