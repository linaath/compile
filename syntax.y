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

// Variables globales pour le passage d'informations entre règles
int current_type; 
int is_const;      
int tab_size;      

// Fonction de vérification de compatibilité de types
int type_check(int type1, int type2) {
    if (type1 == TYPE_UNDEFINED || type2 == TYPE_UNDEFINED)
        return 1; 
    if ((type1 == TYPE_ENTIER && type2 == TYPE_ENTIER) || 
        (type1 == TYPE_REEL && type2 == TYPE_REEL))
        return 1;
    if (type1 == TYPE_REEL && type2 == TYPE_ENTIER)
        return 1;
    if ((type1 == TYPE_TABLEAU_ENTIER && type2 == TYPE_ENTIER) ||
        (type1 == TYPE_TABLEAU_REEL && type2 == TYPE_REEL))
        return 1;
    if (type1 == TYPE_TABLEAU_REEL && type2 == TYPE_ENTIER)
        return 1;
        
    return 0;
}

// Déterminer le type résultant d'une expression
int get_expr_type(int type1, int type2, char op) {
    if (type1 == TYPE_REEL || type2 == TYPE_REEL)
        return TYPE_REEL;
    else
        return TYPE_ENTIER;
}
%}

%union {
    int ival;
    double fval;
    char* sval;
    struct {
        int type;       
        int is_tab;     
        int index_ts;  
        int tab_size;  
        int val_int;
        double val_float;
    } info_var;
}

%type <info_var> expression condition type valeur liste_idf idf_use
%token MAINPRGM VAR BEGINPG ENDPG LET DEFINE CONST INT_TYPE FLOAT_TYPE 
%token IF THEN ELSE DO WHILE FOR FROM TO STEP INPUT OUTPUT
%token AND OR NOT PLUS MINUS MULT DIV LT GT LE GE EQ NE 
%token ASSIGN COLON SEMICOLON COMMA LBRACKET RBRACKET EQUALS LPAREN RPAREN LBRACE RBRACE
%token <sval> IDF
%token <ival> INT_VAL
%token <fval> FLOAT_VAL
%token <sval> STRING_VAL
%token COMMENTAIRE_LIGNE COMMENTAIRE_BLOC

%left OR
%left AND
%left NOT
%left LT GT LE GE EQ NE
%left PLUS MINUS
%left MULT DIV
%left ASSIGN
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%start programme

%%

programme : MAINPRGM IDF SEMICOLON bloc { 
    printf("Programme syntaxiquement correct !\n"); 
    afficher(); 
}
;

bloc : VAR declarations BEGINPG LBRACE instructions RBRACE ENDPG SEMICOLON
;

declarations : declarations declaration
             | declarations commentaire
             | /* vide */
             ;

declaration : LET liste_idf COLON type SEMICOLON { 
    // Mise à jour des types pour les variables simples
    int i;
    for (i = 0; i < 200; i++) {
        if (TS[i].state == 1 && strcmp(TS[i].type, "") == 0) {
            if ($4.type == TYPE_ENTIER) {
                strcpy(TS[i].type, "Int");
            } else if ($4.type == TYPE_REEL) {
                strcpy(TS[i].type, "Float");
            }
        }
    }
    printf("Declaration de variables simples\n"); 
}
            | LET liste_idf COLON LBRACKET type SEMICOLON INT_VAL RBRACKET SEMICOLON { 
    if ($7 <= 0) {
        yyerror("Erreur semantique: La taille du tableau doit etre positive");
    }
    tab_size = $7;
    
    // Mise à jour des types et tailles pour les tableaux
    int i;
    for (i = 0; i < 200; i++) {
        if (TS[i].state == 1 && strcmp(TS[i].type, "") == 0) {
            if ($5.type == TYPE_ENTIER) {
                strcpy(TS[i].type, "TableauInt");
            } else if ($5.type == TYPE_REEL) {
                strcpy(TS[i].type, "TableauFloat");
            }
            set_tab_size(i, tab_size);
        }
    }
    printf("Declaration de tableau de taille %d\n", tab_size); 
}
            | DEFINE CONST IDF COLON type EQUALS valeur SEMICOLON { 
    int index = recherche_idf_declared($3);
    if (index == -1) {
        char type_str[20] = "";
        char val_str[20] = "";
        if ($5.type == TYPE_ENTIER) {
            strcpy(type_str, "Int");
            sprintf(val_str, "%d", $7.val_int);  
        } else if ($5.type == TYPE_REEL) {
            strcpy(type_str, "Float");
            sprintf(val_str, "%f", $7.val_float); 
        }
        
        rechercher($3, "CONST", type_str, val_str, 1);
    } else {
        yyerror("Erreur sémantique: Constante deja declaree");
    }
    printf("Déclaration de constante %s\n", $3); 
}
;

liste_idf : liste_idf COMMA IDF { 
    int index = recherche_idf_declared($3);
    if (index == -1) {
        // Ajout à la table des symboles avec un type vide pour l'instant
        rechercher($3, "IDF", "", "", 1);
    } else {
        yyerror("Erreur semantique: Variable deja declaree");
    }
    printf("Variable: %s\n", $3);
    $$ = $1;  
}
          | IDF { 
    int index = recherche_idf_declared($1);
    if (index == -1) {
        // Ajout à la table des symboles avec un type vide pour l'instant
        rechercher($1, "IDF", "", "", 1);
        $$.index_ts = recherche_idf_declared($1);  // Récupérer l'index après insertion
        $$.type = current_type;
        $$.is_tab = 0;
        $$.tab_size = 0;
    } else {
        yyerror("Erreur sémantique: Variable deja declaree");
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
    $$.type = TYPE_ENTIER;
    $$.val_int = $1;
    printf("Constante entiere: %d\n", $1); 
}
        | FLOAT_VAL { 
    $$.type = TYPE_REEL;
    $$.val_float = $1;
    printf("Constante reelle: %f\n", $1); 
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
    int index = $1.index_ts;
    if (index >= 0) {
        if (strcmp(TS[index].code, "CONST") == 0) {
            yyerror("Erreur semantique: Impossible de modifier une constante");
        }
        if (!type_check($1.type, $3.type)) {
            yyerror("Erreur semantique: Types incompatibles dans l'affectation");
        }
    }
    printf("Affectation\n"); 
}
           | idf_use LBRACKET expression RBRACKET ASSIGN expression SEMICOLON {
    if ($1.index_ts >= 0) {
        if (!$1.is_tab) {
            yyerror("Erreur sémantique: Variable simple utilisée comme un tableau");
        } else {
            if ($3.type == TYPE_ENTIER) {
                int tab_size = $1.tab_size;
                // Vérification statique de l'indice si possible
                if ($3.val_int < 0 || ($3.val_int >= tab_size && tab_size > 0)) {
                    yyerror("Erreur semantique: Indice de tableau hors limites");
                }
            } else {
                yyerror("Erreur semantique: Indice de tableau doit etre un entier");
            }
            int elem_type = ($1.type == TYPE_TABLEAU_ENTIER) ? TYPE_ENTIER : TYPE_REEL;
            if (!type_check(elem_type, $6.type)) {
                yyerror("Erreur semantique: Types incompatibles dans l'affectation de tableau");
            }
        }
    } else {
        yyerror("Erreur semantique: Tableau non declare");
    }
    printf("Affectation a un element de tableau\n");
}
;

idf_use : IDF {
    int index = recherche_idf_declared($1);
    if (index == -1) {
        yyerror("Erreur semantique: Variable non declaree");
        $$.index_ts = -1;
        $$.type = TYPE_UNDEFINED;
        $$.is_tab = 0;
        $$.tab_size = 0;
    } else {
        $$.index_ts = index;
        if (strcmp(TS[index].type, "Int") == 0) {
            $$.type = TYPE_ENTIER;
            $$.is_tab = 0;
        } else if (strcmp(TS[index].type, "Float") == 0) {
            $$.type = TYPE_REEL;
            $$.is_tab = 0;
        } else if (strcmp(TS[index].type, "TableauInt") == 0) {
            $$.type = TYPE_TABLEAU_ENTIER;
            $$.is_tab = 1;
            $$.tab_size = TS[index].tab_size;
        } else if (strcmp(TS[index].type, "TableauFloat") == 0) {
            $$.type = TYPE_TABLEAU_REEL;
            $$.is_tab = 1;
            $$.tab_size = TS[index].tab_size;
        } else if (strcmp(TS[index].type, "") == 0) {
            // Type non encore défini
            yyerror("Erreur semantique: Variable utilisée avant d'être typée");
            $$.type = TYPE_UNDEFINED;
        }
    }
}
;

expression : expression PLUS expression {
    $$.type = get_expr_type($1.type, $3.type, '+');
    if ($1.type == TYPE_ENTIER && $3.type == TYPE_ENTIER) {
        $$.val_int = $1.val_int + $3.val_int;
    } else {
        $$.val_float = ($1.type == TYPE_ENTIER ? $1.val_int : $1.val_float) + 
                       ($3.type == TYPE_ENTIER ? $3.val_int : $3.val_float);
    }
}
            | expression MINUS expression {
    $$.type = get_expr_type($1.type, $3.type, '-');
    if ($1.type == TYPE_ENTIER && $3.type == TYPE_ENTIER) {
        $$.val_int = $1.val_int - $3.val_int;
    } else {
        $$.val_float = ($1.type == TYPE_ENTIER ? $1.val_int : $1.val_float) - 
                       ($3.type == TYPE_ENTIER ? $3.val_int : $3.val_float);
    }
}
            | expression MULT expression {
    $$.type = get_expr_type($1.type, $3.type, '*');
    if ($1.type == TYPE_ENTIER && $3.type == TYPE_ENTIER) {
        $$.val_int = $1.val_int * $3.val_int;
    } else {
        $$.val_float = ($1.type == TYPE_ENTIER ? $1.val_int : $1.val_float) * 
                       ($3.type == TYPE_ENTIER ? $3.val_int : $3.val_float);
    }
}
            | expression DIV expression {
    if (($3.type == TYPE_ENTIER && $3.val_int == 0) || 
        ($3.type == TYPE_REEL && $3.val_float == 0.0)) {
        yyerror("Erreur semantique: Division par zero");
        $$.type = TYPE_UNDEFINED;
    } else {
        $$.type = get_expr_type($1.type, $3.type, '/');
        if ($1.type == TYPE_ENTIER && $3.type == TYPE_ENTIER) {
            $$.val_int = $1.val_int / $3.val_int;
        } else {
            $$.val_float = ($1.type == TYPE_ENTIER ? $1.val_int : $1.val_float) / 
                           ($3.type == TYPE_ENTIER ? $3.val_int : $3.val_float);
        }
    }
}
            | LPAREN expression RPAREN {
    $$ = $2;
}
            | idf_use {
    $$.type = $1.type;
    int index = $1.index_ts;
    if (index >= 0) {
        if (strcmp(TS[index].code, "CONST") == 0) {
            // Pour les constantes, récupérer leur valeur
            if (strcmp(TS[index].type, "Int") == 0) {
                $$.val_int = atoi(TS[index].val);
                $$.type = TYPE_ENTIER;
            } else if (strcmp(TS[index].type, "Float") == 0) {
                $$.val_float = atof(TS[index].val);
                $$.type = TYPE_REEL;
            }
        }
    }
}
            | idf_use LBRACKET expression RBRACKET {
    if (!$1.is_tab) {
        yyerror("Erreur sémantique: Variable simple utilisée comme un tableau");
        $$.type = TYPE_UNDEFINED;
    } else {
        if ($3.type == TYPE_ENTIER) {
            int index = $1.index_ts;
            if (index >= 0) {
                int tab_size = $1.tab_size;
                // Vérification statique de l'indice si possible
                if ($3.val_int < 0 || ($3.val_int >= tab_size && tab_size > 0)) {
                    yyerror("Erreur semantique: Indice de tableau hors limites");
                }
            }
        } else {
            yyerror("Erreur semantique: Indice de tableau doit etre un entier");
        }
        
        if ($1.type == TYPE_TABLEAU_ENTIER) {
            $$.type = TYPE_ENTIER;
        } else if ($1.type == TYPE_TABLEAU_REEL) {
            $$.type = TYPE_REEL;
        } else {
            $$.type = TYPE_UNDEFINED;
        }
    }
}
            | INT_VAL {
    $$.type = TYPE_ENTIER;
    $$.val_int = $1;
}
            | FLOAT_VAL {
    $$.type = TYPE_REEL;
    $$.val_float = $1;
}
;

condition : expression LT expression {
    $$.type = TYPE_ENTIER; 
    $$.val_int = 0;  
}
          | expression GT expression {
    $$.type = TYPE_ENTIER;
    $$.val_int = 0;
}
          | expression LE expression {
    $$.type = TYPE_ENTIER;
    $$.val_int = 0;
}
          | expression GE expression {
    $$.type = TYPE_ENTIER;
    $$.val_int = 0;
}
          | expression EQ expression {
    $$.type = TYPE_ENTIER;
    $$.val_int = 0;
}
          | expression NE expression {
    $$.type = TYPE_ENTIER;
    $$.val_int = 0;
}
          | LPAREN condition AND condition RPAREN {
    $$.type = TYPE_ENTIER;
    $$.val_int = 0;
}
          | LPAREN condition OR condition RPAREN {
    $$.type = TYPE_ENTIER;
    $$.val_int = 0;
}
          | NOT LPAREN condition RPAREN {
    $$.type = TYPE_ENTIER;
    $$.val_int = 0;
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
    int index = recherche_idf_declared($2);
    if (index == -1) {
        yyerror("Erreur semantique: Variable d'iteration non declaree");
    } else if (strcmp(TS[index].code, "CONST") == 0) {
        yyerror("Erreur semantique: Variable d'iteration ne peut pas etre une constante");
    } else if (strstr(TS[index].type, "Tableau") != NULL) {
        yyerror("Erreur semantique: Variable d'iteration ne peut pas etre un tableau");
    }
    
    // Vérifier que la variable de step est un entier
    if ($8.type != TYPE_ENTIER) {
        yyerror("Erreur semantique: Le pas de la boucle FOR doit être un entier");
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
    printf("Output chaine\n");
}
               | OUTPUT LPAREN STRING_VAL COMMA expression RPAREN SEMICOLON {
    printf("Output chaine et expression\n");
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
    fprintf(stderr, "Erreur (ligne %d, colonne %d): %s\n", ligne, colonne, msg);
}

int main(int argc, char **argv) {
    extern FILE *yyin;
    initialization();
    
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier %s\n", argv[1]);
            exit(1);
        }
    } else {
        yyin = stdin;
    }
    
    printf("Demarrage de l'analyse syntaxique...\n");
    yyparse();
    
    return 0;
}
