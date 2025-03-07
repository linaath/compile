rherehr
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int ligne, colonne;
extern char* yytext;
void yyerror(const char *s);
extern FILE *yyin;
%}

%union {
    int ival;
    double fval;
    char* sval;
}
%token MAINPRGM L3_SOFTWARE VAR BEGINPG ENDPG
%token LET DEFINE CONST INT FLOAT
%token COLON SEMICOLON COMMA
%token LBRACKET RBRACKET LPAREN RPAREN LBRACE RBRACE
%token ASSIGN
%token IF THEN ELSE DO WHILE FOR FROM TO STEP INPUT OUTPUT
%token AND OR NOT PLUS MINUS MULTIPLY DIVIDE
%token LTE GTE EQ NEQ LT GT
%token NUMBER FLOAT_NUMBER CHAINE IDF


%left OR
%left AND
%right NOT
%left EQ NEQ LT GT LTE GTE
%left PLUS MINUS
%left MULTIPLY DIVIDE
%right UMINUS 

%start program

%%


program:
    MAINPRGM L3_SOFTWARE declarations BEGINPG statements ENDPG
    ;

declarations:

    | declarations declaration
    ;

declaration:
    VAR id_list COLON type SEMICOLON
    | DEFINE IDF ASSIGN expression SEMICOLON
    | CONST IDF ASSIGN expression SEMICOLON
    ;

id_list:
    IDF
    | id_list COMMA IDF
    ;

type:
    INT
    | FLOAT
    ;

statements:
   
    | statements statement
    ;

statement:
    LET IDF ASSIGN expression SEMICOLON
    | if_statement
    | while_statement
    | for_statement
    | io_statement
    | LBRACE statements RBRACE
    ;

if_statement:
    IF LPAREN expression RPAREN THEN statement
    | IF LPAREN expression RPAREN THEN statement ELSE statement
    ;

while_statement:
    WHILE LPAREN expression RPAREN DO statement
    ;

for_statement:
    FOR IDF FROM expression TO expression DO statement
    | FOR IDF FROM expression TO expression STEP expression DO statement
    ;

io_statement:
    INPUT LPAREN IDF RPAREN SEMICOLON
    | OUTPUT LPAREN expression RPAREN SEMICOLON
    ;

expression:
    IDF
    | NUMBER
    | FLOAT_NUMBER
    | CHAINE
    | LPAREN expression RPAREN
    | expression PLUS expression
    | expression MINUS expression
    | expression MULTIPLY expression
    | expression DIVIDE expression
    | expression AND expression
    | expression OR expression
    | NOT expression
    | expression EQ expression
    | expression NEQ expression
    | expression LT expression
    | expression GT expression
    | expression LTE expression
    | expression GTE expression
    | MINUS expression %prec UMINUS
    | array_access
    ;

array_access:
    IDF LBRACKET expression RBRACKET
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erreur syntaxique (ligne %d, colonne %d): %s\n", ligne, colonne, s);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier %s\n", argv[1]);
            exit(1);
        }
    } else {
        yyin = stdin;
    }
    
   
    yyparse();
    
    if (yyin != stdin) {
        fclose(yyin);
    }
    
    return 0;
}