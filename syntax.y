%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ts.h"

extern int ligne;
extern int colonne;
void yyerror(const char *msg);
int yylex();
int yywrap() { 
    return 1; 
}

// Variables pour l'analyse sémantique
int current_type;  // Pour stocker le type courant en cours de déclaration
int is_const;      // Pour indiquer si on traite une constante
int index_idf;     // Pour stocker l'index d'un identifiant dans la table des symboles
int tab_size;      // Pour stocker la taille d'un tableau déclaré
%}

%union {
    int ival;
    double fval;
    char* sval;
    struct {
        int type;       // TYPE_ENTIER ou TYPE_REEL
        int is_tab;     // 0 pour variable simple, 1 pour tableau
        int index_ts;   // Index dans la table des symboles
        int tab_size;   // Taille du tableau (si applicable)
    } info_var;
}

%type <ival> expression condition
%type <info_var> type valeur liste_idf idf_use
%token MAINPRGM VAR BEGINPG ENDPG LET DEFINE CONST INT_TYPE FLOAT_TYPE 
%token IF THEN ELSE DO WHILE FOR FROM TO STEP INPUT OUTPUT
%token AND OR NOT PLUS MINUS MULT DIV LT GT LE GE EQ NE 
%token ASSIGN COLON SEMICOLON COMMA LBRACKET RBRACKET EQUALS LPAREN RPAREN LBRACE RBRACE
%token <sval> IDF
%token <ival> INT_VAL
%token <fval> FLOAT_VAL
%token <sval> STRING_VAL
%token COMMENTAIRE_LIGNE COMMENTAIRE_BLOC

// Définition des priorités et associativités (du moins prioritaire au plus prioritaire)
%left OR
%left AND
%right NOT
%left LT GT LE GE EQ NE
%left PLUS MINUS
%left MULT DIV
%right ASSIGN
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%start programme

%%

programme : MAINPRGM IDF SEMICOLON bloc { 
    printf("Programme syntaxiquement correct !\n"); 
    afficher_table_symboles();
}
;

bloc : VAR declarations BEGINPG LBRACE instructions RBRACE ENDPG SEMICOLON
;

declarations : declarations declaration
             | declarations commentaire
             | /* vide */
             ;

declaration : LET liste_idf COLON type SEMICOLON { 
    printf("Déclaration de variables simples\n"); 
}
            | LET liste_idf COLON LBRACKET type SEMICOLON INT_VAL RBRACKET SEMICOLON { 
    if ($7 <= 0) {
        yyerror("Erreur sémantique: La taille du tableau doit être positive");
    }
    tab_size = $7;
    printf("Déclaration de tableau de taille %d\n", tab_size); 
}
            | DEFINE CONST IDF COLON type EQUALS valeur SEMICOLON { 
    int index = rechercher_symbole($3);
    if (index == -1) {
        index = inserer_symbole($3, ENTITE_CONSTANTE, $5.type, 1, ligne, colonne);
        if ($5.type == TYPE_ENTIER) {
            inserer_valeur_entier(index, $7.type);
        } else if ($5.type == TYPE_REEL) {
            inserer_valeur_reel(index, $7.type);
        }
    } else {
        yyerror("Erreur sémantique: Constante déjà déclarée");
    }
    printf("Déclaration de constante %s\n", $3); 
}
;

liste_idf : liste_idf COMMA IDF { 
    int index = rechercher_symbole($3);
    if (index == -1) {
        // Cas des tableaux
        if ($1.is_tab == 1) {
            type_symbole type_tab = ($1.type == TYPE_ENTIER) ? TYPE_TABLEAU_ENTIER : TYPE_TABLEAU_REEL;
            inserer_symbole($3, ENTITE_TABLEAU, type_tab, $1.tab_size, ligne, colonne);
        } else {
            // Cas des variables simples
            inserer_symbole($3, ENTITE_VARIABLE, $1.type, 1, ligne, colonne);
        }
    } else {
        yyerror("Erreur sémantique: Variable déjà déclarée");
    }
    printf("Variable: %s\n", $3);
    $$ = $1;  // Propager l'information pour les déclarations multiples
}
          | IDF { 
    int index = rechercher_symbole($1);
    if (index == -1) {
        $$.index_ts = -1;  // Sera rempli lors de la complétion de la règle déclaration
        $$.type = current_type;
        $$.is_tab = 0;
        $$.tab_size = 0;
    } else {
        yyerror("Erreur sémantique: Variable déjà déclarée");
    }
    printf("Variable: %s\n", $1); 
}
;

type : INT_TYPE { 
    current_type = TYPE_ENTIER;
    $$.type = TYPE_ENTIER;
    printf("Type: Integer\n"); 
}
      | FLOAT_TYPE { 
    current_type = TYPE_REEL;
    $$.type = TYPE_REEL;
    printf("Type: Float\n"); 
}
;

valeur : INT_VAL { 
    $$.type = $1;
    printf("Constante entière: %d\n", $1); 
}
        | FLOAT_VAL { 
    $$.type = $1;
    printf("Constante réelle: %f\n", $1); 
}
;

instructions : instructions instruction
              | /* vide */
;

instruction : affectation
             | condition
             | boucle
             | io_instruction
             | commentaire
             | instruction_if 
             | SEMICOLON
;

affectation : idf_use ASSIGN expression SEMICOLON { 
    // Vérification si l'identifiant est une constante
    if ($1.index_ts >= 0 && table_symboles[$1.index_ts].code == ENTITE_CONSTANTE) {
        yyerror("Erreur sémantique: Impossible de modifier une constante");
    }
    // Vérification de compatibilité de type (simplifiée)
    printf("Affectation\n"); 
}
           | idf_use LBRACKET expression RBRACKET ASSIGN expression SEMICOLON {
    // Vérification des bornes du tableau
    if ($1.index_ts >= 0) {
        if (!$1.is_tab) {
            yyerror("Erreur sémantique: Variable simple utilisée comme un tableau");
        }
        // La vérification de dépassement d'index se fera à l'exécution
        // sauf dans le cas d'un indice constant
    } else {
        yyerror("Erreur sémantique: Tableau non déclaré");
    }
    printf("Affectation à un élément de tableau\n");
}
;

idf_use : IDF {
    int index = rechercher_symbole($1);
    if (index == -1) {
        yyerror("Erreur sémantique: Variable non déclarée");
        $$.index_ts = -1;
        $$.type = TYPE_ENTIER;  // Type par défaut
        $$.is_tab = 0;
    } else {
        $$.index_ts = index;
        $$.type = table_symboles[index].type;
        $$.is_tab = (table_symboles[index].code == ENTITE_TABLEAU) ? 1 : 0;
        $$.tab_size = table_symboles[index].taille;
    }
}
;

expression : expression PLUS expression {
    // Vérification de type pour les opérations arithmétiques
    $$ = $1 + $3;  // Simplifié pour l'exemple
}
            | expression MINUS expression {
    $$ = $1 - $3;
}
            | expression MULT expression {
    $$ = $1 * $3;
}
            | expression DIV expression {
    if ($3 == 0) {
        yyerror("Erreur sémantique: Division par zéro");
        $$ = 0;
    } else {
        $$ = $1 / $3;
    }
}
            | LPAREN expression RPAREN {
    $$ = $2;
}
            | idf_use {
    $$ = 0;  // Simplifié
}
            | idf_use LBRACKET expression RBRACKET {
    // Vérification d'accès à un tableau
    if (!$1.is_tab) {
        yyerror("Erreur sémantique: Variable simple utilisée comme un tableau");
    }
    $$ = 0;  // Simplifié
}
            | INT_VAL {
    $$ = $1;
}
            | FLOAT_VAL {
    $$ = (int)$1;  // Conversion simplifiée pour l'exemple
}
;

condition : expression LT expression {
    $$ = ($1 < $3) ? 1 : 0;
}
          | expression GT expression {
    $$ = ($1 > $3) ? 1 : 0;
}
          | expression LE expression {
    $$ = ($1 <= $3) ? 1 : 0;
}
          | expression GE expression {
    $$ = ($1 >= $3) ? 1 : 0;
}
          | expression EQ expression {
    $$ = ($1 == $3) ? 1 : 0;
}
          | expression NE expression {
    $$ = ($1 != $3) ? 1 : 0;
}
          | LPAREN condition AND condition RPAREN {
    $$ = ($2 && $4) ? 1 : 0;
}
          | LPAREN condition OR condition RPAREN {
    $$ = ($2 || $4) ? 1 : 0;
}
          | NOT LPAREN condition RPAREN {
    $$ = (!$3) ? 1 : 0;
}
;

bloc_instruction : LBRACE instructions RBRACE
;

instruction_if : IF LPAREN condition RPAREN THEN bloc_instruction %prec LOWER_THAN_ELSE {
    printf("Condition IF\n");
}
               | IF LPAREN condition RPAREN THEN bloc_instruction ELSE bloc_instruction {
    printf("Condition IF-ELSE\n");
}
;

boucle : DO bloc_instruction WHILE LPAREN condition RPAREN SEMICOLON {
    printf("Boucle DO-WHILE\n");
}
       | FOR IDF FROM expression TO expression STEP expression bloc_instruction {
    // Vérification que l'identifiant est déclaré et est une variable simple
    int index = rechercher_symbole($2);
    if (index == -1) {
        yyerror("Erreur sémantique: Variable d'itération non déclarée");
    } else if (table_symboles[index].code == ENTITE_CONSTANTE) {
        yyerror("Erreur sémantique: Variable d'itération ne peut pas être une constante");
    } else if (table_symboles[index].code == ENTITE_TABLEAU) {
        yyerror("Erreur sémantique: Variable d'itération ne peut pas être un tableau");
    }
    printf("Boucle FOR\n");
}
       | WHILE LPAREN condition RPAREN bloc_instruction {
    printf("Boucle WHILE\n");
}
;

io_instruction : INPUT LPAREN idf_use RPAREN SEMICOLON {
    printf("Input\n");
}
               | OUTPUT LPAREN STRING_VAL RPAREN SEMICOLON {
    printf("Output chaîne\n");
}
               | OUTPUT LPAREN STRING_VAL COMMA expression RPAREN SEMICOLON {
    printf("Output chaîne et expression\n");
}
               | OUTPUT LPAREN expression RPAREN SEMICOLON {
    printf("Output expression\n");
}
;

commentaire : COMMENTAIRE_LIGNE {
    printf("Commentaire sur une ligne\n");
}
            | COMMENTAIRE_BLOC {
    printf("Commentaire sur plusieurs lignes\n");
}
;

%%

void yyerror(const char *msg) {
    fprintf(stderr, "Erreur syntaxique (ligne %d, colonne %d): %s\n", ligne, colonne, msg);
}

int main(int argc, char **argv) {
    extern FILE *yyin;
    
    // Initialiser la table des symboles
    initialiser_table_symboles();
    
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier %s\n", argv[1]);
            exit(1);
        }
    } else {
        yyin = stdin;
    }
    
    printf("Démarrage de l'analyse syntaxique...\n");
    yyparse();
    
    return 0;
}



