%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "syntax.tab.h"
#include "ts.h"
void yyerror(const char *msg);
int ligne = 1;
int colonne = 1;

#define MIN_INT -32768
#define MAX_INT 32767
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
    
    char val_str[20];
    sprintf(val_str, "%d", val);
    rechercher(yytext, "CONST", "Int", val_str, 1);
    
    free(inner);
    colonne += yyleng; 
    printf("Nombre entier signé : %s\n", yytext);
    return INT_VAL;
}

{reel_signe}    { 
    char *inner = strdup(yytext + 1); 
    inner[strlen(inner) - 1] = '\0';  
    yylval.fval = atof(inner);
    
    char val_str[20];
    sprintf(val_str, "%f", yylval.fval);
    rechercher(yytext, "CONST", "Float", val_str, 1);
    
    free(inner);
    colonne += yyleng; 
    printf("Nombre reel signé : %s\n", yytext);
    return FLOAT_VAL;
}

"MainPrgm"      { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return MAINPRGM; }
"Var"           { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return VAR; }
"BeginPg"       { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return BEGINPG; }
"EndPg"         { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return ENDPG; }
"let"           { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return LET; }
"@define"       { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return DEFINE; }
"Const"         { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return CONST; }
"Int"           { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return INT_TYPE; }
"Float"         { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return FLOAT_TYPE; }
"if"            { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return IF; }
"then"          { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return THEN; }
"else"          { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return ELSE; }
"do"            { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return DO; }
"while"         { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return WHILE; }
"for"           { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return FOR; }
"from"          { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return FROM; }
"to"            { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return TO; }
"step"          { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return STEP; }
"input"         { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return INPUT; }
"output"        { rechercher(yytext, "Mot-cle", "", "", 2); colonne += yyleng; return OUTPUT; }

{entier} { 
    int val = atoi(yytext);
    if (val < MIN_INT || val > MAX_INT) {
        yyerror("Erreur lexicale: Valeur entière hors limites (-32768 à 32767)");
        exit(1);
    }
    
    char val_str[20];
    sprintf(val_str, "%d", val);
    rechercher(yytext, "CONST", "Int", val_str, 1);
    
    yylval.ival = val;
    colonne += yyleng; 
    printf("Nombre entier : %s\n", yytext);
    return INT_VAL;
}

{reel} { 
    double val = atof(yytext);
    
    char val_str[20];
    sprintf(val_str, "%f", val);
    rechercher(yytext, "CONST", "Float", val_str, 1);
    
    yylval.fval = val;
    colonne += yyleng; 
    printf("Nombre reel : %s\n", yytext);
    return FLOAT_VAL;
}

":"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return COLON; }
";"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return SEMICOLON; }
","             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return COMMA; }
"["             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return LBRACKET; }
"]"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return RBRACKET; }
"="             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return EQUALS; }
":="            { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return ASSIGN; }
"("             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return LPAREN; }
")"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return RPAREN; }
"{"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return LBRACE; }
"}"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return RBRACE; }
"+"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return PLUS; }
"-"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return MINUS; }
"*"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return MULT; }
"/"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return DIV; }
"<="            { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return LE; }
">="            { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return GE; }
"=="            { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return EQ; }
"!="            { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return NE; }
"<"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return LT; }
">"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return GT; }
"AND"           { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return AND; }
"OR"            { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return OR; }
"!"             { rechercher(yytext, "Separateur", "", "", 3); colonne += yyleng; return NOT; }

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
    
    // Par défaut, on l'insère comme IDF, le type sera défini plus tard dans l'analyse syntaxique
    rechercher(yytext, "IDF", "", "", 1);
    
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
    initialization();
    
    int token;
    while ((token = yylex()) != 0) {
        printf("Token: %d, Lexeme: %s, Ligne: %d, Colonne: %d\n", 
               token, yytext, ligne, colonne);
    }
    
    afficher(); // Afficher la table des symboles à la fin
    return 0;
}
