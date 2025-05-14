%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

int temp_counter = 0;
int label_counter = 0;
extern int yylex();
extern FILE *yyin;
FILE *yyout;

int yyerror(char *s);

// Create a new temporary variable
char* new_temp() {
    char* name = malloc(10);
    sprintf(name, "t%d", temp_counter++);
    return name;
}

// Create a new label
char* new_label() {
    char* label = malloc(10);
    sprintf(label, "L%d", label_counter++);
    return label;
}

// Emit a TAC instruction
void emit(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vfprintf(yyout, format, args);
    fprintf(yyout, "\n");
    va_end(args);
}
%}

%union {
    char* str;
    struct {
        char* code;
        char* place;
    } *expr;
}

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%token PRINT SEMI ASSIGN PLUS MINUS TIMES DIVIDE LPAREN RPAREN
%token IF ELSE
%token EQ NE LT GT LE GE
%token <str> NUMBER ID
%token LBRACE RBRACE

%type <expr> expression term factor condition
%type <str> statement_block statement
%type <str> statement_list assignment print_statement if_statement

%%

program:
    statement_list { emit("%s", $1); free($1); }
;

statement_list:
    statement { $$ = $1; }
    | statement_list statement {
        int len = strlen($1) + strlen($2) + 2;
        $$ = malloc(len);
        snprintf($$, len, "%s\n%s", $1, $2);
        free($1); free($2);
    }
;

statement:
    assignment SEMI { $$ = $1; }
    | print_statement SEMI { $$ = $1; }
    | if_statement { $$ = $1; }
;

assignment:
    ID ASSIGN expression {
        char* code = malloc(strlen($3->code) + strlen($1) + strlen($3->place) + 10);
        sprintf(code, "%s%s = %s", $3->code, $1, $3->place);
        $$ = code;
        free($1); free($3->code); free($3->place); free($3);
    }
;

print_statement:
    PRINT expression {
        char* code = malloc(strlen($2->code) + 50);
        sprintf(code, "%sprint %s", $2->code, $2->place);
        $$ = code;
        free($2->code); free($2->place); free($2);
    }
;

if_statement:
    IF LPAREN condition RPAREN statement_block %prec LOWER_THAN_ELSE {
        char *label_end = new_label();
        char* code = malloc(strlen($3->code) + strlen($5) + 100);
        sprintf(code, "%sifFalse %s goto %s\n%s\n%s:", $3->code, $3->place, label_end, $5, label_end);
        $$ = code;
        free($3->code); free($3->place); free($3); free($5); free(label_end);
    }
    | IF LPAREN condition RPAREN statement_block ELSE statement_block {
        char* label_else = new_label();
        char* label_end = new_label();
        char* code = malloc(strlen($3->code) + strlen($5) + strlen($7) + 200);
        sprintf(code, "%sifFalse %s goto %s\n%s\ngoto %s\n%s:\n%s\n%s:",
                $3->code, $3->place, label_else, $5, label_end, label_else, $7, label_end);
        $$ = code;
        free($3->code); free($3->place); free($3); free($5); free($7);
        free(label_else); free(label_end);
    }
;

statement_block:
    statement {
        $$ = strdup($1);
        free($1);
    }
    | LBRACE statement_list RBRACE {
        $$ = $2;
    }
;

condition:
    expression EQ expression {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s == %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1->code); free($1->place); free($1);
        free($3->code); free($3->place); free($3);
    }
    | expression NE expression {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s != %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1); free($3);
    }
    | expression LT expression {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s < %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1); free($3);
    }
    | expression LE expression {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s <= %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1); free($3);
    }
    | expression GT expression {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s > %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1); free($3);
    }
    | expression GE expression {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s >= %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1); free($3);
    }
;

expression:
    term { $$ = $1; }
    | expression PLUS term {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s + %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1); free($3);
    }
    | expression MINUS term {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s - %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1); free($3);
    }
;

term:
    factor { $$ = $1; }
    | term TIMES factor {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s * %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1); free($3);
    }
    | term DIVIDE factor {
        $$ = malloc(sizeof(*$$));
        $$->place = new_temp();
        $$->code = malloc(strlen($1->code) + strlen($3->code) + 100);
        sprintf($$->code, "%s%s%s = %s / %s\n", $1->code, $3->code, $$->place, $1->place, $3->place);
        free($1); free($3);
    }
;

factor:
    NUMBER {
        $$ = malloc(sizeof(*$$));
        $$->place = $1;
        $$->code = strdup("");
    }
    | ID {
        $$ = malloc(sizeof(*$$));
        $$->place = $1;
        $$->code = strdup("");
    }
    | LPAREN expression RPAREN { $$ = $2; }
;

%%

int yyerror(char *s) {
    fprintf(stderr, "Error: %s\n", s);
    return 1;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <input_file> <output_file>\n", argv[0]);
        return 1;
    }

    FILE *input_file = fopen(argv[1], "r");
    if (!input_file) {
        perror("Error opening input file");
        return 1;
    }

    yyout = fopen(argv[2], "w");
    if (!yyout) {
        perror("Error opening output file");
        fclose(input_file);
        return 1;
    }

    yyin = input_file;
    yyparse();

    fclose(input_file);
    fclose(yyout);
    return 0;
}
