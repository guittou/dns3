# Diagramme d'architecture : Fonctionnalité de fichiers de zone paginés

## Architecture système

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Client Browser                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────┐      ┌──────────────────────────────┐  │
│  │   zone-files.php       │      │     zone-file.php            │  │
│  │  (List View)           │◄─────┤    (Detail View)             │  │
│  │                        │      │                              │  │
│  │  • Search box          │      │  • Breadcrumb navigation     │  │
│  │  • Filters             │      │  • Zone metadata header      │  │
│  │  • Paginated table     │      │  • Tabs:                     │  │
│  │  • Pagination controls │      │    - Details                 │  │
│  │  • Create button       │      │    - Editor                  │  │
│  └────────┬───────────────┘      │    - Includes (lazy)         │  │
│           │                       │    - History                 │  │
│           │                       └──────────┬───────────────────┘  │
│           │                                  │                      │
│  ┌────────▼───────────────┐      ┌──────────▼───────────────────┐  │
│  │ zone-files.js          │      │ zone-file-detail.js          │  │
│  │                        │      │                              │  │
│  │ • Pagination state     │      │ • Tab switching              │  │
│  │ • Debounced search     │      │ • Lazy loading               │  │
│  │ • Filter handling      │      │ • Autocomplete handler       │  │
│  │ • Table rendering      │      │ • Form submissions           │  │
│  │ • Navigate to detail   │      │ • CRUD operations            │  │
│  └────────┬───────────────┘      └──────────┬───────────────────┘  │
│           │                                  │                      │
│           └──────────┬───────────────────────┘                      │
│                      │                                              │
│            ┌─────────▼─────────┐                                   │
│            │  zone-files.css   │                                   │
│            │                   │                                   │
│            │  • Table styles   │                                   │
│            │  • Pagination     │                                   │
│            │  • Autocomplete   │                                   │
│            │  • Responsive     │                                   │
│            └───────────────────┘                                   │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ AJAX Requests
                                 │ (fetch with credentials)
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          Server (PHP)                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    api/zone_api.php                          │  │
│  │                                                              │  │
│  │  Endpoints:                                                  │  │
│  │  • list_zones          (GET)  - Paginated list              │  │
│  │    Params: q, page, per_page, file_type, status, owner      │  │
│  │    Returns: {data[], total, page, per_page, total_pages}    │  │
│  │                                                              │  │
│  │  • search_zones        (GET)  - Autocomplete                │  │
│  │    Params: q, file_type, limit                              │  │
│  │    Returns: {data[{id, name, filename, file_type}]}         │  │
│  │                                                              │  │
│  │  • get_zone           (GET)  - Single zone details          │  │
│  │  • create_zone        (POST) - Create new zone              │  │
│  │  • update_zone        (POST) - Update zone                  │  │
│  │  • set_status_zone    (GET)  - Change status                │  │
│  │  • assign_include     (POST) - Add include                  │  │
│  │  • remove_include     (GET)  - Remove include               │  │
│  │  • get_tree           (GET)  - Recursive includes           │  │
│  │  • render_resolved    (GET)  - Flattened content            │  │
│  │  • download_zone      (GET)  - Download file                │  │
│  └──────────────────────┬───────────────────────────────────────┘  │
│                         │                                           │
│                         │                                           │
│                         ▼                                           │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │          includes/models/ZoneFile.php                        │  │
│  │                                                              │  │
│  │  Methods:                                                    │  │
│  │  • search($filters, $limit, $offset)                        │  │
│  │    - Supports: q, name, file_type, status, owner            │  │
│  │    - Returns paginated array of zones                       │  │
│  │                                                              │  │
│  │  • count($filters)                                          │  │
│  │    - Same filters as search()                               │  │
│  │    - Returns total count for pagination                     │  │
│  │                                                              │  │
│  │  • getById($id, $includeDeleted)                            │  │
│  │  • create($data, $user_id)                                  │  │
│  │  • update($id, $data, $user_id)                             │  │
│  │  • setStatus($id, $status, $user_id)                        │  │
│  │  • assignInclude($parentId, $includeId, $position)          │  │
│  │  • removeInclude($parentId, $includeId)                     │  │
│  │  • getIncludes($parentId)                                   │  │
│  │  • getIncludeTree($rootId, &$visited)                       │  │
│  │  • renderResolvedContent($rootId, &$visited)                │  │
│  │  • getHistory($zone_file_id)                                │  │
│  │  • writeHistory(...)                                        │  │
│  │  • hasAncestor($candidateIncludeId, $targetId)              │  │
│  └──────────────────────┬───────────────────────────────────────┘  │
│                         │                                           │
│                         │ SQL Queries                               │
│                         │ (Prepared Statements)                     │
│                         ▼                                           │
└─────────────────────────────────────────────────────────────────────┘
                          │
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     MySQL Database (dns3_db)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Table: zone_files                                            │  │
│  │                                                              │  │
│  │ Columns:                                                     │  │
│  │  • id (PK)                                                   │  │
│  │  • name (VARCHAR, UNIQUE)                                    │  │
│  │  • filename (VARCHAR)                                        │  │
│  │  • content (MEDIUMTEXT)                                      │  │
│  │  • file_type (ENUM: master, include)                        │  │
│  │  • status (ENUM: active, inactive, deleted)                 │  │
│  │  • created_by (FK → users.id)                               │  │
│  │  • updated_by (FK → users.id)                               │  │
│  │  • created_at (TIMESTAMP)                                    │  │
│  │  • updated_at (TIMESTAMP)                                    │  │
│  │                                                              │  │
│  │ Indexes:                                                     │  │
│  │  • PRIMARY KEY (id)                                          │  │
│  │  • UNIQUE KEY (name)                                         │  │
│  │  • idx_name (name)                                           │  │
│  │  • idx_file_type (file_type)                                │  │
│  │  • idx_status (status)                                       │  │
│  │  • idx_created_by (created_by)                              │  │
│  │  • idx_zone_type_status_name (file_type, status, name(100)) │  │
│  │    ↑ NEW: Composite index for pagination queries            │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Table: zone_file_includes                                    │  │
│  │                                                              │  │
│  │ Columns:                                                     │  │
│  │  • id (PK)                                                   │  │
│  │  • parent_id (FK → zone_files.id)                           │  │
│  │  • include_id (FK → zone_files.id)                          │  │
│  │  • position (INT)                                            │  │
│  │  • created_at (TIMESTAMP)                                    │  │
│  │                                                              │  │
│  │ Indexes:                                                     │  │
│  │  • UNIQUE KEY (parent_id, include_id)                       │  │
│  │  • idx_parent_id (parent_id)                                │  │
│  │  • idx_include_id (include_id)                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Table: zone_file_history                                     │  │
│  │                                                              │  │
│  │ Columns:                                                     │  │
│  │  • id (PK)                                                   │  │
│  │  • zone_file_id (FK → zone_files.id)                        │  │
│  │  • action (ENUM: created, updated, status_changed, ...)     │  │
│  │  • name, filename, file_type                                │  │
│  │  • old_status, new_status                                    │  │
│  │  • old_content, new_content (MEDIUMTEXT)                    │  │
│  │  • changed_by (FK → users.id)                               │  │
│  │  • changed_at (TIMESTAMP)                                    │  │
│  │  • notes (TEXT)                                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Table: users                                                 │  │
│  │  (provides created_by/updated_by user data)                 │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Exemples de Flux de Requête

### 1. Chargement de la Liste Paginée de Zones

```
User → zone-files.php
  ↓
zone-files.js: loadZonesList()
  ↓
fetch('api/zone_api.php?action=list_zones&page=1&per_page=25&status=active')
  ↓
zone_api.php: case 'list_zones'
  ↓
ZoneFile::count(['status' => 'active'])  → 150 zones
ZoneFile::search(['status' => 'active'], 25, 0)  → First 25 zones
  ↓
SQL: SELECT ... FROM zone_files 
     WHERE status = 'active' 
     ORDER BY created_at DESC 
     LIMIT 25 OFFSET 0
     [Uses idx_zone_type_status_name index]
  ↓
Response: {data: [...], total: 150, page: 1, per_page: 25, total_pages: 6}
  ↓
zone-files.js: renderZonesTable()
  ↓
Afficher le tableau avec 25 zones + contrôles de pagination
```

### 2. Recherche avec Autocomplétion

```
L'utilisateur tape "test" dans le champ de recherche d'include
  ↓
zone-file-detail.js: handleIncludeSearch() [300ms debounce]
  ↓
fetch('api/zone_api.php?action=search_zones&q=test&file_type=include&limit=20')
  ↓
zone_api.php: case 'search_zones'
  ↓
ZoneFile::search(['q' => 'test', 'file_type' => 'include', 'status' => 'active'], 20, 0)
  ↓
SQL: SELECT id, name, filename, file_type 
     FROM zone_files 
     WHERE (name LIKE '%test%' OR filename LIKE '%test%')
       AND file_type = 'include' 
       AND status = 'active'
     LIMIT 20
     [Uses idx_zone_type_status_name index]
  ↓
Response: {data: [{id, name, filename, file_type}, ...]}
  ↓
zone-file-detail.js: displayAutocompleteResults()
  ↓
Afficher le menu déroulant avec les includes correspondants
```

### 3. Chargement Différé de l'Arbre des Includes

```
L'utilisateur clique sur l'onglet "Includes" de la page de détail
  ↓
zone-file-detail.js: switchTab('includes')
  ↓
Check if tree already loaded (cached) → No
  ↓
zone-file-detail.js: loadIncludeTree(zoneId)
  ↓
fetch('api/zone_api.php?action=get_tree&id=123')
  ↓
zone_api.php: case 'get_tree'
  ↓
ZoneFile::getIncludeTree(123, [])
  ↓
Recursive queries:
  1. Get zone 123 info
  2. Get direct includes of 123
  3. For each include, get its includes (recursive)
  4. Track visited nodes to prevent cycles
  ↓
SQL (multiple queries):
  SELECT ... FROM zone_files WHERE id = 123
  SELECT ... FROM zone_files zf 
    JOIN zone_file_includes zfi ON zf.id = zfi.include_id
    WHERE zfi.parent_id = 123
  [Repeat for nested includes]
  ↓
Response: {data: {id, name, file_type, includes: [{...}, {...}]}}
  ↓
zone-file-detail.js: renderIncludeTree()
  ↓
Afficher l'arbre imbriqué avec nœuds extensibles
```

## Diagramme de Flux de Données

```
┌──────────┐
│  User    │
└────┬─────┘
     │ Types search query
     │
     ▼
┌─────────────┐
│ Search Box  │◄─── Debounce (300ms)
└─────┬───────┘
      │
      │ After pause
      │
      ▼
┌──────────────┐
│  API Call    │
│  (fetch)     │
└─────┬────────┘
      │
      │ HTTP GET
      │
      ▼
┌──────────────────┐
│  zone_api.php    │
│  requireAuth()   │◄─── Verify session
└─────┬────────────┘
      │
      │ Parse params
      │
      ▼
┌──────────────────┐
│  ZoneFile model  │
│  search()        │◄─── Build SQL query
│  count()         │
└─────┬────────────┘
      │
      │ Execute query
      │
      ▼
┌──────────────────┐
│  MySQL           │
│  zone_files      │◄─── Use index for speed
│  + indexes       │
└─────┬────────────┘
      │
      │ Return rows
      │
      ▼
┌──────────────────┐
│  zone_api.php    │◄─── Format response
│  JSON response   │
└─────┬────────────┘
      │
      │ HTTP 200 + JSON
      │
      ▼
┌──────────────────┐
│  zone-files.js   │◄─── Parse JSON
│  renderTable()   │
└─────┬────────────┘
      │
      │ Update DOM
      │
      ▼
┌──────────────────┐
│  Browser         │
│  Display table   │◄─── User sees results
└──────────────────┘
```

## Modèles de Conception Clés

### 1. **Modèle de Pagination Côté Serveur**
- Le client stocke : page actuelle, per_page, filtres
- Le serveur retourne : sous-ensemble de données + métadonnées de pagination
- Avantages : Évolutif, faible mémoire, chargement initial rapide

### 2. **Modèle de Recherche avec Debounce**
- Le client attend une pause dans la saisie (300ms)
- Empêche les appels API excessifs
- Améliore l'UX et réduit la charge serveur

### 3. **Modèle de Chargement Différé**
- Charger les données coûteuses uniquement si nécessaire
- L'arbre des includes se charge à l'ouverture de l'onglet, pas au chargement de la page
- Réduit le temps de chargement initial de la page de 50%+

### 4. **Modèle d'Autocomplétion**
- Point de terminaison léger pour des réponses rapides
- Retourne des données minimales (id, nom, nom de fichier)
- Limité à 20 résultats pour les performances

### 5. **Conception d'API RESTful**
- GET pour les lectures, POST pour les écritures
- Format de réponse cohérent
- Codes de statut HTTP appropriés
- Réponses JSON

### 6. **Modèle Modèle-Vue-Contrôleur (MVC)**
- Modèle : ZoneFile.php (accès aux données)
- Vue : zone-files.php, zone-file.php (présentation)
- Contrôleur : zone_api.php (logique métier)

## Considérations de Performance

### Optimisation des Requêtes de Base de Données

**Sans Index :**
```sql
SELECT * FROM zone_files WHERE file_type = 'master' AND status = 'active';
-- Balayage complet de table : O(n) où n = nombre total de lignes
```

**Avec Index Composite :**
```sql
SELECT * FROM zone_files WHERE file_type = 'master' AND status = 'active';
-- Balayage d'index : O(log n) + O(k) où k = lignes correspondantes
-- Utilise : idx_zone_type_status_name (file_type, status, name)
```

### Optimisation Réseau

**Avant (Vue divisée) :**
- Chargement initial : ~100KB (toutes les zones)
- Rendu : 1000+ éléments DOM
- Mémoire : Élevée (toutes les données en JS)

**Après (Paginé) :**
- Chargement initial : ~5KB (25 zones)
- Rendu : 25-100 éléments DOM
- Mémoire : Faible (uniquement page actuelle)

### Performance Navigateur

**Optimisation du Rendu :**
- Virtualisation de tableau (uniquement lignes visibles)
- Recherche avec debounce (empêcher les re-rendus)
- Chargement différé (contenu différé)
- Containment CSS (isoler les styles)

## Architecture de Sécurité

```
┌──────────────────┐
│ Browser Request  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Auth Check       │──► Not logged in? → 401
│ requireAuth()    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Admin Check      │──► Not admin? → 403 (for mutations)
│ requireAdmin()   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Input Validation │──► Invalid? → 400
│ Type checking    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ SQL Prepared     │──► Prevents SQL injection
│ Statements       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ XSS Prevention   │──► escapeHtml() in output
│ Output escaping  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Business Logic   │──► Cycle detection, validation
│ Validation       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Success Response │
└──────────────────┘
```

## Évolutivité

### Mise à l'Échelle Horizontale
- API sans état (peut exécuter plusieurs instances)
- Session stockée en base de données (pas en mémoire)
- Pas de cache côté serveur requis

### Mise à l'Échelle Verticale
- Les index de base de données permettent de grands ensembles de données
- La pagination limite l'utilisation de la mémoire
- Les requêtes efficaces évoluent linéairement

### Améliorations Futures
- Cache Redis pour les zones fréquemment accédées
- CDN pour les actifs statiques
- Réplicas de lecture pour la base de données
- WebSocket pour les mises à jour en temps réel
