# Importer des fichiers de zone BIND dans dns3

Ce document décrit les deux scripts fournis pour importer des fichiers de zones BIND dans l'application dns3 :

- `scripts/import_bind_zones.py` — implémentation Python (recommandée pour les zones complexes)
- `scripts/import_bind_zones.sh` — importeur heuristique en Bash (léger, pour zones simples)

Important : toujours tester en mode `--dry-run` sur une base de test et faire une sauvegarde de la base de données avant toute exécution en écriture.

## Table des matières

- [Recommandations de sécurité](#recommandations-de-sécurité)
- [Importeur Python](#importeur-python)
  - [Fonctionnalités](#fonctionnalités)
  - [Dépendances](#dépendances)
  - [Installation](#installation)
  - [Utilisation - Mode API](#utilisation---mode-api)
  - [Utilisation - Mode Base de données](#utilisation---mode-base-de-données)
  - [Options](#options)
- [Importeur Bash](#importeur-bash)
  - [Fonctionnalités](#fonctionnalités-1)
  - [Limitations](#limitations)
  - [Utilisation](#utilisation)
  - [Options](#options-1)
- [Comparaison](#comparaison)
- [Exemples](#exemples)
- [Dépannage](#dépannage)

---

## Recommandations de sécurité

⚠️ **IMPORTANT** : Suivez toujours ces pratiques de sécurité lors de l'importation de fichiers de zone :

1. **Utilisez d'abord le mode dry-run** : Testez avec `--dry-run` pour voir ce qui sera importé sans effectuer de modifications
2. **Sauvegardez votre base de données** : Créez une sauvegarde avant d'importer en production
3. **Testez en environnement de test** : Testez d'abord les importations dans un environnement hors production
4. **Vérifiez les fichiers de zone** : Inspectez les fichiers de zone pour détecter les erreurs avant l'importation
5. **Utilisez skip-existing** : Utilisez `--skip-existing` pour éviter d'écraser les zones existantes
6. **Commencez petit** : Testez avec un petit sous-ensemble de zones avant de faire des importations en masse

### Vérification rapide de sécurité

```bash
# 1. Create database backup
mysqldump -u root -p dns3_db > backup_before_import.sql

# 2. Run dry-run first
python3 scripts/import_bind_zones.py --dir /path/to/zones --dry-run --api-url http://localhost/dns3 --api-token YOUR_TOKEN

# 3. Review output, then run actual import
python3 scripts/import_bind_zones.py --dir /path/to/zones --skip-existing --api-url http://localhost/dns3 --api-token YOUR_TOKEN
```

---

## Importeur Python

L'importeur Python (`scripts/import_bind_zones.py`) est l'outil recommandé pour importer des fichiers de zone BIND. Il utilise la bibliothèque dnspython pour analyser correctement les fichiers de zone et peut fonctionner en deux modes.

### Fonctionnalités

- **Analyse précise** : Utilise la bibliothèque dnspython pour une analyse conforme aux RFC
- **Support de $ORIGIN** : Gère correctement les directives $ORIGIN
- **Extraction SOA** : Extrait les champs d'enregistrement SOA (MNAME, RNAME, timers) et les stocke dans les métadonnées de zone
- **Traitement de $INCLUDE** : Détecte les directives $INCLUDE (nécessite le flag `--create-includes`)
- **Deux modes de fonctionnement** :
  - **Mode API** (par défaut) : Utilise les endpoints HTTP (zone_api.php, dns_api.php) - méthode préférée
  - **Mode DB** : Insertion MySQL directe avec introspection du schéma
- **Support dry-run** : Prévisualise ce qui sera importé sans effectuer de modifications
- **Détection du schéma** : Détecte automatiquement les colonnes de base de données disponibles
- **Gestion des erreurs** : Rapport d'erreurs et journalisation complets
- **Mode test** : Flag `--example` pour des tests rapides

### Dépendances

L'importeur Python nécessite :

- Python 3.6 ou supérieur
- bibliothèque dnspython (pour l'analyse de zone)
- bibliothèque requests (pour le mode API)
- bibliothèque pymysql (pour le mode DB)

### Installation

**Option 1 : Installation avec les paquets système Debian 12 / Ubuntu (recommandée) :**

```bash
sudo apt install -y \
  python3-dnspython \
  python3-requests \
  python3-pymysql
```

**Option 2 : Installation avec pip :**

```bash
# Install all dependencies
pip3 install dnspython requests pymysql

# Or install individually
pip3 install dnspython  # Required
pip3 install requests   # Required for API mode
pip3 install pymysql    # Required for DB mode
```

Alternativement, si un fichier `requirements.txt` existe :

```bash
pip3 install -r requirements.txt
```

### Utilisation - Mode API

Le mode API est l'approche **recommandée** car il utilise la logique d'authentification et de validation existante de l'application.

**Prérequis** :
- L'application DNS3 doit être en cours d'exécution et accessible
- Vous avez besoin d'un jeton d'authentification API (Bearer token)
- Les endpoints API doivent être disponibles : `/api/zone_api.php` et `/api/dns_api.php`

**Utilisation de base** :

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url http://localhost/dns3 \
  --api-token YOUR_API_TOKEN
```

**Avec options** :

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url http://localhost/dns3 \
  --api-token YOUR_API_TOKEN \
  --dry-run \
  --skip-existing \
  --verbose
```

### Utilisation - Mode Base de données

Le mode base de données effectue une insertion MySQL directe. Utilisez ce mode lorsque :
- L'API n'est pas disponible ou ne fonctionne pas
- Vous avez besoin d'importations en masse plus rapides
- Vous importez dans une base de données de test/staging

**Utilisation de base** :

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --db-mode \
  --db-user root \
  --db-pass YOUR_PASSWORD \
  --db-name dns3_db
```

**Avec options** :

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --db-mode \
  --db-host localhost \
  --db-port 3306 \
  --db-user root \
  --db-pass YOUR_PASSWORD \
  --db-name dns3_db \
  --dry-run \
  --skip-existing
```

### Options

| Option | Description | Défaut |
|--------|-------------|--------|
| `--dir PATH` | Répertoire contenant les fichiers de zone | Requis |
| `--dry-run` | Mode prévisualisation - aucune modification effectuée | Désactivé |
| `--skip-existing` | Ignorer les zones qui existent déjà | Désactivé |
| `--verbose, -v` | Activer la journalisation détaillée | Désactivé |
| `--example` | Exécuter avec une zone d'exemple pour les tests | Désactivé |
| **Mode API** | | |
| `--api-url URL` | URL de base de l'application dns3 | Requis pour le mode API |
| `--api-token TOKEN` | Jeton d'authentification API (Bearer) | Requis pour le mode API |
| **Mode Base de données** | | |
| `--db-mode` | Utiliser l'insertion directe dans la base de données | Désactivé (mode API par défaut) |
| `--db-host HOST` | Nom d'hôte du serveur de base de données | localhost |
| `--db-port PORT` | Port du serveur de base de données | 3306 |
| `--db-user USER` | Nom d'utilisateur de la base de données | root |
| `--db-pass PASS` | Mot de passe de la base de données | Chaîne vide |
| `--db-name NAME` | Nom de la base de données | dns3_db |
| **Autre** | | |
| `--user-id ID` | ID utilisateur pour le champ created_by | 1 |
| `--create-includes` | Créer des entrées pour les directives $INCLUDE | Désactivé |

---

## Importeur Bash

L'importeur Bash (`scripts/import_bind_zones.sh`) est une alternative légère pour les fichiers de zone simples. Il utilise une analyse heuristique et convient aux zones simples sans fonctionnalités complexes.

### Fonctionnalités

- **Aucune dépendance** : Script Bash pur, nécessite uniquement le client MySQL
- **Analyse heuristique** : Analyse simple basée sur des regex pour les types d'enregistrement courants
- **Détection du schéma** : Introspection du schéma de base de données via information_schema
- **Support dry-run** : Mode prévisualisation pour les tests
- **Protection contre l'injection SQL** : Valide les identifiants et échappe les valeurs

### Limitations

⚠️ **ATTENTION** : L'importeur Bash a des limitations :

- **Analyseur heuristique** : Peut ne pas gérer correctement les enregistrements complexes ou multi-lignes
- **Types d'enregistrement limités** : Prend en charge uniquement A, AAAA, CNAME, MX, NS, PTR, TXT, SRV, CAA
- **Pas de support $INCLUDE** : Ne peut pas traiter les directives $INCLUDE
- **Pas de DNSSEC** : Ne prend pas en charge les enregistrements DNSSEC (DNSKEY, RRSIG, etc.)
- **SOA simple** : L'analyse SOA de base peut échouer avec un formatage non standard
- **Pas de validation** : Ne valide pas la syntaxe de zone avant l'importation

**Recommandation** : Utilisez l'importeur Python pour :
- Les zones complexes avec des directives $INCLUDE
- Les zones avec des enregistrements DNSSEC
- Les enregistrements multi-lignes ou formatage non standard
- Les environnements de production nécessitant de la précision

Utilisez l'importeur Bash uniquement pour :
- Les zones de test simples
- Les importations rapides de fichiers de zone simples
- Les environnements où Python n'est pas disponible

### Utilisation

```bash
./scripts/import_bind_zones.sh \
  --dir /var/named/zones \
  --db-user root \
  --db-pass YOUR_PASSWORD
```

**Avec options** :

```bash
./scripts/import_bind_zones.sh \
  --dir /var/named/zones \
  --db-user root \
  --db-pass YOUR_PASSWORD \
  --db-name dns3_db \
  --dry-run \
  --skip-existing
```

### Options

| Option | Description | Défaut |
|--------|-------------|--------|
| `--dir PATH` | Répertoire contenant les fichiers de zone | Requis |
| `--dry-run` | Mode prévisualisation - aucune modification effectuée | Désactivé |
| `--db-host HOST` | Nom d'hôte du serveur de base de données | localhost |
| `--db-port PORT` | Port du serveur de base de données | 3306 |
| `--db-user USER` | Nom d'utilisateur de la base de données | root |
| `--db-pass PASS` | Mot de passe de la base de données | Demande si non fourni |
| `--db-name NAME` | Nom de la base de données | dns3_db |
| `--skip-existing` | Ignorer les zones qui existent déjà | Désactivé |
| `--user-id ID` | ID utilisateur pour le champ created_by | 1 |

---

## Comparaison

| Fonctionnalité | Importeur Python | Importeur Bash |
|----------------|------------------|----------------|
| **Précision d'analyse** | Élevée (conforme RFC) | Faible (heuristique) |
| **Dépendances** | Python, dnspython, requests/pymysql | Bash, client mysql |
| **Mode API** | ✅ Oui | ❌ Non |
| **Mode DB** | ✅ Oui | ✅ Oui |
| **Support $ORIGIN** | ✅ Oui | ⚠️ Basique |
| **Support $INCLUDE** | ✅ Oui (avec flag) | ❌ Non |
| **Analyse SOA** | ✅ Complète | ⚠️ Basique |
| **Types d'enregistrement** | ✅ Tous types | ⚠️ Types courants uniquement |
| **Support DNSSEC** | ✅ Oui | ❌ Non |
| **Enregistrements multi-lignes** | ✅ Oui | ❌ Non |
| **Gestion des erreurs** | ✅ Complète | ⚠️ Basique |
| **Performance** | Moyenne | Rapide |
| **Recommandé pour** | Production, zones complexes | Tests, zones simples |

---

## Exemples

### Exemple 1 : Dry-run avec Python (mode API)

Tester ce qui serait importé sans effectuer de modifications :

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url http://localhost/dns3 \
  --api-token abc123xyz \
  --dry-run \
  --verbose
```

Sortie :
```
2024-12-08 15:00:00 [INFO] Using API mode (HTTP requests)
2024-12-08 15:00:00 [INFO] DRY-RUN mode enabled - no changes will be made
2024-12-08 15:00:00 [INFO] Found 3 zone file(s) in /var/named/zones
2024-12-08 15:00:00 [INFO] Processing zone file: example.com.zone
2024-12-08 15:00:00 [INFO] [DRY-RUN] Would create zone: example.com
2024-12-08 15:00:00 [INFO] [DRY-RUN] Would create 15 records
...
2024-12-08 15:00:05 [INFO] Import Statistics:
2024-12-08 15:00:05 [INFO]   Zones created: 3
2024-12-08 15:00:05 [INFO]   Records created: 45
2024-12-08 15:00:05 [INFO]   Errors: 0
```

### Exemple 2 : Import avec Python (mode DB)

Import direct dans la base de données avec saut des zones existantes :

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --db-mode \
  --db-user dns3_user \
  --db-pass secretpassword \
  --db-name dns3_db \
  --skip-existing
```

### Exemple 3 : Import avec Bash (zones simples)

Import de zones simples avec le script Bash :

```bash
./scripts/import_bind_zones.sh \
  --dir /var/named/simple_zones \
  --db-user root \
  --db-pass password \
  --dry-run
```

### Exemple 4 : Test avec zone d'exemple

Test rapide avec l'exemple intégré :

```bash
python3 scripts/import_bind_zones.py --example
```

Sortie :
```
2024-12-08 15:00:00 [INFO] Running in EXAMPLE mode with sample zone data
Sample zone content:

$ORIGIN example.com.
$TTL 3600
@       IN      SOA     ns1.example.com. admin.example.com. (...)
        IN      NS      ns1.example.com.
        IN      A       192.0.2.1
www     IN      A       192.0.2.1
...

Parsed zone successfully!

Extracted 7 records:
  - example.com. 3600 IN NS ns1.example.com.
  - example.com. 3600 IN NS ns2.example.com.
  - example.com. 3600 IN A 192.0.2.1
  - www.example.com. 3600 IN A 192.0.2.1
  ...
```

### Exemple 5 : Import avec jeton d'authentification

Utilisation du mode API avec authentification appropriée :

```bash
# Set API token as environment variable (recommended)
export DNS3_API_TOKEN="your-secret-token-here"

python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url https://dns.example.com \
  --api-token "$DNS3_API_TOKEN" \
  --skip-existing
```

---

## Dépannage

### Problèmes courants

#### 1. Dépendances Python non trouvées

**Erreur** : `ImportError: No module named 'dns'`

**Solution** : Installez dnspython :
```bash
pip3 install dnspython
```

#### 2. Échec de l'authentification API

**Erreur** : `API error creating zone: 401 - Authentication required`

**Solution** : 
- Vérifiez que votre jeton API est correct
- Vérifiez que le jeton n'est pas expiré
- Assurez-vous d'utiliser le format de jeton `Bearer`
- Testez l'endpoint API manuellement : `curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost/dns3/api/zone_api.php?action=list_zones`

#### 3. Échec de la connexion à la base de données

**Erreur** : `Database connection failed: Access denied for user`

**Solution** :
- Vérifiez les identifiants de la base de données
- Vérifiez que l'utilisateur MySQL a les privilèges nécessaires : `GRANT ALL ON dns3_db.* TO 'user'@'localhost';`
- Testez la connexion manuellement : `mysql -u user -p dns3_db`

#### 4. Échec de l'analyse de zone

**Erreur** : `Failed to parse zone file: unexpected end of file`

**Solution** :
- Vérifiez la syntaxe du fichier de zone : `named-checkzone example.com /path/to/zone/file`
- Assurez-vous que $ORIGIN est correctement défini
- Vérifiez que le fichier de zone n'est pas corrompu
- Utilisez l'importeur Python au lieu de Bash pour les zones complexes

#### 5. Enregistrements non créés

**Problème** : Zones créées mais aucun enregistrement n'apparaît

**Solution** :
- Vérifiez les journaux avec le flag `--verbose`
- Vérifiez que l'enregistrement SOA n'est pas le seul enregistrement dans la zone
- Vérifiez que les types d'enregistrement sont pris en charge par le schéma de base de données
- Assurez-vous que la clé étrangère zone_file_id est correctement définie

#### 6. L'analyseur Bash échoue sur des zones valides

**Problème** : L'importeur Bash ignore des enregistrements valides

**Solution** :
- Utilisez l'importeur Python pour une analyse précise
- L'analyseur Bash est heuristique et peut ne pas gérer tous les formats
- Vérifiez que le fichier de zone a un formatage standard (un enregistrement par ligne pour les enregistrements simples)

#### 7. Erreurs de permission refusée

**Erreur** : `Permission denied` lors de l'accès aux fichiers de zone

**Solution** :
```bash
# Check file permissions
ls -l /var/named/zones/

# Make readable by your user
sudo chmod +r /var/named/zones/*.zone

# Or run as appropriate user
sudo -u named python3 scripts/import_bind_zones.py ...
```

### Conseils de débogage

1. **Activer la journalisation détaillée** :
   ```bash
   python3 scripts/import_bind_zones.py --dir /path/to/zones --verbose ...
   ```

2. **Tester avec un seul fichier de zone** :
   ```bash
   # Create test directory with single zone
   mkdir /tmp/test_import
   cp /var/named/zones/example.com.zone /tmp/test_import/
   python3 scripts/import_bind_zones.py --dir /tmp/test_import --dry-run ...
   ```

3. **Vérifier le schéma de base de données** :
   ```bash
   mysql -u root -p dns3_db -e "DESCRIBE zone_files;"
   mysql -u root -p dns3_db -e "DESCRIBE dns_records;"
   ```

4. **Valider la syntaxe du fichier de zone** :
   ```bash
   named-checkzone example.com /var/named/zones/example.com.zone
   ```

5. **Tester les endpoints API manuellement** :
   ```bash
   # Test zone API
   curl -X POST -H "Authorization: Bearer TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name":"test.com","filename":"test.zone","file_type":"master"}' \
     http://localhost/dns3/api/zone_api.php?action=create_zone
   ```

### Obtenir de l'aide

Si vous rencontrez des problèmes non couverts ici :

1. Vérifiez les journaux de l'application : `/var/log/dns3/` ou les journaux d'erreur du serveur web
2. Consultez les journaux de base de données pour les erreurs SQL
3. Testez avec le flag `--example` pour vérifier la fonctionnalité de base
4. Vérifiez le format du fichier de zone avec `named-checkzone`
5. Vérifiez que le schéma de base de données correspond aux attentes dans `structure_ok_dns3_db.sql`

### Considérations de performance

Pour les importations volumineuses (centaines/milliers de zones) :

- **Utilisez le mode DB** pour de meilleures performances (évite la surcharge HTTP)
- **Désactivez temporairement les vérifications de clé étrangère** (uniquement en mode DB, environnement de test)
- **Importez par lots** plutôt que tout d'un coup
- **Surveillez les performances de la base de données** pendant l'importation
- **Utilisez `--skip-existing`** pour éviter les importations redondantes

Exemple pour les importations volumineuses :
```bash
# Import in batches
for batch in batch1 batch2 batch3; do
  python3 scripts/import_bind_zones.py \
    --dir /var/named/zones/$batch \
    --db-mode \
    --db-user root \
    --db-pass password \
    --skip-existing
  
  # Give database time to process
  sleep 10
done
```

---

## Résumé

- **Utilisez l'importeur Python pour la production** : Plus précis, prend en charge les zones complexes
- **Utilisez le mode API quand c'est possible** : Exploite l'authentification et la validation de l'application
- **Testez toujours avec --dry-run d'abord** : Prévisualisez les modifications avant de les appliquer
- **Sauvegardez la base de données avant l'importation** : La sécurité d'abord !
- **Utilisez l'importeur Bash uniquement pour les cas de test simples** : Précision limitée

Pour la plupart des cas d'utilisation, la commande recommandée est :

```bash
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --api-url http://localhost/dns3 \
  --api-token YOUR_TOKEN \
  --dry-run \
  --skip-existing
```

Ensuite, retirez `--dry-run` après avoir vérifié la sortie.
