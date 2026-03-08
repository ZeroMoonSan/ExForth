use flib/core
use flib/math

\ Variables
var counter
0 counter!

\ Math
: square dup * ;
: average { a b } a b add 2 div_ ;

\ Control flow
: abs dup 0 lt if negate then ;
: factorial
  dup 1 lte if drop 1 exit then
  dup 1- factorial mul
;

\ Loop
: sum
  0 swap 1+ 1 do
    i add
  loop
;

\ Pattern matching
: describe-number
  0 -> "zero"
  1 -> "one"
  2 -> "two"
  _ -> "many"
;

\ Main
: main
  5 square dot
  10 20 average dot
  -7 abs dot
  5 factorial dot
  10 sum dot
  1 describe-number dot
;
main
