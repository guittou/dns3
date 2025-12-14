# Modifications Visuelles : Interface Created At / Updated At

## Modifications de la Vue Tableau

### Avant
```
| Nom | TTL | Classe | Type | Valeur | Demandeur | Expire | Vu le | Statut | ID | Actions |
|-----|-----|--------|------|--------|-----------|--------|-------|--------|----|---------| 
```

### Après
```
| Nom | TTL | Classe | Type | Valeur | Demandeur | Expire | Vu le | Créé le | Modifié le | Statut | ID | Actions |
|-----|-----|--------|------|--------|-----------|--------|-------|---------|------------|--------|----|---------| 
```

**Nouvelles Colonnes :**
- **Créé le** : Affiche l'horodatage de création de l'enregistrement (JJ/MM/AAAA HH:MM)
- **Modifié le** : Affiche l'horodatage de la dernière modification (JJ/MM/AAAA HH:MM)

### Exemple d'Affichage des Données

```
| Nom                  | ... | Vu le              | Créé le            | Modifié le         | Statut | ... |
|----------------------|-----|--------------------|--------------------|--------------------| -------|-----|
| example.com          | ... | 20/10/2025 14:30   | 15/10/2025 09:15   | 18/10/2025 11:20   | active | ... |
| test.example.com     | ... | -                  | 20/10/2025 08:00   | 20/10/2025 08:00   | active | ... |
| old-record.com       | ... | 10/10/2025 16:45   | 01/10/2025 10:00   | 15/10/2025 14:30   | active | ... |
```

## Modifications de la Vue Modale

### Mode Création (Nouvel Enregistrement)

**Champs Visibles :**
- Type d'enregistrement
- Nom
- Champ de valeur spécifique au type (Adresse IPv4 pour A, IPv6 pour AAAA, Cible pour CNAME, etc.)
- TTL
- Demandeur
- Date d'expiration
- Référence ticket
- Commentaire

**Champs NON Visibles :**
- ❌ Vu pour la dernière fois (masqué - pas encore consulté)
- ❌ Créé le (masqué - pas encore créé)
- ❌ Modifié le (masqué - pas encore modifié)

### Mode Édition (Enregistrement Existant)

**Champs Additionnels Visibles :**
- ✓ Vu pour la dernière fois (lecture seule, si l'enregistrement a été consulté)
- ✓ **Créé le** (lecture seule, affiche l'horodatage de création)
- ✓ **Modifié le** (lecture seule, affiche l'horodatage de dernière modification)

**Exemple de Contenu de la Modale (Mode Édition) :**
```
═══════════════════════════════════════════
  Modifier l'enregistrement DNS
═══════════════════════════════════════════

Type d'enregistrement: [A ▼]

Nom: [example.com                        ]

Adresse IPv4: [192.168.1.100             ]

TTL (secondes): [3600]

Demandeur: [Jean Dupont                  ]

Date d'expiration: [2025-12-31T23:59     ]

Référence ticket: [JIRA-1234              ]

Commentaire: [Record for production...   ]

Vu pour la dernière fois: [20/10/2025 14:30]
                          (désactivé, lecture seule)

Créé le: [15/10/2025 09:15]              ← NOUVEAU!
         (désactivé, lecture seule)

Modifié le: [18/10/2025 11:20]           ← NOUVEAU!
            (désactivé, lecture seule)

                    [Annuler] [Enregistrer]
═══════════════════════════════════════════
```

## Modifications de la Base de Données

### Instruction INSERT

**Avant :**
```sql
INSERT INTO dns_records (
    record_type, name, value, ..., status, created_by
)
VALUES (?, ?, ?, ..., 'active', ?)
```

**Après :**
```sql
INSERT INTO dns_records (
    record_type, name, value, ..., status, created_by, created_at
)
VALUES (?, ?, ?, ..., 'active', ?, NOW())
```

### Instruction UPDATE

**Aucune modification requise** - utilise déjà `updated_at = NOW()` :
```sql
UPDATE dns_records 
SET record_type = ?, name = ?, value = ?, ..., 
    updated_by = ?, updated_at = NOW()
WHERE id = ?
```

## Sécurité

### Requête Client (CREATE)
```json
{
  "record_type": "A",
  "name": "example.com",
  "address_ipv4": "192.168.1.100",
  "ttl": 3600,
  "created_at": "2020-01-01 00:00:00"  ← Ignoré par le serveur!
}
```

Le serveur va :
1. Supprimer `created_at` de la charge utile
2. Utiliser `NOW()` pour `created_at` dans le SQL
3. Empêcher la manipulation côté client

### Requête Client (UPDATE)
```json
{
  "name": "example.com",
  "ttl": 7200,
  "created_at": "2020-01-01 00:00:00",  ← Ignoré par le serveur!
  "updated_at": "2020-01-01 00:00:00"   ← Ignoré par le serveur!
}
```

Le serveur va :
1. Supprimer `created_at` et `updated_at` de la charge utile
2. Utiliser `NOW()` pour `updated_at` dans le SQL
3. Ne jamais modifier `created_at` (préserver l'original)
4. Empêcher la manipulation côté client

## Réponses API

### GET /api/dns_api.php?action=get&id=123

**La réponse inclut les horodatages :**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "record_type": "A",
    "name": "example.com",
    "address_ipv4": "192.168.1.100",
    "ttl": 3600,
    "created_at": "2025-10-15 09:15:00",    ← Retourné
    "updated_at": "2025-10-18 11:20:00",    ← Retourné
    "last_seen": "2025-10-20 14:30:00",
    "status": "active",
    ...
  }
}
```

### GET /api/dns_api.php?action=list

**Chaque enregistrement dans le tableau inclut les horodatages :**
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "name": "example.com",
      "created_at": "2025-10-15 09:15:00",  ← Retourné
      "updated_at": "2025-10-18 11:20:00",  ← Retourné
      ...
    },
    ...
  ]
}
```

## Flux d'Expérience Utilisateur

### Création d'un Nouvel Enregistrement
1. L'utilisateur clique sur "+ Créer un enregistrement"
2. La modale s'ouvre avec un formulaire vide
3. Les champs d'horodatage sont masqués (pas encore applicables)
4. L'utilisateur remplit les champs requis
5. L'utilisateur clique sur "Enregistrer"
6. Le serveur crée l'enregistrement avec `created_at = NOW()`
7. Le tableau se rafraîchit
8. Le nouvel enregistrement apparaît avec "Créé le" et "Modifié le" remplis

### Modification d'un Enregistrement Existant
1. L'utilisateur clique sur "Modifier" sur un enregistrement
2. La modale s'ouvre avec le formulaire prérempli
3. Les champs d'horodatage sont visibles et en lecture seule :
   - "Créé le" affiche l'heure de création d'origine
   - "Modifié le" affiche l'heure de dernière modification
   - "Vu pour la dernière fois" affiche l'heure de dernière consultation
4. L'utilisateur modifie un champ
5. L'utilisateur clique sur "Enregistrer"
6. Le serveur met à jour l'enregistrement avec `updated_at = NOW()`
7. Le tableau se rafraîchit
8. L'enregistrement affiche l'horodatage "Modifié le" mis à jour
9. "Créé le" reste inchangé

### Consultation du Tableau
1. L'utilisateur navigue vers la page de Gestion DNS
2. Le tableau se charge avec tous les enregistrements
3. Chaque ligne affiche les horodatages formatés :
   - "Créé le" : Affiche toujours l'heure de création
   - "Modifié le" : Affiche l'heure de dernière modification
   - Si null : affiche "-"
4. L'utilisateur peut filtrer/rechercher des enregistrements
5. Les horodatages restent visibles et formatés

## Implémentation Technique

### Formatage de Date JavaScript

Fonction utilisée : `formatDateTime(datetime)`
```javascript
function formatDateTime(datetime) {
    if (!datetime) return '';
    try {
        const date = new Date(datetime.replace(' ', 'T'));
        return date.toLocaleString('fr-FR', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch (e) {
        return datetime;
    }
}
```

**Entrée :** `"2025-10-15 09:15:00"` (format SQL)
**Sortie :** `"15/10/2025 09:15"` (locale française)

### Génération de Lignes de Tableau

```javascript
// Générer des lignes de tableau avec des classes sémantiques
currentRecords.forEach(record => {
    const row = document.createElement('tr');
    row.innerHTML = `
        <td class="col-name">${escapeHtml(record.name)}</td>
        <td class="col-ttl">${escapeHtml(record.ttl)}</td>
        <td class="col-class">${escapeHtml(record.class || 'IN')}</td>
        <td class="col-type">${escapeHtml(record.record_type)}</td>
        <td class="col-value">${escapeHtml(record.value)}</td>
        <td class="col-requester">${escapeHtml(record.requester || '-')}</td>
        <td class="col-expires">${record.expires_at ? formatDateTime(record.expires_at) : '-'}</td>
        <td class="col-lastseen">${record.last_seen ? formatDateTime(record.last_seen) : '-'}</td>
        <td class="col-created">${record.created_at ? formatDateTime(record.created_at) : '-'}</td>
        <td class="col-updated">${record.updated_at ? formatDateTime(record.updated_at) : '-'}</td>
        <td class="col-status"><span class="status-badge status-${record.status}">${escapeHtml(record.status)}</span></td>
        <td class="col-id">${escapeHtml(record.id)}</td>
        <td class="col-actions">...</td>
    `;
    tbody.appendChild(row);
});
```

## Résumé

Cette implémentation ajoute une visibilité complète des métadonnées temporelles aux enregistrements DNS tout en maintenant :
- ✓ La sécurité (horodatages gérés par le serveur)
- ✓ L'expérience utilisateur (visibilité appropriée des champs)
- ✓ L'intégrité des données (NOW() explicite dans le SQL)
- ✓ La compatibilité ascendante (fonctionne avec les données existantes)
- ✓ Un code propre (modifications minimales)
