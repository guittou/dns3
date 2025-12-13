# Correction de l'affichage du domaine DNS - Notes d'implémentation

## Vue d'ensemble
Correction de l'affichage du domaine DNS pour montrer le domaine maître pour les zones include au lieu du nom de fichier include (par exemple, "test.fr" au lieu de "include1").

## Énoncé du problème
Après la migration de `domaine_list.domain` vers `zone_files.domain`, la page de gestion DNS affichait :
- ❌ Nom de fichier de zone include (par exemple, "include1") dans la colonne "Domaine" et le combobox
- ✅ Attendu : Domaine du parent maître (par exemple, "test.fr")

## Analyse de la cause racine
Le combobox de domaine était en lecture seule et ne chargeait pas les domaines disponibles depuis les zones maîtres. Les utilisateurs ne pouvaient pas filtrer par domaine, et le système n'affichait pas correctement les informations de domaine pour les zones include.

## Architecture de la solution

### Backend (Déjà correct - Aucune modification requise)

#### 1. Database Schema
```sql
-- zone_files table has domain column (added in migration 015)
ALTER TABLE zone_files ADD COLUMN `domain` VARCHAR(255) DEFAULT NULL;

-- zone_file_includes table manages parent-child relationships
CREATE TABLE zone_file_includes (
  parent_id INT(11),
  include_id INT(11),
  position INT(11)
);
```

#### 2. DnsRecord Model (includes/models/DnsRecord.php)

**Requête SQL avec JOINs appropriés :**
```php
$sql = "SELECT dr.*, 
               zf.domain as zone_domain,
               zf.file_type as zone_file_type,
               p.domain as parent_domain
        FROM dns_records dr
        LEFT JOIN zone_files zf ON dr.zone_file_id = zf.id
        LEFT JOIN zone_file_includes zfi ON zf.id = zfi.include_id
        LEFT JOIN zone_files p ON zfi.parent_id = p.id";
```

**Logique de calcul de domain_name :**
```php
$fileType = $record['zone_file_type'] ?? 'master';
if ($fileType === 'master') {
    // Master zone: use zone_domain (no fallback to zone_name)
    $record['domain_name'] = (!empty($record['zone_domain'])) ? 
                              $record['zone_domain'] : null;
} else {
    // Include zone: use parent_domain (no fallback)
    $record['domain_name'] = (!empty($record['parent_domain'])) ? 
                              $record['parent_domain'] : null;
}
```

#### 3. DNS API (api/dns_api.php)

**Point de terminaison list_domains :**
```php
// Retourne seulement les zones maîtres avec le champ domain défini
SELECT zf.id, zf.domain, zf.name as zone_name
FROM zone_files zf
WHERE zf.domain IS NOT NULL 
  AND zf.domain != ''
  AND zf.status = 'active'
  AND zf.file_type = 'master'
ORDER BY zf.domain ASC
```

### Modifications du frontend

#### 1. Combobox de domaine (assets/js/dns-records.js)

**Avant (Incorrect) :**
```javascript
async function initDomainCombobox() {
    const input = document.getElementById('dns-domain-input');
    if (input) {
        input.readOnly = true;  // ❌ Read-only, no interaction
        input.placeholder = 'Sélectionnez d\'abord une zone';
    }
}
```

**Après (Correct) :**
```javascript
async function initDomainCombobox() {
    // Load all domains from master zones
    const result = await apiCall('list_domains');
    allDomains = result.data || [];
    
    const input = document.getElementById('dns-domain-input');
    const list = document.getElementById('dns-domain-list');
    
    // Make input interactive
    input.readOnly = false;
    input.placeholder = 'Rechercher un domaine...';
    
    // Input event - filter domains
    input.addEventListener('input', () => {
        const query = input.value.toLowerCase().trim();
        const filtered = allDomains.filter(d => 
            d.domain.toLowerCase().includes(query)
        );
        populateComboboxList(list, filtered, ...);
    });
    
    // Focus - show all domains
    input.addEventListener('focus', () => {
        populateComboboxList(list, allDomains, ...);
    });
    
    // Blur, Escape handlers...
}
```

#### 2. Rendu du tableau (Déjà correct)
```javascript
// Table already uses domain_name field
const domainDisplay = escapeHtml(record.domain_name || '-');
row.innerHTML = `
    <td class="col-domain">${domainDisplay}</td>
    ...
`;
```

#### 3. Modal de zone (zone-files.js - Déjà correct)
```javascript
// Domain field shown only for masters
const group = document.getElementById('zoneDomainGroup');
if (group) {
    group.style.display = ((zone.file_type || 'master') === 'master') 
                          ? 'block' : 'none';
}
```

## Flux de données

### Scénario 1 : Chargement du tableau des enregistrements DNS

```
L'utilisateur charge la page
    ↓
initDomainCombobox() appelé
    ↓
apiCall('list_domains')
    ↓
dns_api.php?action=list_domains
    ↓
Retourne : [
    {id: 260, domain: "test.fr"},
    {id: 261, domain: "example.com"}
]
    ↓
Combobox de domaine rempli
    ↓
loadDnsTable() appelé
    ↓
apiCall('list')
    ↓
dns_api.php?action=list
    ↓
$dnsRecord->search()
    ↓
SQL avec JOINs exécuté
    ↓
domain_name calculé pour chaque enregistrement
    ↓
Retourne : [
    {
        id: 123,
        name: "www",
        zone_name: "test.fr",
        zone_file_type: "master",
        zone_domain: "test.fr",
        domain_name: "test.fr"  // ✅ Maître
    },
    {
        id: 456,
        name: "mail", 
        zone_name: "include1",
        zone_file_type: "include",
        parent_domain: "test.fr",
        domain_name: "test.fr"  // ✅ Include -> parent
    }
]
    ↓
Tableau rendu avec domain_name
```

### Scénario 2 : Clic sur un enregistrement include

```
L'utilisateur clique sur une ligne d'enregistrement
    ↓
Gestionnaire de clic de ligne
    ↓
zoneFileId = record.zone_file_id
    ↓
setDomainForZone(zoneFileId)
    ↓
zoneApiCall('get_zone', {id: zoneFileId})
    ↓
zone_api.php?action=get_zone&id=260
    ↓
ZoneFile->getById(260)
    ↓
SQL avec JOIN parent_domain
    ↓
Retourne : {
    id: 260,
    name: "include1",
    file_type: "include",
    parent_id: 259,
    parent_domain: "test.fr"
}
    ↓
Logique setDomainForZone :
    if (zone.file_type === 'master') {
        domainName = zone.domain || '';
    } else {
        domainName = zone.parent_domain || '';  // ✅
    }
    ↓
L'entrée de domaine affiche "test.fr"
```

## Vérification des tests

### Étapes de test manuel

1. **Chargement du combobox de domaine :**
   - Ouvrir la page de gestion DNS
   - Cliquer sur l'entrée de domaine
   - Vérifier que le menu déroulant affiche tous les domaines maîtres
   - Taper pour filtrer les domaines
   - Sélectionner un domaine et vérifier le filtrage des zones

2. **Le tableau affiche le bon domaine :**
   - Pour les enregistrements de zone maître : Affiche zone_files.domain
   - Pour les enregistrements de zone include : Affiche le domaine du parent maître
   - Pour les maîtres sans domaine : Affiche "-"

3. **Clic sur un enregistrement include :**
   - Cliquer sur un enregistrement appartenant à une zone include
   - Vérifier que l'entrée de domaine affiche le domaine du parent (par exemple, "test.fr")
   - Pas le nom de fichier include (par exemple, "include1")

4. **Modal de zone :**
   - Ouvrir le modal de zone maître : Champ de domaine visible et modifiable
   - Ouvrir le modal de zone include : Champ de domaine masqué

### Tests API

**Test 1 : list_domains**
```bash
curl -X GET "http://localhost/api/dns_api.php?action=list_domains" \
     -H "Cookie: PHPSESSID=..." \
     -H "Accept: application/json"
```

Réponse attendue :
```json
{
  "success": true,
  "data": [
    {"id": 260, "domain": "example.com", "zone_name": "example.com"},
    {"id": 261, "domain": "test.fr", "zone_name": "test.fr"}
  ]
}
```

**Test 2 : list (avec enregistrements include)**
```bash
curl -X GET "http://localhost/api/dns_api.php?action=list" \
     -H "Cookie: PHPSESSID=..." \
     -H "Accept: application/json"
```

Réponse attendue :
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "name": "www",
      "zone_name": "test.fr",
      "zone_file_type": "master",
      "zone_domain": "test.fr",
      "parent_domain": null,
      "domain_name": "test.fr"
    },
    {
      "id": 456,
      "name": "mail",
      "zone_name": "include1",
      "zone_file_type": "include",
      "zone_domain": null,
      "parent_domain": "test.fr",
      "domain_name": "test.fr"
    }
  ]
}
```

**Test 3 : get_zone (include)**
```bash
curl -X GET "http://localhost/api/zone_api.php?action=get_zone&id=260" \
     -H "Cookie: PHPSESSID=..." \
     -H "Accept: application/json"
```

Réponse attendue :
```json
{
  "success": true,
  "data": {
    "id": 260,
    "name": "include1",
    "filename": "include1.conf",
    "file_type": "include",
    "domain": null,
    "parent_id": 259,
    "parent_name": "test.fr",
    "parent_domain": "test.fr"
  }
}
```

## Fichiers modifiés

- `assets/js/dns-records.js` : Fonction initDomainCombobox() mise à jour

## Fichiers vérifiés (Aucune modification requise)

- `includes/models/DnsRecord.php` : Calcule déjà domain_name correctement
- `api/dns_api.php` : Utilise déjà le modèle DnsRecord avec les JOINs corrects
- `includes/models/ZoneFile.php` : Retourne déjà parent_domain
- `api/zone_api.php` : Expose déjà les informations du parent
- `assets/js/zone-files.js` : Affiche déjà le champ de domaine uniquement pour les maîtres

## Plan de rollback

Si des problèmes sont découverts après le déploiement :

```bash
# Option 1 : Annuler le commit
git revert <commit-hash>
git push origin <branch>

# Option 2 : Correction rapide - remettre l'entrée de domaine en lecture seule
# Éditer assets/js/dns-records.js :
async function initDomainCombobox() {
    const input = document.getElementById('dns-domain-input');
    if (input) {
        input.readOnly = true;
        input.placeholder = 'Sélectionnez d\'abord une zone';
    }
}
```

Le changement est minimal et réversible. La logique backend est inchangée, ce qui réduit les risques.

## Considérations de sécurité

- ✅ Pas de risques d'injection SQL (utilise des requêtes préparées PDO)
- ✅ Pas de risques XSS (utilise escapeHtml() pour toutes les données utilisateur)
- ✅ Authentification requise pour tous les points de terminaison API
- ✅ Aucun nouveau point de terminaison créé
- ✅ Analyse CodeQL réussie avec 0 vulnérabilité

## Impact sur les performances

- **Minimal** : Un appel API supplémentaire au chargement de la page (list_domains)
- **Optimisé** : list_domains filtre uniquement les maîtres
- **Mis en cache** : Liste de domaines chargée une fois et mise en cache en mémoire
- **Pas de N+1** : SQL utilise des JOINs appropriés, pas de requêtes multiples

## Compatibilité des navigateurs

- ✅ Navigateurs modernes (Chrome, Firefox, Safari, Edge)
- ✅ ES6 async/await (supporté dans tous les navigateurs modernes)
- ✅ Aucun polyfill requis
- ✅ Dégradation gracieuse si JavaScript désactivé (mode lecture seule)

## Limitations connues

1. **Le champ de domaine est optionnel** : Les maîtres sans domaine afficheront "-" dans le tableau
2. **Chaînes d'include** : Seul le domaine du parent direct est affiché (pas le grand-parent)
3. **Références circulaires** : Protégé par la constante MAX_ZONE_TRAVERSAL_DEPTH

## Améliorations futures

1. Ajouter la validation du champ de domaine dans le modal de création/édition de zone
2. Afficher la chaîne de parents complète pour les includes imbriqués
3. Ajouter le champ de domaine aux zones include (pour les scénarios de remplacement)
4. Ajouter un outil d'attribution de domaine en masse pour les maîtres existants

## Références

> **Note** : Les fichiers de migration ont été supprimés. Le schéma complet est dans `database.sql`.

- Problème d'origine : GitHub Issue #XXX (le cas échéant)
- PR associée : #137 (migration de domaine précédente)

---

**Auteur** : Copilot Agent  
**Date** : 2025-11-09  
**Statut** : ✅ Implémentation terminée  
**Analyse de sécurité** : ✅ Réussie (0 vulnérabilité)
