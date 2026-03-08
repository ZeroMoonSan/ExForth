use flib/core
ex: . ( x -- ) [x | rest] = stack; IO.puts(x); rest ex;
ex: + ( a b -- n ) [a, b | rest] = stack; [a + b | rest] ex;
ex: - ( a b -- n ) [a, b | rest] = stack; [a - b | rest] ex;
ex: * ( a b -- n ) [a, b | rest] = stack; [a * b | rest] ex;
ex: / ( a b -- n ) [a, b | rest] = stack; [div(b, a) | rest] ex;
: square ( x -- x^2 ) dup * ;
: sqrt ( a -- a^2 ) dup *  ;
: cube ( a -- a^3 ) dup dup * * ;
