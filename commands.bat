flex lexical.l
bison -d -v --report=all syntax.y

gcc lex.yy.c syntax.tab.c  ts.c -lfl -ly -o test.exe

test.exe < code.txt