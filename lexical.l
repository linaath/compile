%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
  
int ligne = 1;
int colonne = 1;

#define MIN_INT -32768
#define MAX_INT 32767

typedef union {
    int ival;
    double fval;
    char* sval;
} YYSTYPE;
YYSTYPE yylval;

void yyerror(const char *msg) {
    fprintf(stderr, "Erreur lexicale (ligne %d, colonne %d): %s\n", ligne, colonne, msg);
}
%}

%option noyywrap


lettre         [A-Za-z]
chiffre        [0-9]
IDF            {lettre}({lettre}|{chiffre}|_)*
entier         {chiffre}+
reel           {chiffre}+\.[0-9]+
nombre_parenthese "("[+-]?{chiffre}+")"
reel_parenthese  "("[+-]?{chiffre}+\.{chiffre}+")"
comment_ligne "<"[ ]*"!-"[^\n]*"-!"[ ]*">"
comment_bloc  "{--"([^-]|"-"[^-]|"\n")*"--}"
chaine         \"[^\"]*\"

%%


[ \t]+          { colonne += yyleng; }  
\n             { ligne++; colonne = 1; } 
{comment_ligne} {  
    colonne += yyleng; 
     printf("Commentaire ligne : %s\n", yytext);
}
{comment_bloc}  { 
    int i;
    for(i = 0; i < yyleng; i++){
        if(yytext[i]=='\n'){
            ligne++;
            colonne = 1;
        } else {
            colonne++;

        }
    }
     printf("Commentaire bloc simple : %s\n", yytext);
}
{nombre_parenthese} { 
   
    char *inner = strdup(yytext + 1); // Sauter la première parenthèse
    inner[strlen(inner) - 1] = '\0';  // Supprimer la dernière parenthèse
    int val = atoi(inner);
    if (val < MIN_INT || val > MAX_INT) {
        yyerror("Valeur entière hors limites (-32768 à 32767)");
        exit(1);
    }
    yylval.ival = val;
    free(inner);
    colonne += yyleng; 
    printf("Nombre entier parenthese : %s\n", yytext);
}
{reel_parenthese} { 
    // Extraire le nombre entre parenthèses
    char *inner = strdup(yytext + 1); // Sauter la première parenthèse
    inner[strlen(inner) - 1] = '\0';  // Supprimer la dernière parenthèse
    yylval.fval = atof(inner);
    free(inner);
    colonne += yyleng; 
    printf("Nombre reel parenthese : %s\n", yytext);
}
"MainPrgm"      { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"Var"           { colonne += yyleng; printf("Mot-cle: %s\n", yytext); }
"BeginPg"       { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"EndPg"         { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }

"let"           { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"@define"       { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"Const"         { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }

"Int"           { colonne += yyleng; printf("Type: %s\n", yytext);  }
"Float"         { colonne += yyleng; printf("Type: %s\n", yytext);}

{entier} { 
    int val = atoi(yytext);
    if (val < MIN_INT || val > MAX_INT) {
        yyerror("Valeur entière hors limites (-32768 à 32767)");
        exit(1);
    }
    yylval.ival = val;
    colonne += yyleng; 
    printf("Nombre entier : %s\n", yytext);
}

{reel} { 
    yylval.fval = atof(yytext);
    colonne += yyleng; 
    printf("Nombre reel : %s\n", yytext);

}


":"             { colonne += yyleng; printf("Symbole: %s\n", yytext); }
";"             { colonne += yyleng; printf("Symbole: %s\n", yytext);  }
","             { colonne += yyleng; printf("Symbole: %s\n", yytext);  }
"["             { colonne += yyleng; printf("Symbole: %s\n", yytext);  }
"]"             { colonne += yyleng; printf("Symbole: %s\n", yytext);  }
"="            { colonne += yyleng; printf("Symbole: %s\n", yytext);  }

":="            { colonne += yyleng; printf("Operateur d'affectation: %s\n", yytext);  }
"("             { colonne += yyleng; printf("Parenthese ouvrante: %s\n", yytext);  }
")"             { colonne += yyleng; printf("Parenthese fermante: %s\n", yytext);  }
"{"             { colonne += yyleng; printf("Accolade ouvrante: %s\n", yytext);  }
"}"             { colonne += yyleng; printf("Accolade fermante: %s\n", yytext);  }


"if"            { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"then"          { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"else"          { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"do"            { colonne += yyleng; printf("Mot-cle: %s\n", yytext); }
"while"         { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"for"           { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"from"          { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"to"            { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"step"          { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"input"         { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }
"output"        { colonne += yyleng; printf("Mot-cle: %s\n", yytext);  }


"AND"            { colonne += yyleng; printf("Operateur logique: %s\n", yytext);  }
"OR"            { colonne += yyleng; printf("Operateur logique: %s\n", yytext);  }
"!"             { colonne += yyleng; printf("Operateur logique: %s\n", yytext);  }
"+"             { colonne += yyleng; printf("Operateur arithmétique: %s\n", yytext);  }
"-"             { colonne += yyleng; printf("Operateur arithmétique: %s\n", yytext); }
"*"             { colonne += yyleng; printf("Operateur arithmétique: %s\n", yytext);  }
"/"             { colonne += yyleng; printf("Operateur arithmétique: %s\n", yytext); }
"<="            { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext);  }
">="            { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext);  }
"=="            { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext);  }
"!="            { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext); }
"<"             { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext); }
">"             { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext);  }


{chaine} {
    yylval.sval = strdup(yytext);
    colonne += yyleng;
    printf("Chaine : %s\n", yytext);
  
}


{IDF} {
    colonne += yyleng;
    if (strlen(yytext) > 14) {
        yyerror("Identificateur trop long (max 14 caractères)");
        exit(1);
    }
    if (yytext[strlen(yytext) - 1] == '_') {
        yyerror("Identificateur ne peut pas se terminer par un underscore");
        exit(1);
    }
    int i;
    for ( i = 0; i < (int)strlen(yytext) - 1; i++) {
        if (yytext[i] == '_' && yytext[i+1] == '_') {
            yyerror("Identificateur contient des underscores consécutifs");
            exit(1);
        }
    }
    yylval.sval = strdup(yytext);
    printf("Identificateur : %s\n", yytext); 
      }
. {
    yyerror("Caractere non reconnu");
    colonne += yyleng;
}

%%

int main_lex(int argc, char** argv) {
    extern FILE *yyin;
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier %s\n", argv[1]);
            exit(1);
        }
    } else {
        yyin = stdin;
    }
    
    int token;
    while ((token = yylex()) != 0) {
        printf("Token: %d, Lexème: %s, Ligne: %d, Colonne: %d\n", 
               token, yytext, ligne, colonne);
    }
    
    return 0;
}

