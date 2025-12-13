# Guide de démarrage rapide - Fichiers de zone

## Configuration initiale

### 1. Configuration de la base de données

> **Note** : Les fichiers de migration ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

```bash
# Importer le schéma complet
mysql -u dns3_user -p dns3_db < database.sql
```

### 2. Créer votre premier fichier de zone

En utilisant l'API Zone (nécessite une connexion administrateur) :

```bash
# Créer une zone maître
curl -X POST "http://localhost/api/zone_api.php?action=create_zone" \
  -H "Content-Type: application/json" \
  -H "Cookie: PHPSESSID=your_session_id" \
  -d '{
    "name": "example.com",
    "filename": "db.example.com",
    "file_type": "master",
    "content": "$ORIGIN example.com.\n$TTL 3600\n@ IN SOA ns1.example.com. admin.example.com. (\n    2024010101 ; Serial\n    3600       ; Refresh\n    1800       ; Retry\n    604800     ; Expire\n    86400 )    ; Minimum TTL\n"
  }'
```

Ou insérer directement dans la base de données (plus facile pour la configuration initiale) :

```sql
INSERT INTO zone_files (name, filename, file_type, status, created_by, created_at) 
VALUES 
  ('example.com', 'db.example.com', 'master', 'active', 1, NOW()),
  ('internal.local', 'db.internal.local', 'master', 'active', 1, NOW()),
  ('common.include', 'common.include', 'include', 'active', 1, NOW());
```

## Utilisation de l'interface utilisateur

### Créer un enregistrement DNS

1. Naviguer vers la page **Gestion DNS**
2. Cliquer sur **"+ Créer un enregistrement"**
3. **D'abord**, sélectionner une zone dans le menu déroulant "Fichier de zone"
4. Remplir les autres champs :
   - Nom (par exemple, `www.example.com`)
   - TTL (par défaut : 3600)
   - Type (A, AAAA, CNAME, PTR ou TXT)
   - Valeur (adresse IP, nom d'hôte ou texte selon le type)
5. Cliquer sur **"Enregistrer"**

### Modifier un enregistrement DNS

1. Cliquer sur **"Modifier"** sur n'importe quel enregistrement du tableau
2. Vous pouvez changer le fichier de zone en sélectionnant une valeur différente dans le menu déroulant
3. Mettre à jour les autres champs si nécessaire
4. Cliquer sur **"Enregistrer"**

### Afficher les informations de zone

Le tableau des enregistrements DNS affiche maintenant le nom de la zone dans la première colonne pour chaque enregistrement.

## Flux de travail courants

### Flux de travail 1 : Ajouter un nouveau site Web

```bash
# 1. Créer un fichier de zone pour le domaine
curl -X POST ".../zone_api.php?action=create_zone" -d '{"name": "newsite.com", "filename": "db.newsite.com", "file_type": "master"}'

# 2. Ajouter des enregistrements DNS via l'interface
# - Sélectionner "newsite.com (master)" dans le menu déroulant de zone
# - Ajouter un enregistrement A : www.newsite.com -> 192.168.1.100
# - Ajouter un CNAME : mail.newsite.com -> mail.provider.com
```

### Flux de travail 2 : Migrer les enregistrements existants vers des zones

Pour les enregistrements DNS existants sans zone :

```sql
-- Trouver les enregistrements sans zones
SELECT id, name, record_type FROM dns_records WHERE zone_file_id IS NULL;

-- Les mettre à jour pour utiliser une zone (par exemple, zone_file_id = 1)
UPDATE dns_records 
SET zone_file_id = 1 
WHERE name LIKE '%example.com%' AND zone_file_id IS NULL;
```

Ou mettre à jour via l'interface en modifiant chaque enregistrement et en sélectionnant une zone.

### Flux de travail 3 : Créer un fichier include pour les enregistrements communs

```bash
# 1. Créer une zone include
curl -X POST ".../zone_api.php?action=create_zone" \
  -d '{"name": "common-mx", "filename": "common-mx.include", "file_type": "include"}'

# 2. L'assigner aux zones maîtres
curl -X POST ".../zone_api.php?action=assign_include&master_id=1&include_id=3"
curl -X POST ".../zone_api.php?action=assign_include&master_id=2&include_id=3"

# 3. Ajouter des enregistrements DNS à la zone include via l'interface
# Sélectionner "common-mx (include)" et ajouter des enregistrements MX
```

## Bonnes pratiques

### Organisation des zones

1. **Zones maîtres** : Une par domaine ou sous-domaine
   - example.com
   - internal.example.com
   - api.example.com

2. **Zones include** : Pour les ensembles d'enregistrements communs
   - common-mx (enregistrements MX partagés)
   - common-ns (serveurs de noms partagés)
   - monitoring-hosts (IPs de surveillance standard)

### Conventions de nommage

- **Noms de zone** : Utiliser le format de domaine (example.com, subdomain.example.com)
- **Noms de fichiers** : Utiliser db.* pour les maîtres, *.include pour les includes

### Gestion des statuts

- **active** : Zone en cours d'utilisation
- **inactive** : Désactivée temporairement, peut être réactivée
- **deleted** : Suppression douce, cachée des vues normales

## Dépannage

### "Missing required field: zone_file_id"

**Problème** : Tentative de créer un enregistrement DNS sans sélectionner de zone.

**Solution** : Sélectionner une zone dans le menu déroulant "Fichier de zone" avant de soumettre.

### "Invalid or inactive zone_file_id"

**Problème** : La zone sélectionnée n'existe pas ou n'est pas active.

**Solutions** :
1. Vérifier que la zone existe : `SELECT * FROM zone_files WHERE id = X;`
2. Vérifier que la zone est active : `UPDATE zone_files SET status = 'active' WHERE id = X;`
3. Sélectionner une zone différente dans le menu déroulant

### Le menu déroulant des zones est vide

**Problème** : Aucune zone maître ou include active disponible.

**Solutions** :
1. Créer au moins une zone (voir "Créer votre premier fichier de zone" ci-dessus)
2. S'assurer que la zone a status='active'
3. Vérifier la console du navigateur pour les erreurs API
4. Vérifier que l'administrateur est connecté

### Impossible de changer la zone d'un enregistrement existant

**Problème** : Le menu déroulant des zones n'est pas visible ou est désactivé.

**Solution** : Le menu déroulant des zones est toujours activé en mode édition. Assurez-vous d'utiliser la dernière version du code et actualisez votre navigateur.

## Résumé de référence API

### Fichiers de zone
- `GET /api/zone_api.php?action=list_zones[&file_type=master][&status=active]`
- `GET /api/zone_api.php?action=get_zone&id=X`
- `POST /api/zone_api.php?action=create_zone` (admin)
- `POST /api/zone_api.php?action=update_zone&id=X` (admin)
- `POST /api/zone_api.php?action=assign_include&master_id=X&include_id=Y` (admin)
- `GET /api/zone_api.php?action=download_zone&id=X`

### Enregistrements DNS (Améliorés)
- `POST /api/dns_api.php?action=create` - Nécessite maintenant `zone_file_id`
- `GET /api/dns_api.php?action=list` - Inclut maintenant `zone_name`
- `POST /api/dns_api.php?action=update&id=X` - Peut mettre à jour `zone_file_id`

## Support

Pour les problèmes ou questions :
1. Consulter ZONE_FILES_TESTING_GUIDE.md
2. Consulter ZONE_FILES_IMPLEMENTATION_SUMMARY.md
3. Examiner les messages d'erreur API dans la console du navigateur
4. Vérifier les journaux d'erreurs du serveur
