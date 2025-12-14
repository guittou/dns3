# Gestion des Fichiers de Zone - Référence Rapide

## Vue d'ensemble

L'interface de gestion des fichiers de zone fournit une solution complète pour gérer les fichiers de zone DNS avec support des includes récursifs et de la détection automatique de cycles.

## Accéder à l'Interface

1. Se connecter en tant qu'administrateur
2. Cliquer sur l'onglet "Zones" dans le menu de navigation
3. Vous verrez l'interface de gestion des zones avec une disposition à deux panneaux

## Disposition de l'Interface

### Panneau Gauche - Liste des Zones
- **Barre de Recherche** : Filtrer les zones par nom ou fichier
- **Filtre de Type** : Filtrer par Maître ou Include
- **Filtre de Statut** : Afficher les zones Actives, Inactives ou Supprimées
- **Zones Maîtres** : Liste des fichiers de zone maîtres
- **Zones Include** : Liste des fichiers de zone include
- Cliquer sur n'importe quelle zone pour voir/éditer ses détails

### Panneau Droit - Détails de la Zone (4 Onglets)

#### 1. Onglet Détails
- Éditer les métadonnées de la zone : Nom, Fichier, Type, Statut
- Voir les informations de création et modification
- Sauvegarder les modifications avec le bouton "Enregistrer"

#### 2. Onglet Éditeur
- Éditer le contenu du fichier de zone dans une grande zone de texte
- **Télécharger** : Télécharger le contenu du fichier de zone
- **Voir le Contenu Résolu** : Voir le contenu complet avec tous les includes aplatis
- **Sauvegarder le Contenu** : Sauvegarder les modifications du contenu de la zone

#### 3. Onglet Includes
- Voir l'arbre récursif des includes
- **Ajouter Include** : Ajouter un nouveau fichier include à la zone actuelle
  - Sélectionner parmi les fichiers include disponibles
  - Définir la position pour l'ordonnancement
- **Supprimer** : Cliquer sur le bouton X sur n'importe quel include pour le supprimer
- L'arbre montre la structure imbriquée avec indentation

#### 4. Onglet Historique
- Voir la piste d'audit de tous les changements
- Affiche le type d'action, l'utilisateur, l'horodatage et les notes
- Suit les changements de contenu et de statut

## Créer une Nouvelle Zone

1. Cliquer sur le bouton **"Nouvelle zone"** (en haut à droite)
2. Remplir le formulaire :
   - **Nom** : Nom de la zone (ex : example.com)
   - **Fichier** : Nom du fichier de zone (ex : db.example.com)
   - **Type** : Sélectionner Maître ou Include
   - **Contenu** : Optionnel - ajouter un contenu de zone initial
3. Cliquer sur **"Créer"**

## Travailler avec les Includes Récursifs

### Ajouter des Includes à une Zone

1. Sélectionner une zone (maître ou include)
2. Aller à l'onglet **Includes**
3. Cliquer sur **"Ajouter include"**
4. Sélectionner un fichier include dans la liste déroulante
5. Définir la position (0 = premier, nombres supérieurs = plus tard)
6. Cliquer sur **"Ajouter"**

### Hiérarchie de l'Arbre Include

Les includes peuvent être imbriqués à n'importe quelle profondeur :
```
Zone Maître (example.com)
├── Include A (common-records)
│   ├── Include B (ns-records)
│   └── Include C (mx-records)
└── Include D (app-specific)
    └── Include E (service-records)
```

### Voir le Contenu Résolu

Pour voir le fichier de zone complet avec tous les includes aplatis :

1. Sélectionner une zone
2. Aller à l'onglet **Éditeur**
3. Cliquer sur **"Voir le contenu résolu"**
4. Un modal affichera le contenu complet avec des commentaires indiquant chaque include

Le contenu résolu ressemblera à :
```
; Zone: example.com (db.example.com)
; Type: master
; Generated: 2025-10-21 12:00:00

[contenu de la zone maître]

; Including: common-records (db.common)
[contenu de common-records]

; Including: ns-records (db.ns)
[contenu de ns-records]

...
```

## Détection de Cycles

Le système empêche automatiquement les dépendances circulaires :

### Qu'est-ce qu'un Cycle ?

Un cycle se produit quand :
- Une zone tente de s'inclure elle-même
- La zone A inclut la zone B, et la zone B inclut la zone A
- N'importe quel chemin circulaire : A → B → C → A

### Comment Ça Fonctionne

Quand vous essayez d'ajouter un include qui créerait un cycle :
1. Le système vérifie l'arbre complet des includes
2. Si l'ajout de l'include créerait un cycle, il est rejeté
3. Vous verrez une erreur : "Cannot create circular dependency"

### Exemples de Scénarios

❌ **Rejeté - Auto-inclusion :**
```
La zone A tente d'inclure la zone A
→ Erreur : "Cannot include a zone file in itself"
```

❌ **Rejeté - Cycle Simple :**
```
Maître → Include A → Include B
Tentative d'ajout : Maître vers Include B
→ Erreur : "Cannot create circular dependency"
```

❌ **Rejeté - Cycle Complexe :**
```
Zone A → Zone B → Zone C → Zone D
Tentative d'ajout : Zone D vers Zone A
→ Erreur : "Cannot create circular dependency"
```

✅ **Autorisé - Structure en Arbre :**
```
Maître
├── Include A
│   └── Include B
└── Include C
    └── Include D
```

## Ordonnancement par Position

Le champ `position` contrôle l'ordre des includes :

- Position 0 = Premier
- Position 1 = Deuxième
- etc.

Les includes avec la même position sont triés alphabétiquement par nom.

Exemple :
```
Include A (position 0)
Include B (position 0)  ← alphabétiquement après A
Include C (position 1)
Include D (position 2)
```

## Points de Terminaison API

Le système fournit des points de terminaison API REST pour un accès programmatique :

### Lister les Zones
```
GET /api/zone_api.php?action=list_zones&file_type=master&status=active
```

### Obtenir une Zone avec Includes
```
GET /api/zone_api.php?action=get_zone&id=1
```

### Créer une Zone
```
POST /api/zone_api.php?action=create_zone
Body: {
  "name": "example.com",
  "filename": "db.example.com",
  "file_type": "master",
  "content": "..."
}
```

### Assigner un Include (avec Détection de Cycles)
```
POST /api/zone_api.php?action=assign_include
Body: {
  "parent_id": 1,
  "include_id": 2,
  "position": 0
}

Réponse en cas de cycle :
{
  "error": "Cannot create circular dependency: this would create a cycle in the include tree"
}
```

### Obtenir l'Arbre Récursif
```
GET /api/zone_api.php?action=get_tree&id=1

Response: {
  "success": true,
  "data": {
    "id": 1,
    "name": "example.com",
    "includes": [
      {
        "id": 2,
        "name": "common-records",
        "position": 0,
        "includes": [...]
      }
    ]
  }
}
```

### Rendre le Contenu Résolu
```
GET /api/zone_api.php?action=render_resolved&id=1

Response: {
  "success": true,
  "content": "; Zone: example.com\n..."
}
```

## Bonnes Pratiques

### Organisation des Zones

1. **Zones Maîtres** : Une par domaine
2. **Includes Communs** : Enregistrements réutilisables (NS, SOA, MX)
3. **Includes de Service** : Enregistrements spécifiques aux services
4. **Includes d'Application** : Enregistrements spécifiques aux applications

Exemple de structure :
```
Maîtres :
- example.com
- example.net

Includes :
- common-ns (enregistrements NS)
- common-mx (enregistrements MX)
- app-web (enregistrements serveur web)
- app-mail (enregistrements serveur mail)
```

### Stratégie d'Include

- Garder les includes focalisés sur un seul objectif
- Utiliser la position pour contrôler l'ordre (SOA/NS en premier, autres plus tard)
- Ne pas imbriquer trop profondément (3-4 niveaux max)
- Documenter la structure d'include dans les commentaires de zone

### Gestion du Contenu

- Utiliser l'onglet Éditeur pour les éditions rapides
- Utiliser "Voir le Contenu Résolu" pour vérifier la zone finale
- Télécharger les zones avant les changements majeurs
- Réviser l'historique après les changements pour vérifier

## Dépannage

### "Cannot create circular dependency"
- Vérifier l'arbre des includes pour voir les relations existantes
- Supprimer les includes conflictuels avant d'en ajouter de nouveaux
- Rappel : les includes peuvent inclure d'autres includes

### Zone Non Visible dans les Enregistrements DNS
- Vérifier que le statut de la zone est "active"
- Vérifier le file_type de la zone (master ou include)
- Rafraîchir la liste des zones

### Le Contenu Ne Se Sauvegarde Pas
- Vérifier que vous avez les privilèges administrateur
- Vérifier que le statut de la zone n'est pas "deleted"
- Vérifier la console du navigateur pour les erreurs

### L'Arbre des Includes Ne Se Charge Pas
- Vérifier que la zone a des includes assignés
- Vérifier les références circulaires (devrait être empêché mais pourrait exister depuis des éditions directes en BD)
- Rafraîchir la page

## Notes de Sécurité

- Seuls les administrateurs peuvent créer, éditer ou supprimer des zones
- Tous les changements sont enregistrés dans l'historique
- Le contenu des fichiers de zone est stocké de façon sécurisée dans la base de données
- Les points de terminaison API requièrent l'authentification
- La détection de cycles empêche les boucles malveillantes ou accidentelles

## Documentation Connexe

- `ZONE_FILES_RECURSIVE_IMPLEMENTATION.md` - Détails d'implémentation technique
- `ZONE_FILES_TESTING_GUIDE.md` - Procédures de test complètes
- `ZONE_FILES_IMPLEMENTATION_SUMMARY.md` - Résumé d'implémentation original

## Support

Pour les problèmes ou questions :
1. Vérifier l'onglet Historique pour les changements récents
2. Vérifier le statut et les relations de la zone
3. Réviser le contenu résolu pour voir la sortie réelle
4. Vérifier les logs serveur pour les erreurs API
