%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "syntax.tab.h"
#include "ts.h"

int ligne = 1;
int colonne = 1;

#define MIN_INT -32768
#define MAX_INT 32767


extern int inserer_symbole(char *nom, code_entite code, type_symbole type, int taille, int ligne, int colonne);
extern int rechercher_symbole(char* lexeme);
extern void inserer_valeur_entier(int index, int val);
extern void inserer_valeur_reel(int index, double val);
extern void afficher_table_symboles();
%}

%option noyywrap

lettre_maj_min       [a-zA-Z]
lettre [a-z]
chiffre        [0-9]
idf            {lettre_maj_min}({lettre}|{chiffre}|_)*
entier         {chiffre}+
reel           {chiffre}+\.{chiffre}+
nombre_signe   "("{signe}?{entier}")"
reel_signe     "("{signe}?{reel}")"
signe          [+-]
comment_ligne  "<"[ ]*"!-"[^-]*"-!"[ ]*">"
comment_bloc    "{--"([^-]|"-"[^-]|"\n")*"--}"
chaine         \"[^\"]*\"

%%

{nombre_signe}  { 
    char *inner = strdup(yytext + 1); 
    inner[strlen(inner) - 1] = '\0'; 
    int val = atoi(inner);
    if (val < MIN_INT || val > MAX_INT) {
        yyerror("Erreur lexicale: Valeur entière hors limites (-32768 à 32767)");
        exit(1);
    }
    yylval.ival = val;
    
    int index = inserer_symbole(yytext, ENTITE_CONSTANTE, TYPE_ENTIER, 1, ligne, colonne);
    if (index >= 0) {
        inserer_valeur_entier(index, val);
    }
    
    free(inner);
    colonne += yyleng; 
    printf("Nombre entier signé : %s\n", yytext);
    return INT_VAL;
}

{reel_signe}    { 
    char *inner = strdup(yytext + 1); 
    inner[strlen(inner) - 1] = '\0';  
    yylval.fval = atof(inner);
    
    int index = inserer_symbole(yytext, ENTITE_CONSTANTE, TYPE_REEL, 1, ligne, colonne);
    if (index >= 0) {
        inserer_valeur_reel(index, yylval.fval);
    }
    
    free(inner);
    colonne += yyleng; 
    printf("Nombre reel signé : %s\n", yytext);
    return FLOAT_VAL;
}

"MainPrgm"      { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return MAINPRGM; }
"Var"           { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return VAR; }
"BeginPg"       { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return BEGINPG; }
"EndPg"         { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return ENDPG; }

"let"           { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return LET; }
"@define"       { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return DEFINE; }
"Const"         { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return CONST; }

"Int"           { colonne += yyleng; printf("Type: %s\n", yytext); return INT_TYPE; }
"Float"         { colonne += yyleng; printf("Type: %s\n", yytext); return FLOAT_TYPE; }

{entier} { 
    int val = atoi(yytext);
    if (val < MIN_INT || val > MAX_INT) {
        yyerror("Erreur lexicale: Valeur entière hors limites (-32768 à 32767)");
        exit(1);
    }
    int index = inserer_symbole(yytext, ENTITE_CONSTANTE, TYPE_ENTIER, 1, ligne, colonne);
    if (index >= 0) {
        inserer_valeur_entier(index, val);
    }
    yylval.ival = val;
    colonne += yyleng; 
    printf("Nombre entier : %s\n", yytext);
    return INT_VAL;
}

{reel} { 
    double val = atof(yytext);
    yylval.fval = val;
    int index = inserer_symbole(yytext, ENTITE_CONSTANTE, TYPE_REEL, 1, ligne, colonne);
    if (index >= 0) {
        inserer_valeur_reel(index, val);
    }
    colonne += yyleng; 
    printf("Nombre reel : %s\n", yytext);
    return FLOAT_VAL;
}

":"             { colonne += yyleng; printf("Symbole: %s\n", yytext); return COLON; }
";"             { colonne += yyleng; printf("Symbole: %s\n", yytext); return SEMICOLON; }
","             { colonne += yyleng; printf("Symbole: %s\n", yytext); return COMMA; }
"["             { colonne += yyleng; printf("Symbole: %s\n", yytext); return LBRACKET; }
"]"             { colonne += yyleng; printf("Symbole: %s\n", yytext); return RBRACKET; }
"="             { colonne += yyleng; printf("Symbole: %s\n", yytext); return EQUALS; }

":="            { colonne += yyleng; printf("Operateur d'affectation: %s\n", yytext); return ASSIGN; }
"("             { colonne += yyleng; printf("Parenthese ouvrante: %s\n", yytext); return LPAREN; }
")"             { colonne += yyleng; printf("Parenthese fermante: %s\n", yytext); return RPAREN; }
"{"             { colonne += yyleng; printf("Accolade ouvrante: %s\n", yytext); return LBRACE; }
"}"             { colonne += yyleng; printf("Accolade fermante: %s\n", yytext); return RBRACE; }

"if"            { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return IF; }
"then"          { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return THEN; }
"else"          { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return ELSE; }
"do"            { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return DO; }
"while"         { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return WHILE; }
"for"           { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return FOR; }
"from"          { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return FROM; }
"to"            { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return TO; }
"step"          { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return STEP; }
"input"         { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return INPUT; }
"output"        { colonne += yyleng; printf("Mot-cle: %s\n", yytext); return OUTPUT; }

"AND"           { colonne += yyleng; printf("Operateur logique: %s\n", yytext); return AND; }
"OR"            { colonne += yyleng; printf("Operateur logique: %s\n", yytext); return OR; }
"!"             { colonne += yyleng; printf("Operateur logique: %s\n", yytext); return NOT; }
"+"             { colonne += yyleng; printf("Operateur arithmetique: %s\n", yytext); return PLUS; }
"-"             { colonne += yyleng; printf("Operateur arithmetique: %s\n", yytext); return MINUS; }
"*"             { colonne += yyleng; printf("Operateur arithmetique: %s\n", yytext); return MULT; }
"/"             { colonne += yyleng; printf("Operateur arithmetique: %s\n", yytext); return DIV; }
"<="            { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext); return LE; }
">="            { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext); return GE; }
"=="            { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext); return EQ; }
"!="            { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext); return NE; }
"<"             { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext); return LT; }
">"             { colonne += yyleng; printf("Operateur de comparaison: %s\n", yytext); return GT; }

{chaine} {
    yylval.sval = strdup(yytext);
    colonne += yyleng;
    printf("Chaine : %s\n", yytext);
    return STRING_VAL;
}

{idf} {
    colonne += yyleng;
    // Vérification des contraintes sur les identificateurs
    if (strlen(yytext) > 14) {
        yyerror("Erreur lexicale: Identificateur trop long (max 14 caractères)");
        exit(1);
    }
    if (yytext[strlen(yytext) - 1] == '_') {
        yyerror("Erreur lexicale: Identificateur ne peut pas se terminer par un underscore");
        exit(1);
    }
    int i;
    for (i = 0; i < (int)strlen(yytext) - 1; i++) {
        if (yytext[i] == '_' && yytext[i+1] == '_') {
            yyerror("Erreur lexicale: Identificateur contient des underscores consécutifs");
            exit(1);
        }
    }
    
  
    yylval.sval = strdup(yytext);
    printf("Identificateur : %s\n", yytext);
    
    return IDF;
}

{comment_ligne} {  
    colonne += yyleng; 
    printf("Commentaire ligne : %s\n", yytext);
    return COMMENTAIRE_LIGNE;
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
    printf("Commentaire bloc : %s\n", yytext);
    return COMMENTAIRE_BLOC;
}
[ \t]+          { colonne += yyleng; }  
\n              { ligne++; colonne = 1; } 

. {
    yyerror("Erreur lexicale: Caractere non reconnu");
    colonne += yyleng;
}

%%

/* Cette fonction est utile pour les tests lexicaux séparés */
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
    
    // Initialisation de la table des symboles
    initialiser_table_symboles();
    
    int token;
    while ((token = yylex()) != 0) {
        printf("Token: %d, Lexeme: %s, Ligne: %d, Colonne: %d\n", 
               token, yytext, ligne, colonne);
    }
    
    afficher_table_symboles(); // Afficher la table des symboles à la fin
    return 0;
}

