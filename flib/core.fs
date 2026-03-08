ex: dup ( x -- x x ) [x | rest] = stack; [x, x | rest] ;
ex: drop ( x -- ) [_ | rest] = stack; rest ;
ex: swap ( a b -- b a ) [a, b | rest] = stack; [b, a | rest] ;
ex: over ( a b -- a b a ) [a, b | rest] = stack; [b, a, b | rest] ;
ex: < ( a b -- bool ) [b, a | rest] = stack; [a < b | rest] ;
ex: > ( a b -- bool ) [b, a | rest] = stack; [a > b | rest] ;
ex: = ( a b -- bool ) [b, a | rest] = stack; [a == b | rest] ; ;
ex: negate ( n -- n ) [n | rest] = stack; [-n | rest] ;
ex: lte ( a b -- bool ) [b, a | rest] = stack; [a <= b | rest] ;
