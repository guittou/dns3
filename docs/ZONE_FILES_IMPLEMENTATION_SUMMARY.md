# Gestion des fichiers de zone - Résumé d'implémentation

## Vue d'ensemble

Cette documentation décrit la fonctionnalité de gestion des fichiers de zone du système DNS3, qui garantit que chaque enregistrement DNS est associé à un fichier de zone.

> **Note** : La fonctionnalité Applications a été retirée de l'application. La table `applications` peut rester dans la base de données à titre de référence historique mais n'est plus utilisée par l'application. Voir les archives de migration pour les détails du schéma.

## Modifications de la base de données

### Nouvelles tables

1. **zone_files**
   - Table principale pour la gestion des fichiers de zone DNS
   - Champs : id, name, filename, content, file_type (master/include), status, created_by, updated_by, created_at, updated_at
   - Supporte les zones master et les fichiers include
   - Statut : active, inactive, deleted

2. **zone_file_includes**
   - Table de jonction pour les relations parent/include (supporte l'imbrication récursive)
   - Lie les zones parentes (master ou include) à leurs fichiers include
   - Champs : id, parent_id, include_id, position, created_at
   - Note : `parent_id` a remplacé l'ancien nom de colonne `master_id`

3. **zone_file_history**
   - Piste d'audit pour les modifications de fichier de zone
   - Suit toutes les modifications y compris les changements de contenu
   - Champs : id, zone_file_id, action, name, filename, file_type, old_status, new_status, old_content, new_content, changed_by, changed_at, notes

### Tables modifiées

1. **dns_records**
   - Ajouté : zone_file_id INT NULL (nullable pour la migration)
   - Ajout d'index : idx_zone_file_id
   - Contrainte de clé étrangère disponible (commentée) pour application optionnelle

2. **dns_record_history**
   - Ajouté : zone_file_id INT NULL
   - Assure que le suivi de l'historique inclut les informations de zone

## Modèles backend

### ZoneFile.php
- Opérations CRUD complètes pour les fichiers de zone
- Méthodes :
  - `search()` - Filtrer et rechercher des fichiers de zone
  - `getById()` - Obtenir une zone par ID
  - `getByName()` - Obtenir une zone par nom
  - `create()` - Créer un nouveau fichier de zone
  - `update()` - Mettre à jour un fichier de zone
  - `setStatus()` - Changer le statut de zone
  - `assignInclude()` - Lier un fichier include à une zone master
  - `getIncludes()` - Obtenir tous les includes pour une zone master
  - `writeHistory()` - Enregistrer les modifications de zone
  - `getHistory()` - Récupérer l'historique des modifications de zone

### DnsRecord.php (Modifié)
- Amélioré pour exiger et gérer zone_file_id
- Modifications :
  - `create()` : Exige maintenant zone_file_id, valide qu'il référence une zone active
  - `update()` : Permet les changements de zone_file_id, valide si fourni
  - `search()` : LEFT JOIN sur zone_files pour exposer zone_name
  - `getById()` : LEFT JOIN sur zone_files pour exposer zone_name
  - `writeHistory()` : Inclut zone_file_id dans les enregistrements d'historique

## Endpoints API

### Zone API (api/zone_api.php)
- `list_zones` - Lister les fichiers de zone avec filtres (name, file_type, status)
- `get_zone` - Obtenir une zone spécifique avec includes et historique
- `create_zone` - Créer un nouveau fichier de zone (admin uniquement, valide file_type)
- `update_zone` - Mettre à jour un fichier de zone (admin uniquement)
- `set_status_zone` - Changer le statut de zone (admin uniquement)
- `assign_include` - Lier un include à une zone master (admin uniquement)
- `download_zone` - Télécharger le contenu du fichier de zone

### DNS API (api/dns_api.php) - Modifié
- Action `create` : Exige maintenant zone_file_id, valide que la zone existe et est active
- Action `list` : Retourne zone_name pour chaque enregistrement
- Action `get` : Retourne zone_name et zone_file_id
- Action `update` : Permet les changements de zone_file_id, valide si fourni

## Modifications de l'interface

### dns-management.php
1. **Disposition du tableau**
   - Ajout de la colonne "Zone" comme PREMIÈRE colonne
   - Affiche le nom de zone pour chaque enregistrement DNS
   - Mise à jour du colspan pour le message de tableau vide (13 → 14)

2. **Modale Créer/Éditer**
   - Ajout du menu déroulant "Fichier de zone" comme PREMIER champ du formulaire
   - Le menu déroulant est peuplé dynamiquement via API
   - Affiche uniquement les zones actives avec file_type 'master' ou 'include'
   - Format : "zone_name (file_type)"
   - Champ requis pour la création d'enregistrements
   - Permet de changer la zone lors de l'édition d'enregistrements

### dns-records.js
1. **Nouvelles fonctions**
   - `getZoneApiUrl()` - Construire les URLs pour les appels API de zone
   - `zoneApiCall()` - Effectuer des appels API vers les endpoints de zone
   - `loadZoneFiles()` - Peupler le sélecteur de zone avec les zones master/include actives

2. **Fonctions modifiées**
   - `loadDnsTable()` : Mise à jour pour afficher la colonne zone (première position)
   - `openCreateModal()` : Charge les fichiers de zone avant d'afficher la modale
   - `openEditModal()` : Charge les fichiers de zone et définit la zone actuelle dans le sélecteur
   - `submitDnsForm()` : Inclut zone_file_id dans les requêtes créer/mettre à jour, valide la sélection

## Fonctionnalités clés

### Gestion des fichiers de zone
✅ Créer des fichiers de zone master et include
✅ Stocker le contenu du fichier de zone
✅ Suivre l'historique des fichiers de zone (y compris les modifications de contenu)
✅ Lier les fichiers include aux zones master
✅ Télécharger le contenu du fichier de zone
✅ Gestion du statut active/inactive/deleted

### Intégration des enregistrements DNS
✅ Colonne Zone affichée comme première colonne dans le tableau
✅ Sélecteur de zone comme premier champ dans la modale créer/éditer
✅ zone_file_id requis pour les nouveaux enregistrements DNS
✅ zone_file_id peut être modifié lors de l'édition (compatible migration)
✅ Le sélecteur de zone liste uniquement les zones master et include actives
✅ La validation garantit que la zone référencée existe et est active
✅ LEFT JOIN préserve les enregistrements existants sans zones

### Validation et sécurité
✅ Accès admin uniquement pour les opérations créer/mettre à jour/supprimer
✅ Validation de l'existence et du statut de la zone
✅ Support de clé étrangère (optionnel, commenté dans la migration)
✅ Suivi complet de l'historique pour les pistes d'audit
✅ Messages d'erreur appropriés pour zone_file_id manquant ou invalide

## Stratégie de migration

L'implémentation est conçue pour la rétrocompatibilité :

1. **zone_file_id nullable** : Les enregistrements existants sans zones continuent de fonctionner
2. **Validation API** : Les nouveaux enregistrements DOIVENT avoir une zone, appliqué au niveau API
3. **FK optionnelle** : La contrainte de clé étrangère est commentée, peut être activée après nettoyage
4. **Migration graduelle** : Les enregistrements peuvent être mis à jour progressivement pour ajouter des zones

## Tests

Voir `ZONE_FILES_TESTING_GUIDE.md` pour des instructions de test complètes incluant :
- Vérification de migration de base de données
- Test des endpoints API
- Test de fonctionnalité UI
- Comportement attendu et gestion des erreurs

## Fichiers modifiés

### Créés :
- `includes/models/ZoneFile.php`
- `api/zone_api.php`
- `ZONE_FILES_TESTING_GUIDE.md`
- `ZONE_FILES_IMPLEMENTATION_SUMMARY.md` (ce fichier)

### Modifiés :
- `includes/models/DnsRecord.php`
- `api/dns_api.php`
- `dns-management.php`
- `assets/js/dns-records.js`

## Notes de configuration

> **Note** : Les fichiers de migration ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).
>
> ```bash
> mysql -u dns3_user -p dns3_db < database.sql
> ```

Après l'import du schéma :
1. Créer les fichiers de zone initiaux via API ou INSERT en base de données
2. Tester le listage et la sélection de fichiers de zone dans l'UI
3. Créer des enregistrements DNS avec associations de zone
4. (Optionnel) Activer la contrainte de clé étrangère après mise à jour des enregistrements existants
5. (Optionnel) Rendre zone_file_id NOT NULL après que tous les enregistrements ont des zones

## Conformité aux exigences

✅ Colonne Zone comme première colonne dans le tableau DNS
✅ Sélecteur de zone dans la modale créer/éditer
✅ zone_file_id modifiable lors de l'édition
✅ Le sélecteur liste les zones master + include uniquement
✅ La migration crée toutes les tables requises
✅ Validation de zone_file_id lors de la création d'enregistrement
✅ Tous les endpoints API implémentés comme spécifié
✅ Restrictions admin uniquement sur les opérations de gestion
✅ Suivi complet de l'historique pour les zones
