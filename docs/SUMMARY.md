# Documentation DNS3

Bienvenue dans la documentation du projet DNS3, une application web PHP pour la gestion de zones DNS et d'enregistrements DNS.

---

## Table des matières

### 📚 Introduction et Démarrage

- [Vue d'ensemble du projet](../README.md) - Présentation générale, fonctionnalités et aperçu
- [Guide de démarrage rapide](QUICK_START.md) - Installation en 5 minutes et commandes essentielles
- [Guide d'installation](INSTALL.md) - Installation rapide et configuration initiale
- [Démarrage rapide — tokens API](GETTING_STARTED_API_TOKENS.md) - Guide de démarrage pour l'authentification par tokens API

---

### 🔧 Administration et Configuration

- [Guide d'utilisation de l'interface d'administration](ADMIN_INTERFACE_GUIDE.md) - Guide complet de l'interface admin
- [Résumé de l'implémentation de l'interface d'administration](ADMIN_IMPLEMENTATION.md) - Détails d'implémentation de l'admin
- [Vue d'ensemble de l'interface d'administration](ADMIN_UI_OVERVIEW.md) - Aperçu de l'UI d'administration
- [Référence rapide admin](ADMIN_QUICK_REFERENCE.md) - Référence rapide pour les tâches courantes
- [Notes de version admin](ADMIN_RELEASE_NOTES.md) - Historique des versions et changements
- [Modifications de l'authentification admin](ADMIN_AUTH_CHANGES.md) - Changements dans le système d'authentification

---

### 🌐 Gestion DNS et Zones

- [Guide de gestion DNS](DNS_MANAGEMENT_GUIDE.md) - Guide complet pour gérer les enregistrements DNS
- [Champs de Métadonnées DNS - Documentation d'Implémentation](DNS_METADATA_IMPLEMENTATION.md) - Détails sur la gestion des métadonnées
- [Génération de fichiers de zone](ZONE_FILE_GENERATION_IMPLEMENTATION.md) - Implémentation de la génération de zones
- [Résumé de l'implémentation des fichiers de zone](ZONE_FILES_IMPLEMENTATION_SUMMARY.md) - Vue d'ensemble de l'implémentation
- [Guide de démarrage rapide - Fichiers de zone](ZONE_FILES_QUICK_START.md) - Guide de démarrage rapide
- [Référence rapide - Fichiers de zone](ZONE_FILES_QUICK_REFERENCE.md) - Référence rapide pour les zones
- [Implémentation récursive des fichiers de zone](ZONE_FILES_RECURSIVE_IMPLEMENTATION.md) - Support des includes récursifs
- [Guide de test des fichiers de zone](ZONE_FILES_TESTING_GUIDE.md) - Tests pour les fichiers de zone
- [Fonctionnalité de génération de fichiers de zone - Résumé final](ZONE_GENERATION_FINAL_SUMMARY.md) - Résumé final de l'implémentation
- [Améliorations de la Validation des Fichiers de Zone](ZONE_VALIDATION_IMPROVEMENTS.md) - Améliorations de la validation
- [Vérification du combobox de zone](ZONEFILE_COMBOBOX_VERIFICATION.md) - Vérification de l'UI

---

### 🔌 API et Intégration

- [Authentification par tokens API](api_token_authentication.md) - Documentation complète de l'authentification API
- [Résumé de l'implémentation de la validation API](API_VALIDATION_IMPLEMENTATION.md) - Détails de validation via API
- [Implémentation de la validation par preview](PREVIEW_VALIDATION_IMPLEMENTATION.md) - Validation en temps réel
- [Flux de la Modale d'Aperçu de Zone](PREVIEW_MODAL_FLOW.md) - Workflow du preview de zone
- [Diagramme de flux de validation](VALIDATION_FLOW_DIAGRAM.md) - Schéma du processus de validation
- [Implémentation de l'aplatissement de validation](VALIDATION_FLATTENING_IMPLEMENTATION.md) - Aplatissement pour validation
- [Implémentation de la validation include/master](VALIDATION_INCLUDE_MASTER_IMPLEMENTATION.md) - Validation des includes
- [Extraction de lignes pour validation](VALIDATION_LINE_EXTRACTION.md) - Extraction et traitement des lignes

---

### 📜 Scripts et Utilitaires

- [Import de zones BIND](import_bind_zones.md) - Guide complet d'import de zones BIND
- [Mise à jour last_seen depuis les logs BIND](UPDATE_LAST_SEEN_FROM_BIND_LOGS.md) - Script pour synchroniser last_seen
- [Tâches en arrière-plan](../jobs/README.md) - Configuration des workers de validation

---

### 🗄️ Base de Données et Migrations

- [Schéma de base de données](DB_SCHEMA.md) - Documentation complète du schéma
- [Guide des migrations](../migrations/README.md) - Guide de migration des types d'enregistrements DNS

---

### 🏗️ Architecture et Implémentation

- [Diagramme d'Architecture : Fonctionnalité de Fichiers de Zone Paginés](ARCHITECTURE_DIAGRAM.md) - Vue d'ensemble de l'architecture système
- [Correction de l'affichage du domaine DNS - Notes d'implémentation](IMPLEMENTATION_NOTES.md) - Notes d'implémentation de la correction
- [Implémentation des champs spécifiques par type - Rapport d'état](IMPLEMENTATION_STATUS.md) - État actuel de l'implémentation
- [Gestion des fichiers de zone - Guide visuel d'implémentation](IMPLEMENTATION_VISUAL_GUIDE.md) - Guide visuel des fonctionnalités
- [Résumé d'Implémentation : Fonctionnalité de Fichiers de Zone Paginés](IMPLEMENTATION_SUMMARY_PAGINATION.md) - Pagination côté serveur
- [Statut final](FINAL_STATUS.md) - Statut final du projet
- [Validation de Fichier de Zone avec Fichiers Include Séparés](INCLUDE_INLINING_DOCUMENTATION.md) - Documentation du système d'include

---

### 🎨 Interface Utilisateur

- [Documentation des modifications UI - Champs spécifiques](UI_CHANGES_DOCUMENTATION.md) - Modifications visuelles et fonctionnelles
- [Guide visuel des modifications UI - Génération de zone](UI_CHANGES_VISUAL_GUIDE.md) - Guide visuel des changements UI
- [Guide visuel de l'interface utilisateur - Gestion des fichiers de zone](UI_VISUAL_GUIDE.md) - Guide complet de l'interface modale
- [Modifications Visuelles : Interface Created At / Updated At](VISUAL_CHANGES_GUIDE.md) - Documentation des modifications d'interface
- [Implémentation Created At / Updated At](CREATED_UPDATED_UI_IMPLEMENTATION.md) - Affichage des horodatages
- [Résumé de l'Implémentation de la Disposition Responsive des Tableaux](RESPONSIVE_TABLE_IMPLEMENTATION.md) - Tables adaptatives
- [Résumé des champs spécifiques par type](TYPE_SPECIFIC_FIELDS_SUMMARY.md) - Champs dédiés par type d'enregistrement

#### Modals

- [Implémentation de la bannière d'erreur modale](MODAL_ERROR_BANNER_IMPLEMENTATION.md) - Gestion des erreurs dans les modals
- [Centrage vertical des modales - Guide d'implémentation](MODAL_CENTERING_IMPLEMENTATION.md) - Centrage des fenêtres modales
- [Implémentation de la standardisation des modals](MODAL_STANDARDIZATION_IMPLEMENTATION.md) - Uniformisation des modals

---

### 🧪 Tests et Validation

- [Guide de test - Prévisualisation de zone](TESTING_GUIDE.md) - Guide pour tester la prévisualisation avec validation
- [Plan de test - DNS last_seen et formulaires dynamiques](TEST_PLAN.md) - Plan de test complet
- [Implémentation des Champs Spécifiques par Type - Plan de Test](TYPE_SPECIFIC_FIELDS_TEST_PLAN.md) - Tests par type d'enregistrement
- [Checklist de vérification](VERIFICATION_CHECKLIST.md) - Checklist pour validation manuelle
- [Vérification complétée](VERIFICATION_COMPLETE.md) - Rapport de vérification

---

### 📦 Résumés de Livraison

- [Avis de complétion](COMPLETION_NOTICE.md) - Notification de fin de fonctionnalité
- [Résumé de livraison](DELIVERY_SUMMARY.md) - Résumé global de livraison
- [Résumé d'implémentation - Pagination](IMPLEMENTATION_SUMMARY_PAGINATION.md) - Pagination des listes

---

### 📂 Archives

Les documents suivants sont archivés pour référence historique mais ne sont plus maintenus activement :

- [Archive complète](archive/) - Ancien contenu (PR descriptions, guides de test obsolètes, notes intermédiaires)
  - Instructions de PR manuelles
  - Guides de test de fonctionnalités retirées
  - Documentation de corrections de bugs spécifiques
  - Résumés de PR historiques

> **Note**: Les fichiers dans `docs/archive/` sont conservés pour l'historique mais peuvent être obsolètes. Référez-vous toujours aux documents principaux ci-dessus pour les informations à jour.

---

## Comment Contribuer à la Documentation

Pour ajouter ou modifier de la documentation, consultez [CONTRIBUTING_DOCS.md](CONTRIBUTING_DOCS.md).

### État de la Traduction

Pour suivre la progression de la traduction de la documentation en français, consultez [TRANSLATION_STATUS.md](TRANSLATION_STATUS.md).

---

## Structure des Fichiers

```
dns3/
├── README.md                          # Présentation générale du projet
├── docs/
│   ├── SUMMARY.md                     # Ce fichier - index global
│   ├── CONTRIBUTING_DOCS.md           # Guide de contribution documentation
│   ├── INSTALL.md                     # Guide d'installation
│   ├── GETTING_STARTED_API_TOKENS.md  # Guide de démarrage API tokens
│   ├── DB_SCHEMA.md                   # Documentation du schéma
│   ├── ADMIN_*.md                     # Documentation admin
│   ├── DNS_*.md                       # Documentation DNS
│   ├── ZONE_*.md                      # Documentation zones
│   ├── API_*.md                       # Documentation API
│   ├── UI_*.md                        # Documentation interface
│   ├── TESTING_*.md                   # Documentation tests
│   ├── import_bind_zones.md           # Import BIND
│   ├── api_token_authentication.md    # Auth API
│   ├── backup/                        # Backups des versions originales anglaises
│   └── archive/                       # Archives historiques
├── jobs/
│   └── README.md                      # Workers de validation
└── migrations/
    └── README.md                      # Guide des migrations
```

---

## Liens Rapides

- **Installation** : [INSTALL.md](INSTALL.md)
- **Guide Admin** : [ADMIN_INTERFACE_GUIDE.md](ADMIN_INTERFACE_GUIDE.md)
- **API Tokens** : [api_token_authentication.md](api_token_authentication.md)
- **Import BIND** : [import_bind_zones.md](import_bind_zones.md)
- **Schéma DB** : [DB_SCHEMA.md](DB_SCHEMA.md)
- **Tests** : [TESTING_GUIDE.md](TESTING_GUIDE.md)

---

**Dernière mise à jour** : 2025-12-14  
**Version de la documentation** : 2.4
**Progression de la traduction** : 45/52 fichiers complètement traduits (87%) + 4 avec en-têtes traduits + 57 fichiers d'archive (conservés en anglais) ✅
