/* ts.c - Implémentation des fonctions de gestion de la table des symboles */
#include "ts.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h> // Add this for isdigit function

// Initialisation des variables globales
symbole table_symboles[TAILLE_TABLE];
int nb_symboles = 0;

/* Implémentation des fonctions */

// Fonction d'initialisation de la table des symboles
void initialiser_table_symboles() {
    int i;
    for (i = 0; i < TAILLE_TABLE; i++) {
        table_symboles[i].etat = 0;  // 0 indique que l'emplacement est libre
    }
    nb_symboles = 0;
}

// Recherche un symbole dans la table des symboles par son nom
int rechercher_symbole(char *nom) {
    int i;
    for (i = 0; i < TAILLE_TABLE; i++) {
        if (table_symboles[i].etat == 1 && strcmp(table_symboles[i].nom, nom) == 0) {
            return i;  // Retourne l'index si trouvé
        }
    }
    return -1;  // Non trouvé
}

// Insère un nouveau symbole dans la table
int inserer_symbole(char *nom, code_entite code, type_symbole type, int taille, int ligne, int colonne) {
    int pos = rechercher_symbole(nom);
    
    // If it's a literal (constant value), don't report duplicates as errors
    if (pos != -1) {
        // Only print warning for non-literals
        if (code != ENTITE_CONSTANTE || (nom[0] != '-' && !isdigit(nom[0]))) {
            printf(">>>> L'entité %s existe déjà à la ligne %d, colonne %d\n", 
                  nom, table_symboles[pos].ligne, table_symboles[pos].colonne);
        }
        return pos;
    }
    
    // Chercher un emplacement libre
    int i;
    for (i = 0; i < TAILLE_TABLE; i++) {
        if (table_symboles[i].etat == 0) {
            // Emplacement libre trouvé
            table_symboles[i].etat = 1;  // Marquer comme occupé
            strncpy(table_symboles[i].nom, nom, MAX_NOM - 1);
            table_symboles[i].nom[MAX_NOM - 1] = '\0';  // Assurer la terminaison
            table_symboles[i].code = code;
            table_symboles[i].type = type;
            table_symboles[i].taille = taille;
            table_symboles[i].ligne = ligne;
            table_symboles[i].colonne = colonne;
            
            nb_symboles++;
            return i;
        }
    }
    
    // Table pleine
    fprintf(stderr, "Erreur: Table des symboles pleine\n");
    return -1;
}

// Insère une valeur entière pour un symbole
void inserer_valeur_entier(int position, int valeur) {
    if (position >= 0 && position < TAILLE_TABLE && table_symboles[position].etat == 1) {
        table_symboles[position].valeur.valeur_int = valeur;
    }
}

// Insère une valeur réelle pour un symbole
void inserer_valeur_reel(int position, double valeur) {
    if (position >= 0 && position < TAILLE_TABLE && table_symboles[position].etat == 1) {
        table_symboles[position].valeur.valeur_float = valeur;
    }
}

// Obtient une chaîne correspondant au type
char* get_type_string(type_symbole type) {
    switch (type) {
        case TYPE_ENTIER: return "Entier";
        case TYPE_REEL: return "Reel";
        case TYPE_TABLEAU_ENTIER: return "Tableau d'entiers";
        case TYPE_TABLEAU_REEL: return "Tableau de reels";
        default: return "Type inconnu";
    }
}

// Obtient une chaîne correspondant au code d'entité
char* get_code_string(code_entite code) {
    switch (code) {
        case ENTITE_VARIABLE: return "Variable";
        case ENTITE_CONSTANTE: return "Constante";
        case ENTITE_TABLEAU: return "Tableau";
        case ENTITE_MOT_CLE: return "Mot clé";
        case ENTITE_SEPARATEUR: return "Séparateur";
        default: return "Entité inconnue";
    }
}

// Affiche le contenu de la table des symboles
void afficher_table_symboles() {
    printf("\n/***************Table des symboles*************/\n");
    printf("_________________________________________________________________\n");
    printf("| %-15s | %-12s | %-15s | %-6s | %-12s | %-5s | %-5s |\n", 
           "Nom", "Code", "Type", "Taille", "Valeur", "Ligne", "Col");
    printf("_________________________________________________________________\n");
    
    int i;
    for (i = 0; i < TAILLE_TABLE; i++) {
        if (table_symboles[i].etat == 1) {
            symbole s = table_symboles[i];
            char valeur[20] = "---";
            
            if (s.code == ENTITE_CONSTANTE) {
                if (s.type == TYPE_ENTIER || s.type == TYPE_TABLEAU_ENTIER) {
                    sprintf(valeur, "%d", s.valeur.valeur_int);
                } else if (s.type == TYPE_REEL || s.type == TYPE_TABLEAU_REEL) {
                    sprintf(valeur, "%.2f", s.valeur.valeur_float);
                }
            }
            
            printf("| %-15s | %-12s | %-15s | %-6d | %-12s | %-5d | %-5d |\n", 
                   s.nom, get_code_string(s.code), get_type_string(s.type),
                   s.taille, valeur, s.ligne, s.colonne);
        }
    }
    printf("_________________________________________________________________\n");
}
