%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
%}
%option noyywrap
%%
[ \t\n]     ; // Ignore whitespace
"tnirp"     { return PRINT; }
"fi"      {return IF;}
"esle"    {return ELSE;}
"=="      {return EQ;}
"!="      {return NE;}
"<"       {return LT;}
">"       {return GT;}
"<="      {return LE;}
">="      {return GE;}
"="         { return ASSIGN; }
";"         { return SEMI; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return TIMES; }
"/"         { return DIVIDE; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         {return LBRACE;}
"}"         {return RBRACE;}
[0-9]+      { yylval.str = strdup(yytext); return NUMBER; } // Capture number as string
[a-zA-Z]+   { yylval.str = strdup(yytext); return ID; }     // Capture variable name
.           { printf("Invalid token: %s\n", yytext); }
%%