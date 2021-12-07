%{
#include "calc.tab.h"
%}

/***************************************
    Expressões Regulares dos Terminais 
***************************************/
white [ \t]+
digit [0-9]
integer {digit}+
real {integer}("."{integer})?{exponent}?
exponent [eE][+-]?{integer}
lether [a-zA-Z]
identifier ({lether}|_)({lether}|{digit}|_)*


/************************************
    REGRAS: Padrões reconhecidos 

    * yylval.value e yylval.lexeme foram as variáveis 
    declaradas no Union do arquivo .y.
    * 'log' e 'sqrt' precisam estar antes da regra do
    identifier, já que as palavras pertencem a regra.
************************************/
%%
"log" return LOG;
"sqrt" return SQRT;
"pow" return POW;
"viewvars()" return VIEWVARS;

{white} { }
{real} { yylval.v = atof(yytext); return NUMBER; }            
{identifier} { sscanf(yytext, "%s", yylval.l); return VAR; }   

"," return SEPARATOR;
"=" return ATTR;
"+=" return ADDATTR;
"-=" return SUBATTR;
"*=" return MULATTR;
"/=" return DIVATTR;
"%=" return MODATTR;
"||" return OR;
"&&" return E;
"|||" return EXCLUSIVEOR;
"->" return IMPLICATION;
"==" return EQUAL;
"!=" return DIFF;
"<" return LESS;
"<=" return LESSOREQUAL;
">" return MORE;
">=" return MOREOREQUAL;
"+" return ADD;
"-" return SUB;
"*" return MUL;
"/" return DIV;
"%" return MOD;
"!" return NOT;
"(" return LBRACKET;
")" return RBRACKET;
"\n" return EOL;

%%
