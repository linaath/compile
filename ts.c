#include "ts.h"

// Déclaration et initialisation des tables de symboles
TypeTS TS[200];
TypeSM tabM[50];
TypeSM tabS[50];

// Initialisation des tables de symboles
void initialization() {
    int i;
    
    // TS des constantes & variables
    for (i = 0; i < 200; i++) {
        TS[i].state = 0;
    }
    
    // TS des Mots clés & Séparateurs
    for (i = 0; i < 50; i++) {
        tabM[i].state = 0;
        tabS[i].state = 0;
    }
    
    printf("Tables des symboles initialisées\n");
}
// Dans ts.c, ajouter cette fonction
void set_tab_size(int index, int size) {
    if (index >= 0 && index < 200 && TS[index].state == 1) {
        TS[index].tab_size = size;
    }
}
// Recherche d'une entité dans les tables de symboles
void rechercher(char entite[], char code[], char type[], char val[], int y) {
    int i;
    
    switch(y) {
            case 1: // Table des IDF et CONST
                for (i = 0; ((i < 200) && (TS[i].state == 1) && (strcmp(entite, TS[i].name) != 0)); i++);
                
                if (i < 200) {
                    if (TS[i].state == 0) {
                        // Nouvel identifiant, l'ajouter
                        inserer(entite, code, type, val, i, 1);
                    } else if (strcmp(entite, TS[i].name) == 0) {
                        // L'identifiant existe déjà, mettre à jour les informations si nécessaire
                        // Ne pas considérer comme erreur si l'identifiant n'a pas encore de type défini
                        if (strcmp(type, "") != 0 && strcmp(TS[i].type, "") == 0) {
                            strcpy(TS[i].type, type);
                        }
                        if (strcmp(code, "IDF") == 0 && strcmp(TS[i].code, "CONST") == 0) {
                            // Tentative de redéclarer une constante comme variable
                            printf("Erreur: Tentative de redéclaration de la constante %s\n", entite);
                        }
                        // Pas d'erreur pour une IDF dans la phase lexicale
                    }
                }
                break;
                
            
        case 2: // Table des mots clés
            for (i = 0; ((i < 50) && (tabM[i].state == 1) && (strcmp(entite, tabM[i].name) != 0)); i++);
            
            if (i < 50 && (tabM[i].state == 0 || strcmp(entite, tabM[i].name) != 0)) {
                inserer(entite, code, type, val, i, 2);
            } 
            break;
            
        case 3: // Table des séparateurs
            for (i = 0; ((i < 50) && (tabS[i].state == 1) && (strcmp(entite, tabS[i].name) != 0)); i++);
            
            if (i < 50 && (tabS[i].state == 0 || strcmp(entite, tabS[i].name) != 0)) {
                inserer(entite, code, type, val, i, 3);
            } 
            break;
    }
}

// Insertion d'une entité dans une table de symboles
void inserer(char entite[], char code[], char type[], char val[], int i, int y) {
    switch(y) {
        case 1: // Insertion dans la table des IDF et CONST
            TS[i].state = 1;
            strcpy(TS[i].name, entite);
            strcpy(TS[i].code, code);
            strcpy(TS[i].type, type);
            strcpy(TS[i].val, val);
            break;
            
        case 2: // Insertion dans la table des mots clés
            tabM[i].state = 1;
            strcpy(tabM[i].name, entite);
            strcpy(tabM[i].code, code);
            break;
            
        case 3: // Insertion dans la table des séparateurs
            tabS[i].state = 1;
            strcpy(tabS[i].name, entite);
            strcpy(tabS[i].code, code);
            break;
    }
}

// Recherche spécifique dans la table des identificateurs
int recherche_idf_declared(char entite[]) {
    int i;
    for (i = 0; i < 200; i++) {
        if (TS[i].state == 1 && 
            strcmp(entite, TS[i].name) == 0 && 
            strcmp(TS[i].type, "") != 0) {  // Considérer comme déclaré seulement si un type a été attribué
            return i;
        }
    }
    return -1; // Entité non déclarée
}

// Recherche spécifique dans la table des mots clés
int recherche_motcle(char entite[]) {
    int i;
    for (i = 0; i < 50; i++) {
        if (tabM[i].state == 1 && strcmp(entite, tabM[i].name) == 0) {
            return i;
        }
    }
    return -1; // Entité non trouvée
}

// Recherche spécifique dans la table des séparateurs
int recherche_separateur(char entite[]) {
    int i;
    for (i = 0; i < 50; i++) {
        if (tabS[i].state == 1 && strcmp(entite, tabS[i].name) == 0) {
            return i;
        }
    }
    return -1; // Entité non trouvée
}

// Affichage des tables de symboles
void afficher() {
    int i;
    
    printf("\n/***************Table des symboles IDF*************/\n");
    printf("____________________________________________________________________\n");
    printf("\t| Nom_Entite | Code_Entite | Type_Entite | Val_Entite\n");
    printf("____________________________________________________________________\n");
    
    for (i = 0; i < 200; i++) {
        if (TS[i].state == 1) {
            printf("\t|%10s |%15s | %12s | %12s\n", TS[i].name, TS[i].code, TS[i].type, TS[i].val);
        }
    }
    
    printf("\n/***************Table des symboles mots clés*************/\n");
    printf("_____________________________________\n");
    printf("\t| NomEntite | CodeEntite | \n");
    printf("_____________________________________\n");
    
    for (i = 0; i < 50; i++) {
        if (tabM[i].state == 1) {
            printf("\t|%10s |%12s | \n", tabM[i].name, tabM[i].code);
        }
    }
    
    printf("\n/***************Table des symboles séparateurs*************/\n");
    printf("_____________________________________\n");
    printf("\t| NomEntite | CodeEntite | \n");
    printf("_____________________________________\n");
    
    for (i = 0; i < 50; i++) {
        if (tabS[i].state == 1) {
            printf("\t|%10s |%12s | \n", tabS[i].name, tabS[i].code);
        }
    }
}
