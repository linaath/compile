#ifndef TS_H
#define TS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Types de symboles
typedef enum {
    TYPE_ENTIER,
    TYPE_REEL,
    TYPE_TABLEAU_ENTIER,
    TYPE_TABLEAU_REEL,
    TYPE_UNDEFINED
} type_symbole;

// Codes d'entités
typedef enum {
    ENTITE_VARIABLE,
    ENTITE_CONSTANTE,
    ENTITE_TABLEAU,
    ENTITE_MOTCLE,
    ENTITE_SEPARATEUR
} code_entite;

// Structure pour la table des symboles des identificateurs et constantes
typedef struct {
    int state;              // 0: libre, 1: occupé
    char name[20];          // Nom de l'entité
    char code[20];          // Code de l'entité (IDF, CONST, etc.)
    char type[20];          // Type de l'entité (integer, reel, etc.)
    char val[20];           // Valeur de l'entité (pour les constantes)
    int tab_size;           // Taille du tableau (pour les tableaux)
} TypeTS;

// Structure pour les tables des mots clés et séparateurs
typedef struct {
    int state;              // 0: libre, 1: occupé
    char name[20];          // Nom de l'entité
    char code[20];          // Code de l'entité
} TypeSM;

// Déclaration des tables de symboles
extern TypeTS TS[200];             // Table des symboles pour les IDF et constantes
extern TypeSM tabM[50];            // Table des symboles pour les mots clés
extern TypeSM tabS[50];            // Table des symboles pour les séparateurs

// Fonctions de gestion des tables de symboles
void initialization();
void rechercher(char entite[], char code[], char type[], char val[], int y);
void inserer(char entite[], char code[], char type[], char val[], int i, int y);
void set_tab_size(int index, int size);
void afficher();

// Fonctions de recherche spécifiques aux types de tables
int recherche_idf_declared(char entite[]);
int recherche_motcle(char entite[]);
int recherche_separateur(char entite[]);

#endif // TS_H
