# Implémentation de la Génération de Fichiers de Zone

## Vue d'ensemble
Cette implémentation ajoute la capacité de génération de fichiers de zone avec support pour :
- Champ répertoire pour les fichiers de zone (exposé uniquement dans le modal)
- Génération de fichiers de zone complets avec directives $INCLUDE
- Enregistrements DNS formatés en syntaxe BIND
- Suppression de la colonne "# Includes" du tableau de liste des zones

## Modifications Effectuées

### 1. Schéma de Base de Données
> **Note** : Les fichiers de migration ont été supprimés. Le schéma complet est maintenant disponible dans `database.sql`.

- Ajout de la colonne `directory` VARCHAR(255) NULL à la table `zone_files`
- Ajout d'un index sur `directory` pour la performance

### 2. Modifications du Modèle Backend
**Fichier** : `includes/models/ZoneFile.php`

#### Méthodes Modifiées :
- `create()` : Accepte et stocke maintenant le champ `directory`
- `update()` : Accepte et met à jour maintenant le champ `directory`
- `getById()` : S'assure que `directory` est inclus dans les résultats

#### Nouvelles Méthodes :
- `generateZoneFile($zoneId)` : Génère le contenu complet du fichier de zone avec :
  - Contenu propre de la zone (depuis `zone_files.content`)
  - Directives $INCLUDE pour les includes directs
  - Enregistrements DNS formatés en syntaxe BIND
  
- `getDnsRecordsByZone($zoneId)` : Récupère tous les enregistrements DNS actifs pour une zone
  
- `formatDnsRecordBind($record)` : Formate un enregistrement DNS en syntaxe de fichier de zone BIND
  
- `getRecordValue($record)` : Extrait la valeur correcte pour chaque type d'enregistrement

#### Logique de la Directive $INCLUDE :
```
Si directory est défini :
  $INCLUDE "directory/filename"
  
Si directory est NULL :
  $INCLUDE "filename"  (ou "name" si filename est vide)
```

### 3. Modifications de l'API
**Fichier** : `api/zone_api.php`

#### Nouveau Point de Terminaison :
```
GET /api/zone_api.php?action=generate_zone_file&id={zone_id}
```

**Réponse** :
```json
{
  "success": true,
  "content": "... contenu du fichier de zone généré ...",
  "filename": "example.com.zone"
}
```

### 4. Modifications de l'Interface Frontend
**Fichier** : `zone-files.php`

#### Modifications de la Vue Tableau :
- Suppression de la colonne "# Includes" du tableau de liste des zones
- Mise à jour du colspan de 8 à 7 dans les états de chargement/erreur

#### Modifications du Modal :
- Ajout du champ "Répertoire" dans l'onglet Détails :
  ```html
  <input type="text" id="zoneDirectory" class="form-control" placeholder="Exemple: /etc/bind/zones">
  ```
- Ajout du bouton "Générer le fichier de zone" dans l'onglet Éditeur
- Le champ répertoire est uniquement visible dans le modal d'édition, PAS dans la vue liste du tableau

### 5. Modifications JavaScript Frontend
**Fichier** : `assets/js/zone-files.js`

#### Fonctions Modifiées :
- `renderZonesTable()` : Suppression de l'affichage de la colonne includes_count
- `renderErrorState()` : Mise à jour du colspan de 8 à 7
- `openZoneModal()` : Charge et remplit maintenant le champ `zoneDirectory`
- `setupChangeDetection()` : Ajout de `zoneDirectory` au suivi des modifications
- `saveZone()` : Sauvegarde maintenant la valeur du champ `directory`

#### Nouvelle Fonction :
- `generateZoneFileContent()` : Appelle l'API pour générer le fichier de zone et :
  - Propose de télécharger le fichier généré
  - Ou l'affiche dans l'éditeur pour prévisualisation

## Utilisation

### Définir le Champ Répertoire
1. Ouvrir une zone en cliquant dessus dans le tableau
2. Dans le modal, aller à l'onglet "Détails"
3. Entrer le chemin du répertoire dans le champ "Répertoire" (ex : `/etc/bind/zones`)
4. Cliquer sur "Enregistrer" pour sauvegarder

### Générer un Fichier de Zone
1. Ouvrir une zone en cliquant dessus dans le tableau
2. Aller à l'onglet "Éditeur"
3. Cliquer sur le bouton "Générer le fichier de zone"
4. Choisir soit :
   - Télécharger le fichier
   - Le prévisualiser dans l'éditeur

### Format du Fichier de Zone Généré

Le fichier de zone généré contient (dans l'ordre) :

1. **Directive $TTL** (si `default_ttl` est défini pour la zone maître) :
   ```
   $TTL 86400
   ```
2. **Contenu propre de la zone** (depuis le champ `zone_files.content`)
3. **Directives $INCLUDE** pour chaque include direct :
   ```
   $INCLUDE "/etc/bind/zones/common.conf"
   $INCLUDE "special-records.conf"
   ```
4. **Enregistrements DNS** en syntaxe BIND :
   ```
   ; DNS Records
   www.example.com        3600 IN A      192.168.1.10
   mail.example.com       3600 IN A      192.168.1.20
   example.com            3600 IN MX     10 mail.example.com
   _service._tcp          3600 IN SRV    10 5060 sip.example.com
   ```

## Configuration SOA et TTL

Lors de la création ou de l'édition d'une zone maître, vous pouvez configurer les timers SOA et le TTL par défaut :

| Champ | Défaut | Description |
|-------|---------|-------------|
| `default_ttl` | 86400 | TTL par défaut en secondes (utilisé pour la directive $TTL) |
| `soa_rname` | (aucun) | Email de contact pour la zone (ex : hostmaster@example.com) |
| `soa_refresh` | 10800 | Fréquence à laquelle les serveurs secondaires doivent vérifier les mises à jour (3 heures) |
| `soa_retry` | 900 | Intervalle de réessai si le refresh échoue (15 minutes) |
| `soa_expire` | 604800 | Temps après lequel les données de zone ne sont plus autoritaires (7 jours) |
| `soa_minimum` | 3600 | TTL de mise en cache négative (1 heure) |

### Comportement du Numéro de Série SOA

Le numéro de série SOA est auto-généré par l'application au format YYYYMMDDnn. Lorsque la zone est modifiée, le numéro de série est automatiquement incrémenté. L'interface affiche le numéro de série actuel mais ne permet pas l'édition directe pour éviter les conflits.

### Formatage du RNAME

Lors de la génération du fichier de zone, le champ RNAME (contact) est normalisé :
- `@` est remplacé par `.` (format DNS)
- Un point final est ajouté pour le FQDN

Exemple : `admin@example.com` devient `admin.example.com.`

## Exemples de Format d'Enregistrements BIND

- **Enregistrement A** : `name TTL IN A ipv4_address`
- **Enregistrement AAAA** : `name TTL IN AAAA ipv6_address`
- **Enregistrement CNAME** : `name TTL IN CNAME target`
- **Enregistrement MX** : `name TTL IN MX priority target`
- **Enregistrement TXT** : `name TTL IN TXT "text content"`
- **Enregistrement NS** : `name TTL IN NS nameserver`
- **Enregistrement PTR** : `name TTL IN PTR hostname`
- **Enregistrement SRV** : `name TTL IN SRV priority weight port target`
- **Enregistrement SOA** : `name TTL IN SOA mname rname (serial refresh retry expire minimum)`

## Compatibilité

- Compatible PHP 7.4+
- Utilise la syntaxe standard des fichiers de zone BIND
- Les includes ne sont PAS inlinés (utilise les directives $INCLUDE)
- Enregistrements DNS actifs uniquement (status = 'active')

## Checklist de Test

- [ ] Créer/mettre à jour des zones avec le champ répertoire
- [ ] Vérifier que le champ répertoire s'affiche dans le modal mais pas dans le tableau
- [ ] Créer un nouveau maître avec TTL et timers SOA personnalisés
- [ ] Vérifier que le fieldset de configuration SOA est visible uniquement pour les zones maîtres
- [ ] Créer des includes et les assigner à une zone parente
- [ ] Ajouter des enregistrements DNS à une zone
- [ ] Cliquer sur le bouton "Générer le fichier de zone"
- [ ] Vérifier que le fichier généré contient :
  - [ ] Directive $TTL avec le default_ttl configuré
  - [ ] Contenu de la zone
  - [ ] Directives $INCLUDE avec les chemins corrects
  - [ ] Enregistrements DNS en format BIND
- [ ] Tester avec des zones sans répertoire défini
- [ ] Tester avec des zones avec répertoire défini
- [ ] Vérifier que la fonctionnalité de téléchargement fonctionne
- [ ] Vérifier que la prévisualisation dans l'éditeur fonctionne
- [ ] Tester le bouton "Modifier domaine" (activé uniquement quand un domaine est sélectionné)
- [ ] Exécuter `named-checkzone` sur le fichier généré pour valider les timers SOA

## Notes

- Les includes sont référencés par leur chemin (non inlinés)
- Seuls les enregistrements DNS actifs sont inclus dans le fichier généré
- Le champ répertoire est optionnel (NULL est autorisé)
- La colonne "# Includes" a été supprimée de la vue tableau comme demandé
- Toutes les modifications maintiennent la rétrocompatibilité avec les données existantes

## Validation des Noms de Zone

L'application utilise des règles de validation différentes pour les noms de zone selon le type de zone :

### Zones Maîtres (Format FQDN)

Les zones maîtres acceptent des noms de domaine pleinement qualifiés (FQDN) valides :

| Règle | Description |
|------|-------------|
| Format | `label.label.label` (ex : `example.com`, `sub.example.com`) |
| Point final | Optionnel (ex : `example.com.` est également valide) |
| Longueur totale | Maximum 253 caractères (point final exclu) |
| Longueur de label | Maximum 63 caractères par label |
| Caractères autorisés | Lettres minuscules (a-z), chiffres (0-9), traits d'union (-) |
| Restrictions de label | Ne peut pas commencer ou finir par un trait d'union |
| Casse | Automatiquement normalisé en minuscules |

**Exemples de noms de zones maîtres valides :**
- `example.com`
- `sub.domain.example.org`
- `test-domain.net`
- `example.com.` (avec point final)

**Exemples de noms de zones maîtres invalides :**
- `-example.com` (commence par un trait d'union)
- `example-.com` (finit par un trait d'union)
- `test_domain.com` (underscore non autorisé)
- `example..com` (label vide)

### Zones Include (Format Identifiant Simple)

Les zones include utilisent une validation plus stricte qui n'autorise que des identifiants simples :

| Règle | Description |
|------|-------------|
| Format | Chaîne alphanumérique simple (ex : `incm1`, `common1`) |
| Caractères autorisés | Lettres minuscules (a-z), chiffres (0-9) |
| Caractères spéciaux | Non autorisés (pas de points, traits d'union, underscores ou majuscules) |

**Exemples de noms de zones include valides :**
- `inc1`
- `common`
- `zone123`

**Exemples de noms de zones include invalides :**
- `Inc1` (majuscules non autorisées)
- `inc-1` (trait d'union non autorisé)
- `common.records` (point non autorisé)
- `zone_include` (underscore non autorisé)

### Implémentation de la Validation

- **Frontend** : Utilise `validateMasterZoneName()` pour les zones maîtres et `validateZoneName()` pour les includes
- **Backend** : Utilise `DnsValidator::validateName()` pour les zones maîtres et un pattern regex pour les includes
- Les validations frontend et backend sont appliquées pour assurer la cohérence
