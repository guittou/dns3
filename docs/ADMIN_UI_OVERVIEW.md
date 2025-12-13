# Vue d'ensemble de l'interface d'administration

## Disposition de l'interface

L'interface d'administration (`admin.php`) fournit une interface à onglets avec quatre sections principales :

```
┌─────────────────────────────────────────────────────────────────┐
│  DNS3 - Gestion du DNS                                [admin] [✕]│
├─────────────────────────────────────────────────────────────────┤
│  Accueil | DNS | Administration | Services | À propos           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Administration                                                   │
│  ┌────────────┬────────┬─────────────────┬─────┐                │
│  │ Utilisateurs│ Rôles │ Mappings AD/LDAP│ ACL │                │
│  └────────────┴────────┴─────────────────┴─────┘                │
│                                                                   │
│  [Active Tab Content]                                            │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Onglet 1 : Utilisateurs

### Disposition
```
┌─────────────────────────────────────────────────────────────────┐
│ Gestion des Utilisateurs                    [+ Créer un utilisateur]│
├─────────────────────────────────────────────────────────────────┤
│ Filters:                                                         │
│ [Search username...] [Auth method ▼] [Status ▼] [Filtrer] [Réinitialiser]│
├─────────────────────────────────────────────────────────────────┤
│ ID │ Username │ Email │ Auth │ Rôles │ Statut │ Créé │ Actions │
├────┼──────────┼───────┼──────┼───────┼────────┼──────┼─────────┤
│ 1  │ admin    │ admin@│[DB]  │[admin]│[Actif] │ Jan 1│[Modifier]│
│ 2  │ jdoe     │ j@ex  │[AD]  │[user] │[Actif] │ Jan 2│[Modifier]│
│ 3  │ ldap_usr │ l@ex  │[LDAP]│[user] │[Inact] │ Jan 3│[Modifier]│
└────┴──────────┴───────┴──────┴───────┴────────┴──────┴─────────┘
```

### Fonctionnalités
- **Filtrer par :**
  - Nom d'utilisateur (recherche textuelle)
  - Méthode d'authentification (base de données/AD/LDAP)
  - Statut (actif/inactif)
- **Couleurs de badge :**
  - `[admin]` - Badge rouge
  - `[user]` - Badge bleu
  - `[Actif]` - Badge vert
  - `[Inactif]` - Badge gris
  - `[DB]` - Badge turquoise
  - `[AD]` - Badge violet
  - `[LDAP]` - Badge orange

### Modal de création/édition d'utilisateur
```
┌────────────────────────────────────────┐
│ Créer un utilisateur              [×]  │
├────────────────────────────────────────┤
│                                        │
│ Nom d'utilisateur *                   │
│ [_________________________________]   │
│                                        │
│ Email *                                │
│ [_________________________________]   │
│                                        │
│ Méthode d'authentification *           │
│ [Base de données            ▼]        │
│                                        │
│ Mot de passe *                         │
│ [_________________________________]   │
│ Laissez vide pour ne pas modifier     │
│                                        │
│ Statut                                 │
│ [Actif                      ▼]        │
│                                        │
│ Rôles                                  │
│ ☐ admin - Administrator - full access │
│ ☑ user - Regular user - read only     │
│                                        │
├────────────────────────────────────────┤
│                    [Annuler] [Enregistrer]│
└────────────────────────────────────────┘
```

**Note :** Le champ mot de passe est masqué pour les méthodes d'authentification AD/LDAP

## Onglet 2 : Rôles

### Disposition
```
┌─────────────────────────────────────────────────────────────┐
│ Rôles Disponibles                                           │
├─────────────────────────────────────────────────────────────┤
│ ID │ Nom     │ Description                    │ Créé le    │
├────┼─────────┼────────────────────────────────┼────────────┤
│ 1  │ [admin] │ Administrator - full access    │ Jan 1 2024 │
│ 2  │ [user]  │ Regular user - read only       │ Jan 1 2024 │
└────┴─────────┴────────────────────────────────┴────────────┘
```

### Fonctionnalités
- Vue en lecture seule des rôles disponibles
- Affiche le nom du rôle avec badge
- Description et date de création

## Onglet 3 : Mappings AD/LDAP

### Disposition
```
┌─────────────────────────────────────────────────────────────────┐
│ Mappings AD/LDAP                          [+ Créer un mapping]  │
├─────────────────────────────────────────────────────────────────┤
│ ℹ Mappings AD/LDAP permettent d'attribuer automatiquement des  │
│   rôles aux utilisateurs lors de l'authentification basée sur   │
│   leur groupe AD ou DN LDAP.                                    │
│   AD: CN=DNSAdmins,OU=Groups,DC=example,DC=com                 │
│   LDAP: ou=IT,dc=example,dc=com                                │
├─────────────────────────────────────────────────────────────────┤
│ ID │ Source │ DN/Groupe              │ Rôle    │ Créé par │ Notes│ Actions│
├────┼────────┼────────────────────────┼─────────┼──────────┼──────┼────────┤
│ 1  │ [AD]   │ CN=DNSAdmins,OU=...   │ [admin] │ admin    │ DNS  │[Supprimer]│
│ 2  │ [LDAP] │ ou=IT,dc=example...   │ [user]  │ admin    │ IT   │[Supprimer]│
└────┴────────┴────────────────────────┴─────────┴──────────┴──────┴────────┘
```

### Modal de création de mapping
```
┌────────────────────────────────────────┐
│ Créer un mapping AD/LDAP          [×]  │
├────────────────────────────────────────┤
│                                        │
│ Source *                               │
│ [Active Directory           ▼]        │
│                                        │
│ DN/Groupe *                            │
│ [CN=DNSAdmins,OU=Groups,DC=ex...]     │
│ AD: DN complet du groupe               │
│ LDAP: DN ou chemin OU                  │
│                                        │
│ Rôle *                                 │
│ [admin - Administrator      ▼]        │
│                                        │
│ Notes                                  │
│ [________________________________]    │
│ [________________________________]    │
│ [________________________________]    │
│                                        │
├────────────────────────────────────────┤
│                    [Annuler] [Créer]   │
└────────────────────────────────────────┘
```

### Fonctionnalités
- Créer des mappings entre groupes AD/DN LDAP et rôles
- Supprimer des mappings existants
- Ajouter des notes optionnelles pour la documentation
- La validation empêche les mappings dupliqués

## Onglet 4 : ACL

### Disposition
```
┌─────────────────────────────────────────────────────────────┐
│ Liste de Contrôle d'Accès (ACL)                             │
├─────────────────────────────────────────────────────────────┤
│ ℹ ACL permet de définir des permissions granulaires sur les │
│   ressources DNS.                                            │
│   Cette fonctionnalité sera implémentée dans une version    │
│   future.                                                    │
└─────────────────────────────────────────────────────────────┘
```

### Fonctionnalités
- Espace réservé pour la gestion future des ACL
- Réservé pour les permissions granulaires des ressources DNS

## Schéma de couleurs

L'interface utilise un schéma de couleurs cohérent :

```
Primaire:    #3498db (Bleu)    - Boutons principaux, onglets actifs
Secondaire:  #95a5a6 (Gris)    - Boutons secondaires
Succès:      #27ae60 (Vert)    - Statut actif, messages de succès
Danger:      #e74c3c (Rouge)   - Boutons supprimer, badges admin, erreurs
Avertissement: #f39c12 (Orange) - Boutons modifier, badges LDAP
Info:        #3498db (Bleu)    - Badges utilisateur, boîtes d'info
Violet:      #9b59b6           - Badges AD
Turquoise:   #16a085           - Badges base de données

Texte:       #2c3e50 (Foncé)   - Texte principal
Clair:       #ecf0f1           - Bordures de tableau, arrière-plans
```

## Design responsive

L'interface est responsive et s'adapte aux différentes tailles d'écran :

- **Bureau (> 1200px) :** Disposition complète avec toutes les colonnes visibles
- **Tablette (768px - 1200px) :** Les tableaux défilent horizontalement si nécessaire
- **Mobile (< 768px) :** Disposition empilée, formulaires en colonne unique

## Fonctionnalités d'expérience utilisateur

### Notifications
```
┌────────────────────────────────────┐
│ ✓ Utilisateur créé avec succès    │  (Vert, disparition automatique après 3s)
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ ✗ Erreur: Username déjà existant  │  (Rouge, disparition automatique après 3s)
└────────────────────────────────────┘
```

### États de chargement
- Les tableaux affichent "Chargement..." lors de la récupération des données
- Boutons désactivés pendant la soumission du formulaire

### Validation
- Champs requis marqués d'un astérisque (*)
- Validation côté client avant soumission
- Validation côté serveur avec messages d'erreur significatifs
- Retour en temps réel pour les changements de méthode d'authentification

### Accessibilité
- Labels ARIA appropriés
- Support de navigation au clavier
- Gestion du focus dans les modales
- Structure HTML sémantique

## Raccourcis clavier

- **Échap :** Fermer la modale active
- **Entrée :** Soumettre le formulaire actif (dans un champ de saisie)
- **Tab :** Naviguer entre les champs du formulaire

## Intégration API

Toutes les actions de l'interface appellent l'API sécurisée :

```
Action utilisateur            → Appel API
────────────────────────────────────────────────────────
Clic "Créer un utilisateur"  → Ouvrir modale (charger rôles)
Soumettre formulaire utilis. → POST /api/admin_api.php?action=create_user
Clic "Modifier"              → GET /api/admin_api.php?action=get_user&id=X
                              → Ouvrir modale avec données utilisateur
Clic "Filtrer"               → GET /api/admin_api.php?action=list_users&filters...
Basculer vers onglet "Rôles" → GET /api/admin_api.php?action=list_roles
Clic "Créer un mapping"      → Ouvrir modale (charger rôles)
Soumettre formulaire mapping → POST /api/admin_api.php?action=create_mapping
Clic "Supprimer" (mapping)   → Confirmer → POST /api/admin_api.php?action=delete_mapping&id=X
```

## Compatibilité des navigateurs

Testé et compatible avec :
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

Utilise des fonctionnalités JavaScript modernes (ES6+) :
- Fonctions fléchées
- Async/await
- Fetch API
- Littéraux de gabarit
- Déstructuration

## Performance

- Chargement différé des données (charge uniquement quand l'onglet est actif)
- Mises à jour DOM efficaces
- Requêtes HTTP minimales
- Filtrage côté client pour recherche rapide
- Données de rôle en cache pour éviter les appels API redondants

## Indicateurs de sécurité

L'interface fournit des indicateurs visuels de sécurité :

- 🔒 Accès réservé aux admins appliqué côté serveur
- 🔑 Les champs de mot de passe utilisent type="password" (saisie masquée)
- ⚠️ Dialogue de confirmation avant suppression
- 📝 Piste d'audit affichée (créé par, créé le)
- 🚫 Messages d'erreur clairs sans exposition de données sensibles
