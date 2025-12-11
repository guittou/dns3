# fix(dns): robust setDomainForZone — use master id or domain fallback for populateZoneComboboxForDomain

## Contexte

Sur l'onglet DNS, cliquer sur une ligne de la table devait sélectionner le domaine et le fichier de zone correspondant et rendre la combobox de fichier de zone cliquable avec la liste correcte. Actuellement :

- `populateZoneComboboxForDomain(zone.id)` appelé avec l'id d'un fichier de type "include" ne remplit rien (`CURRENT_ZONE_LIST` reste vide)
- L'API `list_zone_files` par nom de domaine retourne bien la liste (ex. 301 éléments) mais la fonction appelée avec l'ID d'include ne la récupère pas
- `setDomainForZone` finit par lire `.length` sur des variables non définies et lance `TypeError`, laissant la combobox dans un état non cliquable ou montrant une liste incorrecte

## Changements appliqués

Cette PR remplace complètement la fonction `setDomainForZone` dans `assets/js/dns-records.js` par une version robuste qui :

### 1. Initialisation des caches

- Attend l'initialisation des caches/combobox (`ensureZonesCache` / `ensureZoneFilesInit` si présent)
- Protège toutes les opérations contre les états non initialisés

### 2. Normalisation des tableaux globaux

- Normalise `window.ALL_ZONES` et `window.CURRENT_ZONE_LIST` en tableaux avant toute lecture
- Protège tous les accès à `.length` par des vérifications `Array.isArray`
- Élimine les `TypeError` causés par les accès à `.length` sur des valeurs `undefined`

### 3. Résolution intelligente du master ID

Calcule l'argument à passer à `populateZoneComboboxForDomain` :

- **Si `zone.file_type === 'master'`** → utilise `zone.id`
- **Sinon (include)** → tente dans l'ordre :
  1. `zone.master_id` (champ direct si disponible)
  2. `zone.parent_zone_id` (identifiant du parent)
  3. Remontée de la chaîne `parent_id` dans `ALL_ZONES` pour trouver le master
  4. Recherche du master par `parent_domain` correspondant dans `ALL_ZONES`

### 4. Stratégies de fallback multiples

Si `populateZoneComboboxForDomain(masterId)` ne produit rien :

1. **Fallback 1** : Appelle `zoneApiCall('list_zone_files', { domain: domainName })` pour remplir `CURRENT_ZONE_LIST` depuis la réponse serveur
2. **Fallback 2** : En dernier recours, essaie `zoneApiCall('list_zone_files', { domain_id: zone.id })` (certaines installations acceptent `domain_id`)

### 5. Garanties de cohérence

- Met à jour les inputs cachés (`#dns-zone-file-id` / `#dns-zone-id`)
- Met à jour les variables globales (`selectedDomainId` / `selectedZoneId`)
- Affiche `#dns-zone-input` en dernier
- Active la combobox (`setDnsZoneComboboxEnabled(true)`)
- **Ajoute le zone courant dans `CURRENT_ZONE_LIST` s'il est manquant** pour permettre la sélection visuelle immédiate

### 6. Logging amélioré

- Ajoute des logs `console.warn` / `console.info` / `console.debug` sur tous les chemins de fallback
- Facilite le debug en production et le support utilisateur

## Tests / QA

### Prérequis

1. **Rebuild assets** (si pipeline de build existe) :
   ```bash
   # Exemple : npm run build ou make assets
   ```

2. **Hard-refresh navigateur** :
   - Chrome/Firefox : `Ctrl+Shift+R` (Windows/Linux) ou `Cmd+Shift+R` (Mac)
   - Ou vider le cache navigateur

### Scénarios de test

#### Test 1 : Onglet DNS - Sélection d'un fichier master

1. Accéder à l'onglet DNS
2. Cliquer sur une ligne de la table avec un fichier de type **master**
3. **Résultat attendu** :
   - Le domaine est sélectionné et affiché dans `#dns-domain-input`
   - `#dns-zone-input` affiche le label du fichier au format `"name (file_type)"`
   - La combobox de zone est cliquable et activée
   - `CURRENT_ZONE_LIST` contient les fichiers attendus (master + includes associés)
   - Pas d'erreur dans la console

#### Test 2 : Onglet DNS - Sélection d'un fichier include

1. Accéder à l'onglet DNS
2. Cliquer sur une ligne de la table avec un fichier de type **include**
3. **Résultat attendu** :
   - Le domaine parent est sélectionné et affiché dans `#dns-domain-input`
   - `#dns-zone-input` affiche le label de l'include au format `"name (file_type)"`
   - La combobox de zone est cliquable et activée
   - `CURRENT_ZONE_LIST` contient le fichier sélectionné ET tous les fichiers de la même arborescence (master + autres includes)
   - Pas d'erreur dans la console
   - Des logs informatifs apparaissent dans la console (normal)

#### Test 3 : Onglet DNS - Combobox activable après sélection

1. Accéder à l'onglet DNS
2. Cliquer sur une ligne de la table (master ou include)
3. Cliquer sur la combobox de zone (`#dns-zone-input`)
4. **Résultat attendu** :
   - La liste déroulante s'ouvre
   - La liste contient les fichiers de zone appropriés
   - Le fichier sélectionné est visible dans la liste
   - La recherche/filtrage fonctionne dans la combobox

#### Test 4 : Onglet DNS - État initial sans sélection

1. Accéder à l'onglet DNS (sans cliquer sur une ligne)
2. **Résultat attendu** :
   - La combobox de zone est désactivée (grisée)
   - Le placeholder indique "Sélectionnez d'abord un domaine"
   - Le bouton "Créer" est désactivé

#### Test 5 : Onglet Zones - Pas de régression

1. Accéder à l'onglet Zones
2. Sélectionner un domaine dans la liste
3. Vérifier que la combobox de fichier de zone se remplit correctement
4. Sélectionner un fichier de zone
5. **Résultat attendu** :
   - Comportement identique à avant la PR
   - Pas d'erreur dans la console
   - Les fonctionnalités de l'onglet Zones ne sont pas impactées

### Vérification console (développeur)

1. Ouvrir la console développeur (F12)
2. Effectuer les tests ci-dessus
3. **Vérifier** :
   - Aucune erreur JavaScript (`TypeError`, `ReferenceError`, etc.)
   - Des logs `[setDomainForZone]` apparaissent (normal)
   - Les logs indiquent clairement quel chemin a été pris (master direct, fallback 1, fallback 2, etc.)

## Captures d'écran de référence

Les captures fournies montrent le comportement problématique sur DNS (combobox inactive ou liste incorrecte) :

![DNS Tab Issue](https://user-images.githubusercontent.com/placeholder-dns-issue.png)
![Zones Tab Reference](https://user-images.githubusercontent.com/placeholder-zones-ref.png)

> **Note** : Après application de cette PR, le comportement sur l'onglet DNS devrait correspondre au comportement correct de l'onglet Zones.

## Impact et compatibilité

- **Fichiers modifiés** : `assets/js/dns-records.js` (fonction `setDomainForZone` uniquement)
- **Pas de changement d'API** : Utilise les endpoints existants
- **Rétrocompatible** : Les anciens appels à `setDomainForZone` continuent de fonctionner
- **Pas d'impact sur l'onglet Zones** : Les fonctions partagées ne sont pas modifiées
- **Logs ajoutés** : Peuvent être désactivés en changeant `console.info` en `console.debug` si nécessaire

## Détails techniques

### Avant

```javascript
async function setDomainForZone(zoneId) {
    // Appel simple sans gestion des includes
    await populateZoneComboboxForDomain(zone.id); // ❌ Ne fonctionne pas avec include
    // Pas de fallback
    // Pas de protection contre TypeError
}
```

### Après

```javascript
async function setDomainForZone(zoneId) {
    // 1. Init caches
    await ensureZonesCache();
    
    // 2. Normalisation arrays (protège contre TypeError)
    if (!Array.isArray(window.ALL_ZONES)) window.ALL_ZONES = [];
    
    // 3. Résolution master ID pour includes
    let masterId = zone.file_type === 'master' ? zone.id : 
                   (zone.master_id || findMasterInParentChain(zone));
    
    // 4. Appel avec bon master ID
    await populateZoneComboboxForDomain(masterId); // ✅ Fonctionne avec master et include
    
    // 5. Fallbacks si nécessaire
    if (CURRENT_ZONE_LIST.length === 0) {
        await fallbackByDomain();
    }
    
    // 6. Garantie: zone courant dans liste
    if (!CURRENT_ZONE_LIST.includes(zone)) {
        CURRENT_ZONE_LIST.push(zone);
    }
}
```

## Références

- Issue originale : (lien à ajouter)
- Documentation de l'API `list_zone_files` : (voir `api/zone_api.php`)
- PR précédente sur combobox : #305

## Checklist de merge

- [x] Code implémenté et testé localement
- [x] Pas d'erreur de syntaxe JavaScript
- [x] Documentation ajoutée (cette PR description)
- [ ] Tests QA effectués (à faire après création de la PR)
- [ ] Revue de code effectuée
- [ ] Prêt pour merge

---

**Note pour les reviewers** : Vérifier particulièrement les scénarios avec fichiers de type "include" qui étaient auparavant cassés.
