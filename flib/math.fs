use flib/core
ex: . ( x -- ) [x | rest] = stack; IO.puts(x); rest ;
ex: + ( a b -- n ) [a, b | rest] = stack; [a + b | rest] ;
ex: - ( a b -- n ) [a, b | rest] = stack; [a - b | rest] ;
ex: * ( a b -- n ) [a, b | rest] = stack; [a * b | rest] ;
ex: / ( a b -- n ) [a, b | rest] = stack; [div(b, a) | rest] ;;
: square ( x -- x^2 ) dup mul ;
: sqrt ( a -- a^2 ) dup *  ;
: cube ( a -- a^3 ) dup dup * * ;
