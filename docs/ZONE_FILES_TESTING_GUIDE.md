# Guide de Test pour la Gestion des Fichiers de Zone

## Configuration de la Base de Données

> **Note** : Les fichiers de migration ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

Pour configurer le schéma de base de données pour les tests:

1. Importer le schéma complet:
```bash
mysql -u dns3_user -p dns3_db < database.sql
```

2. Vérifier que les tables ont été créées:
```sql
USE dns3_db;
SHOW TABLES LIKE 'zone%';
DESCRIBE zone_files;
DESCRIBE zone_file_includes;
DESCRIBE zone_file_history;
SHOW COLUMNS FROM dns_records LIKE 'zone_file_id';
```

## Tests de l'API

### API des Fichiers de Zone

1. **Lister les zones** (requiert authentification):
```bash
curl -X GET "http://localhost/api/zone_api.php?action=list_zones" -H "Cookie: session_id=..."
```

2. **Créer une zone** (requiert admin):
```bash
curl -X POST "http://localhost/api/zone_api.php?action=create_zone" \
  -H "Content-Type: application/json" \
  -H "Cookie: session_id=..." \
  -d '{
    "name": "example.com",
    "filename": "db.example.com",
    "file_type": "master",
    "content": "; Zone file for example.com\n"
  }'
```

3. **Obtenir une zone spécifique**:
```bash
curl -X GET "http://localhost/api/zone_api.php?action=get_zone&id=1" -H "Cookie: session_id=..."
```

4. **Mettre à jour une zone** (requiert admin):
```bash
curl -X POST "http://localhost/api/zone_api.php?action=update_zone&id=1" \
  -H "Content-Type: application/json" \
  -H "Cookie: session_id=..." \
  -d '{
    "content": "; Updated zone file content\n"
  }'
```

5. **Assigner une inclusion à une zone maître** (requiert admin):
```bash
curl -X POST "http://localhost/api/zone_api.php?action=assign_include&master_id=1&include_id=2" \
  -H "Cookie: session_id=..."
```

6. **Télécharger un fichier de zone**:
```bash
curl -X GET "http://localhost/api/zone_api.php?action=download_zone&id=1" -H "Cookie: session_id=..." -o zone_file.txt
```

### API des Enregistrements DNS (avec zone_file_id)

1. **Créer un enregistrement DNS** (requiert maintenant zone_file_id):
```bash
curl -X POST "http://localhost/api/dns_api.php?action=create" \
  -H "Content-Type: application/json" \
  -H "Cookie: session_id=..." \
  -d '{
    "zone_file_id": 1,
    "record_type": "A",
    "name": "test.example.com",
    "address_ipv4": "192.168.1.100",
    "ttl": 3600
  }'
```

2. **Lister les enregistrements DNS** (inclut maintenant zone_name):
```bash
curl -X GET "http://localhost/api/dns_api.php?action=list" -H "Cookie: session_id=..."
```

3. **Mettre à jour un enregistrement DNS** (peut changer zone_file_id):
```bash
curl -X POST "http://localhost/api/dns_api.php?action=update&id=1" \
  -H "Content-Type: application/json" \
  -H "Cookie: session_id=..." \
  -d '{
    "zone_file_id": 2,
    "address_ipv4": "192.168.1.101"
  }'
```

## Tests de l'Interface Utilisateur

1. Ouvrir la page de Gestion DNS: `http://localhost/dns-management.php`

2. Cliquer sur "Créer un enregistrement" pour ouvrir le modal de création

3. Vérifier que:
   - Le menu déroulant "Fichier de zone" est présent comme premier champ
   - Le menu déroulant charge les fichiers de zone de type "master" ou "include"
   - Quand vous sélectionnez une zone et remplissez le formulaire, l'enregistrement est créé avec le zone_file_id

4. Dans le tableau des enregistrements DNS, vérifier que:
   - La colonne "Zone" apparaît comme première colonne
   - Chaque enregistrement montre son nom de zone associé
   - Lors de l'édition d'un enregistrement, le sélecteur de zone montre la zone actuelle sélectionnée
   - Vous pouvez changer la zone lors de l'édition d'un enregistrement

## Comportement Attendu

### Création d'un Enregistrement DNS
- **Avant**: Pouvait créer un enregistrement sans sélectionner une zone
- **Après**: Doit sélectionner un fichier de zone (zone_file_id est requis)
- **Erreur si aucune zone sélectionnée**: "Missing required field: zone_file_id"

### Listage des Enregistrements DNS
- **Avant**: Les enregistrements montraient seulement les données DNS
- **Après**: Les enregistrements incluent le champ zone_name montrant la zone associée

### Édition d'un Enregistrement DNS
- **Avant**: Ne pouvait pas changer la zone
- **Après**: Peut mettre à jour le zone_file_id pour déplacer un enregistrement vers une zone différente

### Sélecteur de Zone
- **Affiche**: Seulement les fichiers de zone avec status='active' et file_type in ('master', 'include')
- **Format**: "zone_name (file_type)" - ex: "example.com (master)"

## Notes de Migration

- La colonne `zone_file_id` dans `dns_records` est nullable pour les besoins de migration
- Les enregistrements existants sans zone_file_id peuvent continuer d'exister
- Les nouveaux enregistrements DOIVENT avoir un zone_file_id (appliqué par validation API)
- La contrainte de clé étrangère est commentée dans la migration mais peut être activée si désiré

## Dépannage

### Erreur: "Invalid or inactive zone_file_id"
- S'assurer que le fichier de zone existe et a status='active'
- Vérifier que le zone_file_id est correct

### Erreur: "zone_file_id is required"
- Ceci est attendu lors de la tentative de création d'un enregistrement DNS sans sélectionner une zone
- Sélectionner une zone depuis le menu déroulant dans l'interface

### Le menu déroulant de zone est vide
- Vérifier que les fichiers de zone existent dans la base de données avec status='active'
- Vérifier qu'au moins une zone a file_type='master' ou 'include'
- Vérifier la console du navigateur pour les erreurs API

### Les enregistrements DNS ne montrent pas les noms de zone
- Vérifier que la migration a ajouté la colonne zone_file_id à dns_records
- Vérifier que les enregistrements ont des valeurs zone_file_id
- Vérifier le LEFT JOIN dans les méthodes search() et getById()
