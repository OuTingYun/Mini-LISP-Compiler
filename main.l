%{
#include "y.tab.h"
#define _GNU_SOURCE
#include <string.h>
%}
digit [0-9]
letter [a-z]
ID {letter}({letter}|{digit}|-)*
Number  0|[1-9]{digit}*|-[1-9]{digit}*
%%
\(  {yylval.word = strdup(yytext);return(lp);}
\)  { yylval.word = strdup(yytext);return(rp);}
{Number}  {
yylval.ival= atoi(yytext); return(number1);
}
#t {yylval.ival= 1; return(boolean);}
#f {yylval.ival= 0; return(boolean);}
\t|\r|\n  {}
[ ] {}
print\-num|print\-bool {yylval.word=strdup(yytext);return(print_op);}
\+|\-|\*|\/|mod|\>|\<|\= {yylval.word=strdup(yytext);return(num_op);}
and|or|not {yylval.word=strdup(yytext);return(logical_op);}
define  {yylval.word=strdup(yytext);return(define_op);}
if  {yylval.word=strdup(yytext);return(if_op);}
fun  {yylval.word=strdup(yytext);return(fun_op);}
{ID} {yylval.word=strdup(yytext);return(id);}
.  { return(yytext[0]); }

%%
