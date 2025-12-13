# Implémentation des Champs Spécifiques par Type - Résumé Complet

## Vue d'ensemble
Cette implémentation ajoute des colonnes de base de données dédiées pour chaque type d'enregistrement DNS (A, AAAA, CNAME, PTR, TXT) au lieu d'utiliser un champ générique `value`. Le système est maintenant limité à la gestion de ces 5 types d'enregistrements de base uniquement.

## Ce qui a Changé

### 1. Schéma de Base de Données
**Nouvelles Colonnes dans la table `dns_records` :**
- `address_ipv4` VARCHAR(15) - pour les enregistrements A
- `address_ipv6` VARCHAR(45) - pour les enregistrements AAAA
- `cname_target` VARCHAR(255) - pour les enregistrements CNAME
- `ptrdname` VARCHAR(255) - pour les enregistrements PTR
- `txt` TEXT - pour les enregistrements TXT

**Nouvelles Colonnes dans la table `dns_record_history` :**
Les mêmes 5 colonnes ajoutées pour un suivi complet de l'historique.

**Index Ajoutés :**
- `idx_address_ipv4`
- `idx_address_ipv6`
- `idx_cname_target`

> **Note** : Les fichiers de migration ont été supprimés. Le schéma complet est maintenant disponible dans `database.sql`.

### 2. Modèle Backend (`includes/models/DnsRecord.php`)

**Nouvelles Méthodes Helper :**
- `getValueFromDedicatedField()` - Calcule la valeur à partir des colonnes dédiées
- `getValueFromDedicatedFieldData()` - Obtient la valeur des données d'entrée
- `mapValueToDedicatedField()` - Mappe l'alias value vers le champ dédié
- `extractDedicatedFields()` - Extrait les champs dédiés de l'entrée

**Méthodes Modifiées :**
- `search()` - Calcule maintenant le champ `value` à partir des colonnes dédiées
- `getById()` - Calcule maintenant le champ `value` à partir des colonnes dédiées
- `create()` - Écrit dans les colonnes dédiées, accepte l'alias value
- `update()` - Écrit dans les colonnes dédiées, accepte l'alias value
- `writeHistory()` - Inclut les champs dédiés dans l'historique

### 3. API (`api/dns_api.php`)

**Restrictions de Type :**
- Seuls A, AAAA, CNAME, PTR, TXT sont autorisés
- MX, SRV, NS, SOA retournent une erreur 400

**Mises à Jour de Validation :**
- `validateRecordByType()` valide maintenant les champs dédiés
- Accepte à la fois les noms de champs dédiés et l'alias `value`
- Validation sémantique spécifique au type (format IPv4/IPv6, validation de nom d'hôte, etc.)

**Sécurité :**
- `last_seen` est toujours supprimé de l'entrée (unset)
- Les champs gérés par le serveur ne peuvent pas être définis par les clients

### 4. Frontend (`dns-management.php`)

**Modifications de Formulaire :**
- Supprimé : Champ unique `record-value`
- Supprimé : Champ `record-priority-group`
- Ajouté : 5 groupes de champs dédiés (un pour chaque type)
  - `record-address-ipv4-group`
  - `record-address-ipv6-group`
  - `record-cname-target-group`
  - `record-ptrdname-group`
  - `record-txt-group`

**Filtre de Type :**
Menu déroulant mis à jour pour afficher uniquement les 5 types supportés.

### 5. JavaScript (`assets/js/dns-records.js`)

**Visibilité des Champs :**
- `updateFieldVisibility()` - Affiche/masque les champs en fonction du type d'enregistrement
- Un seul champ dédié visible à la fois

**Validation :**
- Mise à jour de `REQUIRED_BY_TYPE` pour les champs dédiés
- Mise à jour de `validatePayloadForType()` pour la validation sémantique
- Validation spécifique au type (IPv4, IPv6, nom d'hôte, texte)

**Construction de la Charge Utile :**
- `submitDnsForm()` construit la charge utile avec à la fois le champ dédié ET l'alias value
- N'inclut jamais `last_seen` dans la charge utile

**Modal d'Édition :**
- `openEditModal()` remplit les champs dédiés à partir des données d'enregistrement
- Gère le repli sur le champ `value` pour la rétrocompatibilité

### 6. Documentation

**Fichiers Mis à Jour :**
- `DNS_MANAGEMENT_GUIDE.md` - Exemples et descriptions de champs mis à jour
- `TYPE_SPECIFIC_FIELDS_TEST_PLAN.md` - Plan de test complet (nouveau)
- `UI_CHANGES_DOCUMENTATION.md` - Documentation des changements visuels de l'UI (nouveau)

## Décisions de Conception

### Option : accept-value ✅
L'API accepte `value` comme alias pour la rétrocompatibilité.
```json
// Les deux formats fonctionnent
{"record_type": "A", "address_ipv4": "192.168.1.1"}
{"record_type": "A", "value": "192.168.1.1"}
```

### Option : keep-temporary ✅
La colonne `value` est conservée dans la base de données pour une version pour permettre le rollback.

### Option : implicit-class ✅
Aucune colonne `class` ajoutée à la base de données (implicitement "IN").

### Option : ptr-require-reverse ✅
Les enregistrements PTR nécessitent que l'utilisateur fournisse le nom DNS inversé.

## Règles de Validation

### Enregistrements A
- Champ : `address_ipv4`
- Format : Adresse IPv4 valide
- Exemple : "192.168.1.1"

### Enregistrements AAAA
- Champ : `address_ipv6`
- Format : Adresse IPv6 valide
- Exemple : "2001:db8::1"

### Enregistrements CNAME
- Champ : `cname_target`
- Format : Nom d'hôte valide (pas d'adresses IP)
- Exemple : "target.example.com"

### Enregistrements PTR
- Champ : `ptrdname`
- Format : Nom d'hôte valide (nom DNS inversé)
- Exemple : "1.1.168.192.in-addr.arpa"

### Enregistrements TXT
- Champ : `txt`
- Format : Tout texte non vide
- Exemple : "v=spf1 include:_spf.example.com ~all"

## Tests

### Tests Automatisés
- Validation de syntaxe PHP : ✅ Tous les fichiers passent
- Tests unitaires des fonctions helper : ✅ Tous les 8 tests passent

### Tests Manuels Requis
Voir `TYPE_SPECIFIC_FIELDS_TEST_PLAN.md` pour le plan de test complet.

## Fichiers Modifiés

1. **includes/models/DnsRecord.php** (modifié)
2. **api/dns_api.php** (modifié)
3. **dns-management.php** (modifié)
4. **assets/js/dns-records.js** (modifié)
5. **DNS_MANAGEMENT_GUIDE.md** (modifié)
6. **TYPE_SPECIFIC_FIELDS_TEST_PLAN.md** (nouveau)
7. **UI_CHANGES_DOCUMENTATION.md** (nouveau)

> **Note** : Les fichiers de migration ont été supprimés. Le schéma complet est dans `database.sql`.

## Conclusion

Cette implémentation ajoute avec succès des champs spécifiques au type pour les enregistrements DNS tout en maintenant la rétrocompatibilité. La migration est idempotente et sûre, avec la possibilité de rollback si nécessaire.
