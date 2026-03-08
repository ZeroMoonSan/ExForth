use flib/core
use flib/math

\ Variables
var counter
0 counter!

\ Math
: square ( a -- a^2 ) dup * ;
: average ( a b -- c ){ a b } a b + 2 / ;

\ Control flow
: abs ( a -- b ) dup 0 < if negate then ;
: factorial ( a -- b )
  dup 1 <= if drop 1 exit then
  dup 1- factorial *
;

\ Loop
: sum ( a .. b c -- )
  0 swap 1+ 1 do
    i +
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
  5 square .
  10 20 average .
  -7 abs dot
  5 factorial .
  10 sum .
  1 describe-number .
;
main
