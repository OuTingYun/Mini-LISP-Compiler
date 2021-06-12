##  LEX & YACC
Use Lex & YACC to write an interpreter for Mini-LISP, implement features of the language.
### Rules
Feature | input | output
--------|-------|-------
Syntax Validation|(+)|syntax error
Print|( print-num 3 )|3
Numerical Operations|( print-num (+ 1 2 3 4)|10
Logical Operations|(print-bool ( ( not (> 1 2 ) ) ) |#t
if Expression|( print-num ( ( if #t 1 2) )| 1
Variable Definition|(define x 5)</br>(+ x 1)|6
Function|( ( fun (x) ( + x 1 ) ) 2 ) |3
Named Function|( define foo ( fun () 0 ) )</br>(foo)| 0

### Environment
[flex-2.5.4a-1.exe](http://gnuwin32.sourceforge.net/packages/flex.htm)

[bison-2.4.1-setup.exe](http://gnuwin32.sourceforge.net/packages/bison.htm)
### .lsp file
Put Mini-LISP in .lsp file

```lisp
# inside the test.lsp
( print-num 3 )
```
### How to use
```bash
d:> flex main.l #generate lex.yy.c

d:> bison -dy main.y   #generate y.tab.c

d:> gcc lex.yy.c y.tab.c -o main.exe    #generate main.exe

d:> main.exe < test.lsp      #put test.lsp in main.exe
3
```
