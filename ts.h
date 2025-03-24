/* ts.h - Définition des structures et fonctions pour la table des symboles */
#ifndef TS_H
#define TS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAILLE_TABLE 100
#define MAX_NOM 15

// Types d'entités possibles
typedef enum {
    ENTITE_VARIABLE,
    ENTITE_CONSTANTE,
    ENTITE_TABLEAU,
    ENTITE_MOT_CLE,
    ENTITE_SEPARATEUR
} code_entite;

// Types de données possibles
typedef enum {
    TYPE_ENTIER,
    TYPE_REEL,
    TYPE_TABLEAU_ENTIER,
    TYPE_TABLEAU_REEL
} type_symbole;

// Union pour stocker les valeurs
typedef union {
    int valeur_int;
    double valeur_float;
} valeur_union;

// Structure d'un symbole dans la table
typedef struct {
    int etat;                  // 0: libre, 1: occupé
    char nom[MAX_NOM];         // Nom du symbole
    code_entite code;          // Code de l'entité
    type_symbole type;         // Type du symbole
    int taille;                // Taille (1 pour variable simple, n pour tableau)
    valeur_union valeur;       // Valeur (pour constantes)
    int ligne;                 // Ligne de déclaration
    int colonne;               // Colonne de déclaration
} symbole;

// Variables globales (définies dans ts.c)
extern symbole table_symboles[TAILLE_TABLE];
extern int nb_symboles;

// Prototypes des fonctions
void initialiser_table_symboles();
int rechercher_symbole(char *nom);
int inserer_symbole(char *nom, code_entite code, type_symbole type, int taille, int ligne, int colonne);
void inserer_valeur_entier(int position, int valeur);
void inserer_valeur_reel(int position, double valeur);
char* get_type_string(type_symbole type);
char* get_code_string(code_entite code);
void afficher_table_symboles();

#endif /* TS_H */

