# Plan de Test pour last_seen DNS et Comportement Dynamique des Formulaires

## Résumé des Modifications

Cette PR implémente les changements suivants dans le système de gestion DNS :

1. **Suppression des mises à jour automatiques de last_seen depuis l'UI/API** : Le champ `last_seen` n'est plus mis à jour lors de la consultation des enregistrements via l'interface web ou l'API. La méthode `markSeen()` reste dans le modèle pour une utilisation future par des scripts externes.

2. **Visibilité dynamique des champs de formulaire** : Le champ priorité n'est maintenant affiché que pour les types d'enregistrements MX et SRV, avec des champs s'affichant/se masquant dynamiquement en fonction du type d'enregistrement sélectionné.

3. **Amélioration de la sécurité** : L'API ignore explicitement toute valeur `last_seen` fournie par le client lors des opérations de création/mise à jour.

4. **Charge utile optimisée** : Le JavaScript n'inclut que les champs pertinents dans les requêtes API (par exemple, la priorité n'est envoyée que pour les enregistrements MX/SRV).

## Fichiers Modifiés

- `api/dns_api.php` - Suppression de l'appel markSeen() de l'action GET
- `assets/js/dns-records.js` - Ajout du comportement dynamique des formulaires et optimisation de la construction de la charge utile
- `dns-management.php` - Ajout du wrapper id="record-priority-group" pour le champ priorité

## Cas de Test

### 1. Créer un Enregistrement via l'UI - last_seen Reste NULL

**Étapes de Test :**
1. Se connecter en tant qu'utilisateur administrateur
2. Naviguer vers la page de Gestion DNS
3. Cliquer sur le bouton "Créer un Enregistrement"
4. Remplir tous les champs requis (record_type, name, value)
5. Soumettre le formulaire
6. Interroger la base de données : `SELECT last_seen FROM dns_records WHERE id = [new_record_id]`

**Résultat Attendu :**
- L'enregistrement est créé avec succès
- Le champ `last_seen` dans la base de données est NULL

**Vérification :**
```sql
SELECT id, name, last_seen FROM dns_records WHERE id = [new_record_id];
-- last_seen devrait être NULL
```

### 2. Voir un Enregistrement via l'UI - last_seen Reste Inchangé

**Étapes de Test :**
1. Noter la valeur actuelle de `last_seen` pour un enregistrement (ou NULL si non défini)
2. Cliquer sur le bouton "Modifier" pour cet enregistrement afin de le voir
3. Interroger à nouveau la base de données pour vérifier `last_seen`

**Résultat Attendu :**
- Les détails de l'enregistrement sont affichés correctement
- La valeur `last_seen` dans la base de données reste inchangée (reste NULL ou conserve l'horodatage original)

**Vérification :**
```sql
-- Avant la visualisation
SELECT id, name, last_seen FROM dns_records WHERE id = [record_id];
-- [Voir l'enregistrement dans l'UI]
-- Après la visualisation
SELECT id, name, last_seen FROM dns_records WHERE id = [record_id];
-- Les valeurs devraient être identiques
```

### 3. Modifier un Enregistrement via l'UI - last_seen Reste Inchangé

**Étapes de Test :**
1. Noter la valeur actuelle de `last_seen` pour un enregistrement
2. Cliquer sur le bouton "Modifier"
3. Modifier certains champs (par exemple, TTL ou commentaire)
4. Soumettre le formulaire
5. Interroger la base de données pour vérifier que `last_seen` n'a pas changé

**Résultat Attendu :**
- L'enregistrement est mis à jour avec succès avec les nouvelles valeurs
- Le champ `last_seen` reste inchangé
- Le champ `updated_at` est mis à jour (c'est le comportement attendu)

**Vérification :**
```sql
SELECT id, name, last_seen, updated_at FROM dns_records WHERE id = [record_id];
-- last_seen devrait rester inchangé, updated_at devrait être l'horodatage actuel
```

### 4. Créer un Enregistrement MX - Priorité Visible et Persistée

**Étapes de Test :**
1. Cliquer sur "Créer un Enregistrement"
2. Sélectionner "MX" dans le menu déroulant du type d'enregistrement
3. Vérifier que le champ priorité est visible
4. Remplir les champs requis incluant la priorité (par exemple, 10)
5. Soumettre le formulaire
6. Interroger la base de données pour vérifier que la priorité a été sauvegardée

**Résultat Attendu :**
- Le champ priorité est visible lorsque MX est sélectionné
- La valeur de priorité est sauvegardée dans la base de données
- La requête API inclut la priorité dans la charge utile

**Vérification :**
```sql
SELECT id, record_type, priority FROM dns_records WHERE id = [new_mx_record_id];
-- priority devrait avoir la valeur saisie (par exemple, 10)
```

### 5. Créer un Enregistrement SRV - Priorité Visible et Persistée

**Étapes de Test :**
1. Cliquer sur "Créer un Enregistrement"
2. Sélectionner "SRV" dans le menu déroulant du type d'enregistrement
3. Vérifier que le champ priorité est visible
4. Remplir les champs requis incluant la priorité
5. Soumettre le formulaire

**Résultat Attendu :**
- Le champ priorité est visible lorsque SRV est sélectionné
- La valeur de priorité est sauvegardée correctement

### 6. Créer un Enregistrement A - Priorité Masquée et Non Envoyée

**Étapes de Test :**
1. Cliquer sur "Créer un Enregistrement"
2. Sélectionner "A" dans le menu déroulant du type d'enregistrement
3. Vérifier que le champ priorité est masqué
4. Remplir les champs requis
5. Ouvrir les outils de développement du navigateur, aller dans l'onglet Réseau
6. Soumettre le formulaire
7. Inspecter la charge utile de la requête POST

**Résultat Attendu :**
- Le champ priorité n'est pas visible dans le formulaire
- La charge utile de la requête POST n'inclut PAS le champ "priority"
- L'enregistrement est créé avec succès sans priorité

**Vérification :**
- Vérifier l'onglet Réseau : la charge utile POST ne devrait pas contenir la clé `priority`
- Requête base de données : `SELECT id, record_type, priority FROM dns_records WHERE id = [new_a_record_id]`
- priority devrait être NULL

### 7. Créer un Enregistrement CNAME - Priorité Masquée et Non Envoyée

**Étapes de Test :**
1. Cliquer sur "Créer un Enregistrement"
2. Sélectionner "CNAME" dans le menu déroulant du type d'enregistrement
3. Vérifier que le champ priorité est masqué
4. Soumettre avec les champs requis

**Résultat Attendu :**
- Le champ priorité est masqué
- La priorité n'est pas incluse dans la charge utile
- L'enregistrement est créé avec succès

### 8. Basculement Dynamique des Champs - Changer le Type d'Enregistrement

**Étapes de Test :**
1. Cliquer sur "Créer un Enregistrement"
2. Sélectionner "A" - vérifier que la priorité est masquée
3. Changer pour "MX" - vérifier que la priorité apparaît
4. Changer pour "CNAME" - vérifier que la priorité disparaît
5. Changer pour "SRV" - vérifier que la priorité apparaît
6. Revenir à "A" - vérifier que la priorité disparaît

**Résultat Attendu :**
- La visibilité du champ priorité bascule correctement selon le type d'enregistrement
- Aucune erreur dans la console JavaScript
- Transition fluide (pas de scintillement)

### 9. Test de Sécurité - Tentative d'Envoi de last_seen depuis le Client

**Étapes de Test :**
1. Ouvrir les outils de développement du navigateur
2. Dans l'onglet Console, intercepter la soumission du formulaire ou modifier la requête
3. Essayer d'inclure `last_seen` dans la charge utile :
   ```javascript
   // Modifier la requête pour inclure last_seen
   const data = {
       record_type: 'A',
       name: 'test.example.com',
       value: '192.168.1.1',
       ttl: 3600,
       last_seen: '2025-10-20 12:00:00'  // Injection malveillante
   };
   ```
4. Soumettre la requête modifiée
5. Vérifier la base de données pour confirmer que last_seen n'a PAS été défini

**Résultat Attendu :**
- Le serveur ignore la valeur `last_seen` fournie par le client
- `last_seen` dans la base de données reste NULL (pour les nouveaux enregistrements)
- Aucune erreur serveur
- L'API retourne un succès

**Vérification :**
```sql
SELECT id, name, last_seen FROM dns_records WHERE name = 'test.example.com';
-- last_seen devrait être NULL malgré la tentative du client de le définir
```

### 10. Formulaire de Modification - Visibilité de la Priorité Basée sur le Type d'Enregistrement

**Étapes de Test :**
1. Créer ou sélectionner un enregistrement MX existant
2. Cliquer sur "Modifier"
3. Vérifier que le champ priorité est visible et affiche la valeur actuelle
4. Créer ou sélectionner un enregistrement A
5. Cliquer sur "Modifier"
6. Vérifier que le champ priorité est masqué

**Résultat Attendu :**
- La visibilité du champ priorité en mode édition correspond au type d'enregistrement
- Les valeurs de priorité existantes sont affichées correctement pour MX/SRV

### 11. Vérifier l'Absence d'Erreurs dans la Console JavaScript

**Étapes de Test :**
1. Ouvrir les outils de développement du navigateur, onglet Console
2. Naviguer vers la page de Gestion DNS
3. Effectuer les actions suivantes :
   - Voir la liste des enregistrements
   - Cliquer sur "Créer un Enregistrement"
   - Changer les types d'enregistrements plusieurs fois
   - Soumettre un nouvel enregistrement
   - Modifier un enregistrement existant
   - Supprimer un enregistrement
   - Restaurer un enregistrement supprimé

**Résultat Attendu :**
- Aucune erreur JavaScript dans la console
- Toutes les actions se terminent avec succès
- L'interface est réactive

### 12. Lister les Enregistrements - Vérifier que Tous les Flux Fonctionnent Toujours

**Étapes de Test :**
1. Naviguer vers la page de Gestion DNS
2. Utiliser le filtre de recherche pour trouver des enregistrements
3. Utiliser le filtre de type pour filtrer par type d'enregistrement
4. Utiliser le filtre de statut pour afficher les enregistrements supprimés
5. Vérifier que la pagination fonctionne (si implémentée)

**Résultat Attendu :**
- Tous les filtres fonctionnent correctement
- Les enregistrements sont affichés correctement
- La colonne last_seen affiche les valeurs existantes ou "-" pour NULL
- Aucune erreur dans la console ou l'UI

### 13. Supprimer un Enregistrement - last_seen Reste Inchangé

**Étapes de Test :**
1. Noter la valeur `last_seen` pour un enregistrement
2. Cliquer sur le bouton "Supprimer"
3. Confirmer la suppression
4. Interroger la base de données pour vérifier que last_seen n'a pas changé

**Résultat Attendu :**
- Le statut de l'enregistrement change à "deleted"
- La valeur `last_seen` reste inchangée
- `updated_at` est mis à jour (attendu)

**Vérification :**
```sql
SELECT id, status, last_seen, updated_at FROM dns_records WHERE id = [record_id];
-- status devrait être 'deleted', last_seen inchangé, updated_at actuel
```

### 14. Restaurer un Enregistrement - last_seen Reste Inchangé

**Étapes de Test :**
1. Filtrer pour afficher les enregistrements supprimés
2. Noter la valeur `last_seen` pour un enregistrement supprimé
3. Cliquer sur le bouton "Restaurer"
4. Confirmer la restauration
5. Interroger la base de données pour vérifier que last_seen n'a pas changé

**Résultat Attendu :**
- Le statut de l'enregistrement change à "active"
- La valeur `last_seen` reste inchangée

### 15. Méthode markSeen() Toujours Disponible pour les Scripts

**Étapes de Test :**
1. Créer un script PHP de test qui appelle directement la méthode markSeen() :
   ```php
   <?php
   require_once 'includes/models/DnsRecord.php';
   $dnsRecord = new DnsRecord();
   $result = $dnsRecord->markSeen(1, 1); // record_id=1, user_id=1
   echo $result ? "Success" : "Failed";
   ```
2. Exécuter le script
3. Interroger la base de données pour vérifier que last_seen a été mis à jour

**Résultat Attendu :**
- La méthode markSeen() s'exécute avec succès
- L'horodatage `last_seen` est mis à jour dans la base de données
- Cela confirme que la méthode est préservée pour une utilisation future par des scripts externes

**Vérification :**
```sql
-- Avant l'exécution du script
SELECT id, last_seen FROM dns_records WHERE id = 1;
-- [Exécuter le script de test]
-- Après l'exécution du script
SELECT id, last_seen FROM dns_records WHERE id = 1;
-- last_seen devrait maintenant être mis à jour avec l'horodatage actuel
```

## Vérifications de Compatibilité Ascendante

### Gestion des Utilisateurs
- Vérifier que la création, l'édition et la suppression d'utilisateurs fonctionnent toujours
- Vérifier que l'authentification fonctionne toujours

### ACL/Mappings
- Vérifier que l'interface des mappings ACL fonctionne toujours (si présente)
- Vérifier que le contrôle d'accès basé sur les rôles n'est pas affecté

### Historique des Enregistrements DNS
- Vérifier que le suivi de l'historique fonctionne toujours pour toutes les opérations
- Vérifier que l'historique est affiché correctement dans l'UI

## Considérations de Performance

- Le basculement des champs de formulaire devrait être instantané (< 50ms)
- Les requêtes API ne devraient pas être plus lentes qu'avant
- Les requêtes de base de données ne devraient pas être affectées

## Compatibilité Navigateur

Tester dans les navigateurs suivants :
- Chrome/Edge (dernière version)
- Firefox (dernière version)
- Safari (dernière version, si possible)

## Notes pour les Relecteurs

1. La méthode `markSeen()` dans `includes/models/DnsRecord.php` a été préservée intentionnellement pour une utilisation future par des scripts externes.

2. L'API avait déjà des mesures de sécurité pour annuler les valeurs `last_seen` fournies par le client ; cette PR garantit que l'action GET ne la met pas non plus à jour.

3. Le comportement dynamique du formulaire affecte uniquement l'UI ; le serveur valide toujours toutes les entrées.

4. Le champ priorité est envoyé conditionnellement dans la charge utile (uniquement pour MX/SRV), mais le serveur gère les valeurs de priorité NULL de manière appropriée pour tous les types d'enregistrements.

5. Le champ `last_seen` reste dans le schéma de base de données et dans l'UI (en lecture seule en mode édition) mais n'est jamais mis à jour par les actions de l'interface web.
