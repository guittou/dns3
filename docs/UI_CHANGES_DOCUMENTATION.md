# Documentation des Modifications UI - Champs Spécifiques par Type

## Vue d'ensemble
Ce document décrit les modifications visuelles et fonctionnelles de l'interface de gestion DNS.

## Avant (Ancienne Implémentation)
L'ancienne implémentation utilisait un seul champ générique "valeur" pour tous les types d'enregistrements DNS :

```
[ Type d'enregistrement: A ▼ ]
[ Nom: example.com ]
[ Valeur: 192.168.1.1 ]  ← Champ unique pour tous les types
[ TTL: 3600 ]
[ Priorité: 10 ]  ← Utilisé uniquement pour MX/SRV
```

**Problèmes :**
- Même champ utilisé pour les adresses IP, noms d'hôte et texte
- Pas d'indices de validation spécifiques au type
- Champ priorité affiché pour tous les types (confus)
- Support de 9 types d'enregistrements différents (MX, SRV, NS, SOA non entièrement fonctionnels)

## Après (Nouvelle Implémentation)
La nouvelle implémentation utilise des champs dédiés qui s'affichent/se masquent selon le type d'enregistrement :

### Enregistrement A (IPv4)
```
[ Type d'enregistrement: A ▼ ]
[ Nom: example.com ]
[ Adresse IPv4: 192.168.1.1 ]  ← Champ dédié avec validation
  Exemple: 192.168.1.1
[ TTL: 3600 ]
```

### Enregistrement AAAA (IPv6)
```
[ Type d'enregistrement: AAAA ▼ ]
[ Nom: example.com ]
[ Adresse IPv6: 2001:db8::1 ]  ← Champ dédié avec validation
  Exemple: 2001:db8::1
[ TTL: 3600 ]
```

### Enregistrement CNAME
```
[ Type d'enregistrement: CNAME ▼ ]
[ Nom: www.example.com ]
[ Cible CNAME: example.com ]  ← Champ dédié, pas d'IP autorisée
  Nom d'hôte cible (pas d'adresse IP)
[ TTL: 3600 ]
```

### Enregistrement PTR
```
[ Type d'enregistrement: PTR ▼ ]
[ Nom: example.com ]
[ Nom PTR (inversé): 1.1.168.192.in-addr.arpa ]  ← Nécessite le nom DNS inversé
  Nom DNS inversé requis
[ TTL: 3600 ]
```

### Enregistrement TXT
```
[ Type d'enregistrement: TXT ▼ ]
[ Nom: example.com ]
[ Texte: v=spf1 include:_spf.example.com ~all ]  ← Zone de texte multiligne
  Exemple: v=spf1 include:_spf.example.com ~all
[ TTL: 3600 ]
```

## Modifications Clés

### 1. Sélection de Type
**Avant :** 9 types (A, AAAA, CNAME, MX, TXT, NS, SOA, PTR, SRV)
**Après :** 5 types (A, AAAA, CNAME, PTR, TXT)

Le menu déroulant des types n'affiche maintenant que les types supportés.

### 2. Visibilité Dynamique des Champs
- Un SEUL champ dédié est visible à la fois
- Le champ s'affiche/se masque automatiquement lors du changement de type d'enregistrement
- Chaque champ a un texte d'espace réservé approprié et des indices de validation
- L'indicateur requis (*) est affiché sur le champ actif

### 3. Validation Spécifique aux Champs
- **Enregistrement A** : Valide le format IPv4 (ex : 192.168.1.1)
- **Enregistrement AAAA** : Valide le format IPv6 (ex : 2001:db8::1)
- **Enregistrement CNAME** : Valide le format nom d'hôte, rejette les adresses IP
- **Enregistrement PTR** : Valide le format nom d'hôte, attend un nom DNS inversé
- **Enregistrement TXT** : Accepte tout texte non vide

### 4. Champs Supprimés
- **Champ priorité** : Supprimé (n'était utilisé que pour MX/SRV qui ne sont plus supportés)
- **Champ valeur** : Remplacé par des champs spécifiques au type

### 5. Expérience Utilisateur Améliorée
- Étiquetage clair avec des noms spécifiques au type
- Exemples et indices intégrés sous chaque champ
- Mise en évidence visuelle du champ actif (bordure verte)
- Meilleure validation de formulaire avec messages d'erreur spécifiques

## Correspondance des Champs de Formulaire

| Type d'Enreg. | Nom du Champ | Colonne DB | Élément HTML | Validation |
|---------------|-------------|------------|--------------|------------|
| A | Adresse IPv4 | `address_ipv4` | `<input type="text">` | Format IPv4 |
| AAAA | Adresse IPv6 | `address_ipv6` | `<input type="text">` | Format IPv6 |
| CNAME | Cible CNAME | `cname_target` | `<input type="text">` | Nom d'hôte (pas d'IP) |
| PTR | Nom PTR | `ptrdname` | `<input type="text">` | Nom d'hôte |
| TXT | Texte | `txt` | `<textarea>` | Non vide |

## Comportement JavaScript

### Logique de Visibilité des Champs
```javascript
function updateFieldVisibility() {
    // Masquer tous les groupes de champs dédiés
    ipv4Group.style.display = 'none';
    ipv6Group.style.display = 'none';
    cnameGroup.style.display = 'none';
    ptrGroup.style.display = 'none';
    txtGroup.style.display = 'none';
    
    // Afficher uniquement le champ pertinent selon le type sélectionné
    switch(recordType) {
        case 'A':
            ipv4Group.style.display = 'block';
            ipv4Input.setAttribute('required', 'required');
            break;
        // ... autres types
    }
}
```

### Construction de la Charge Utile
```javascript
// Construire la charge utile avec à la fois le champ dédié ET l'alias value
const data = {
    record_type: 'A',
    name: 'example.com',
    address_ipv4: '192.168.1.1',  // Champ dédié
    value: '192.168.1.1',         // Alias pour rétrocompatibilité
    ttl: 3600
};
```

## Affichage Table

La table des enregistrements continue d'afficher une colonne "Valeur", qui est maintenant calculée à partir des champs dédiés par le backend :

```
| ID | Type  | Nom           | Valeur        | TTL  | ... |
|----|-------|---------------|---------------|------|-----|
| 1  | A     | example.com   | 192.168.1.1   | 3600 | ... |
| 2  | AAAA  | example.com   | 2001:db8::1   | 3600 | ... |
| 3  | CNAME | www.ex...com  | example.com   | 3600 | ... |
```

Le champ `value` dans la réponse API est automatiquement calculé à partir de la colonne dédiée appropriée, assurant la rétrocompatibilité avec le code de rendu de table existant.

## Messages d'Erreur

### Validation Côté Client
- "L'adresse doit être une adresse IPv4 valide pour le type A"
- "L'adresse doit être une adresse IPv6 valide pour le type AAAA"
- "La cible CNAME ne peut pas être une adresse IP (doit être un nom d'hôte)"
- "Le nom PTR doit être un nom d'hôte valide (nom DNS inversé requis)"
- "Le contenu du champ TXT ne peut pas être vide"

### Validation Côté Serveur
- "Type d'enregistrement invalide. Seuls A, AAAA, CNAME, PTR et TXT sont supportés"
- "L'adresse doit être une adresse IPv4 valide pour le type A"
- "La cible CNAME ne peut pas être une adresse IP (doit être un nom d'hôte)"
- "Champ requis manquant : address_ipv4 (ou value) pour le type A"

## Améliorations d'Accessibilité

1. **Étiquettes Claires** : Chaque champ a une étiquette descriptive spécifique au type d'enregistrement
2. **Indicateurs Requis** : Les astérisques (*) indiquent les champs requis
3. **Texte d'Espace Réservé** : Les exemples montrent le format attendu
4. **Texte d'Aide** : Petit texte sous les champs fournit des conseils supplémentaires
5. **Retour Visuel** : Le champ actif est mis en évidence avec une bordure verte

## Rétrocompatibilité

L'implémentation maintient la rétrocompatibilité de plusieurs façons :

1. **L'API accepte `value` comme alias** : L'ancien code peut toujours envoyer `value` au lieu du champ dédié
2. **L'API retourne le champ `value`** : La réponse inclut la `value` calculée pour les anciens clients
3. **La base de données garde la colonne `value`** : Possibilité de rollback si nécessaire
4. **Migration graduelle** : Les enregistrements existants continuent de fonctionner

## Impact de la Migration

Lors de la mise à niveau :
1. Les enregistrements existants sont automatiquement migrés (value → colonne dédiée)
2. L'UI affiche immédiatement les champs dédiés pour les nouveaux/enregistrements modifiés
3. L'API continue d'accepter les deux formats
4. Aucun changement cassant pour les intégrations existantes
