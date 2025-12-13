# Guide de Test - Prévisualisation de Zone avec Affichage de la Validation

## Vue d'ensemble
Ce guide fournit des instructions pas à pas pour tester la nouvelle fonctionnalité de prévisualisation de zone avec affichage de la validation.

## Prérequis
- Accès à l'application DNS3
- Identifiants de compte administrateur
- Au moins un fichier de zone dans le système
- Commande `named-checkzone` disponible sur le serveur (pour la validation)

## Scénarios de Test

### Test 1 : Génération et Prévisualisation de Zone Basique

**Étapes :**
1. Se connecter à DNS3 en tant qu'administrateur
2. Naviguer vers "Gestion des fichiers de zone"
3. Cliquer sur n'importe quelle zone de la liste pour ouvrir le modal d'édition
4. Basculer vers l'onglet "Éditeur"
5. Cliquer sur le bouton "Générer le fichier de zone"

**Résultats Attendus :**
- ✅ Le modal de prévisualisation s'ouvre immédiatement
- ✅ L'état initial affiche "Chargement…" dans la zone de texte
- ✅ Après 1-2 secondes, le contenu du fichier de zone généré apparaît
- ✅ Le contenu inclut les données de zone, les directives $INCLUDE et les enregistrements DNS
- ✅ Le bouton de téléchargement devient actif

**Points de Capture d'Écran :**
- Ouverture du modal avec état de chargement
- Contenu généré affiché
- Bouton de téléchargement prêt

---

### Test 2 : Affichage de la Validation - Validation Réussie

**Étapes :**
1. Suivre les étapes 1-5 du Test 1
2. Attendre l'apparition du contenu généré
3. Regarder sous la zone de texte pour les résultats de validation

**Résultats Attendus :**
- ✅ La section de validation apparaît automatiquement (après le chargement du contenu)
- ✅ L'en-tête de section indique "Résultat de la validation (named-checkzone)"
- ✅ Le badge de statut affiche "✅ Validation réussie" en vert
- ✅ La sortie de validation affiche le résultat de la commande named-checkzone
- ✅ La sortie inclut du texte comme "zone example.com/IN: loaded serial..."

**Ce Qu'il Faut Vérifier :**
```
┌─────────────────────────────────────────────┐
│ Résultat de la validation (named-checkzone) │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐     │
│ │ ✅ Validation réussie (green bg)    │     │
│ └─────────────────────────────────────┘     │
│ ┌─────────────────────────────────────┐     │
│ │ zone example.com/IN: loaded serial  │     │
│ │ 2024102201                          │     │
│ │ OK                                  │     │
│ └─────────────────────────────────────┘     │
└─────────────────────────────────────────────┘
```

---

### Test 3 : Affichage de la Validation - Validation Échouée

**Étapes :**
1. Créer ou éditer une zone avec une syntaxe DNS intentionnellement invalide
2. Sauvegarder la zone
3. Cliquer sur "Générer le fichier de zone"
4. Attendre les résultats de validation

**Résultats Attendus :**
- ✅ Le badge de statut affiche "❌ Validation échouée" en rouge
- ✅ La sortie de validation affiche des messages d'erreur spécifiques
- ✅ Les messages d'erreur indiquent ce qui ne va pas avec le fichier de zone

**Ce Qu'il Faut Vérifier :**
```
┌─────────────────────────────────────────────┐
│ Résultat de la validation (named-checkzone) │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐     │
│ │ ❌ Validation échouée (red bg)      │     │
│ └─────────────────────────────────────┘     │
│ ┌─────────────────────────────────────┐     │
│ │ zone example.com/IN: loading from   │     │
│ │ file failed: syntax error          │     │
│ │ line 5: expected integer near 'abc' │     │
│ └─────────────────────────────────────┘     │
└─────────────────────────────────────────────┘
```

---

### Test 4 : Fonctionnalité de Téléchargement

**Étapes :**
1. Compléter le Test 1 ou Test 2
2. Cliquer sur le bouton "Télécharger" dans le pied de page du modal

**Résultats Attendus :**
- ✅ Le navigateur télécharge un fichier
- ✅ Le nom de fichier correspond au nom du fichier de zone (ex : "example.com.zone")
- ✅ Le contenu du fichier correspond à ce qui est affiché dans la zone de texte
- ✅ Un message de succès apparaît : "Fichier de zone téléchargé avec succès"

**Vérification :**
- Ouvrir le fichier téléchargé dans un éditeur de texte
- Comparer avec le contenu affiché dans le modal de prévisualisation
- Les deux doivent être identiques

---

### Test 5 : Superposition de Modal et z-index

**Étapes :**
1. Ouvrir un modal d'édition de zone
2. Cliquer sur "Générer le fichier de zone" pour ouvrir la prévisualisation
3. Cliquer à l'extérieur du modal de prévisualisation (sur le fond sombre)
4. Observer le comportement du modal

**Résultats Attendus :**
- ✅ Le modal de prévisualisation apparaît au-dessus du modal d'édition
- ✅ Le modal d'édition est toujours visible en arrière-plan
- ✅ Cliquer à l'extérieur du modal de prévisualisation ne ferme que la prévisualisation
- ✅ Le modal d'édition reste ouvert
- ✅ Aucun problème de z-index (la prévisualisation est toujours au-dessus)

**Vérification Visuelle :**
```
┌────────────────────────────────────────┐
│ Editor Modal (z-index: 1000)          │
│ ┌──────────────────────────────────┐  │
│ │ Preview Modal (z-index: 9999)    │  │
│ │ (This should be on top)          │  │
│ └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

---

### Test 6 : Gestion des Erreurs - Échec de Génération

**Étapes :**
1. Utiliser les outils de développement du navigateur pour simuler un échec réseau
2. Cliquer sur "Générer le fichier de zone"
3. Observer la gestion des erreurs

**Résultats Attendus :**
- ✅ Un message d'erreur apparaît dans la zone de texte
- ✅ Message en français : "Erreur lors de la génération du fichier de zone"
- ✅ Détails de l'erreur inclus
- ✅ La section de validation est masquée
- ✅ La console affiche les détails de l'erreur pour le débogage

**Test Alternatif :**
- Interrompre temporairement le point de terminaison API
- Essayer de générer un fichier de zone
- Vérifier que l'erreur est gérée de manière appropriée

---

### Test 7 : Gestion des Erreurs - Échec de Validation

**Étapes :**
1. Générer avec succès un fichier de zone
2. Simuler un échec de l'API de validation (ou si named-checkzone n'est pas disponible)
3. Observer la gestion des erreurs dans la section de validation

**Résultats Attendus :**
- ✅ Le contenu généré s'affiche toujours correctement
- ✅ La section de validation affiche une erreur
- ✅ Message d'erreur : "❌ Erreur lors de la récupération de la validation"
- ✅ Les détails expliquent que la validation n'a pas pu être effectuée
- ✅ La console affiche l'erreur pour le débogage

---

### Test 8 : Comportement de Fermeture du Modal

**Étapes :**
1. Ouvrir le modal de prévisualisation
2. Essayer chaque méthode de fermeture :
   a. Cliquer sur le bouton X dans l'en-tête
   b. Cliquer sur le bouton "Fermer" dans le pied de page
   c. Cliquer sur le fond sombre à l'extérieur du modal

**Résultats Attendus :**
- ✅ Les trois méthodes ferment le modal de prévisualisation
- ✅ Le modal d'édition reste ouvert dans tous les cas
- ✅ Aucune erreur JavaScript dans la console
- ✅ Le modal peut être rouvert sans problème

---

### Test 9 : Comportement Responsive

**Étapes :**
1. Ouvrir le modal de prévisualisation en vue bureau
2. Redimensionner le navigateur à la taille tablette (768px de large)
3. Redimensionner à la taille mobile (375px de large)
4. Tester toutes les fonctionnalités à chaque taille

**Résultats Attendus :**
- ✅ Le modal s'adapte correctement
- ✅ Tous les éléments restent lisibles
- ✅ Les boutons restent accessibles
- ✅ Aucun défilement horizontal requis
- ✅ La section de validation reste visible

---

### Test 10 : Zones Multiples

**Étapes :**
1. Ouvrir et générer la prévisualisation pour la zone A
2. Fermer les modaux de prévisualisation et d'édition
3. Ouvrir et générer la prévisualisation pour la zone B
4. Comparer les résultats

**Résultats Attendus :**
- ✅ Chaque zone affiche son propre contenu
- ✅ Les résultats de validation sont spécifiques à chaque zone
- ✅ Aucune contamination de données entre les prévisualisations
- ✅ Le bouton de téléchargement télécharge le fichier correct pour chaque zone

---

## Test de Compatibilité Navigateur

Tester la fonctionnalité dans :
- ✅ Chrome/Edge (Chromium)
- ✅ Firefox
- ✅ Safari (si disponible)

## Test de Performance

**Métriques à Vérifier :**
1. Temps entre le clic du bouton et l'ouverture du modal : Devrait être < 100ms
2. Temps pour récupérer et afficher le contenu : Devrait être < 2 secondes
3. Temps pour afficher la validation : Devrait être < 3 secondes au total
4. Pas de fuite mémoire après plusieurs ouvertures/fermetures

## Vérifications Console

Ouvrir les Outils de Développement du navigateur → Console et vérifier :
- ✅ Aucune erreur JavaScript
- ✅ Toutes les requêtes fetch réussissent (200 OK)
- ✅ Messages de validation enregistrés pour le débogage
- ✅ Messages d'erreur (le cas échéant) sont descriptifs

## Problèmes Courants et Solutions

### Problème : Le modal ne s'ouvre pas
**Vérifier :**
- La console JavaScript pour les erreurs
- Le gestionnaire de clic du bouton est attaché
- L'élément modal existe dans le DOM

### Problème : Le contenu affiche "Chargement…" indéfiniment
**Vérifier :**
- Le point de terminaison API est accessible
- L'onglet réseau montre que la requête a réussi
- La réponse est un JSON valide
- L'authentification fonctionne

### Problème : La validation n'apparaît pas
**Vérifier :**
- Le point de terminaison API de validation est accessible
- named-checkzone est installé sur le serveur
- Les résultats de validation sont retournés dans le format correct
- Aucune erreur JavaScript dans la console

### Problème : Le téléchargement ne fonctionne pas
**Vérifier :**
- Les données de prévisualisation sont remplies
- La création de Blob réussit
- Le navigateur autorise les téléchargements
- Aucun bloqueur de popup n'interfère

### Problème : Mauvais z-index (les modaux se superposent incorrectement)
**Vérifier :**
- Le modal de prévisualisation a z-index: 9999 appliqué
- Le CSS est chargé correctement
- Aucun style en conflit

## Validation des Tests

Après avoir complété tous les tests, documenter les résultats :

| Test | Statut | Notes | Testeur | Date |
|------|--------|-------|---------|------|
| Test 1 - Génération Basique | ⏳ | | | |
| Test 2 - Validation Réussie | ⏳ | | | |
| Test 3 - Validation Échouée | ⏳ | | | |
| Test 4 - Téléchargement | ⏳ | | | |
| Test 5 - Superposition Modal | ⏳ | | | |
| Test 6 - Erreur Génération | ⏳ | | | |
| Test 7 - Erreur Validation | ⏳ | | | |
| Test 8 - Comportement Fermeture | ⏳ | | | |
| Test 9 - Responsive | ⏳ | | | |
| Test 10 - Zones Multiples | ⏳ | | | |

## Approbation Finale

- [ ] Tous les tests critiques sont passés
- [ ] Aucun problème bloquant trouvé
- [ ] Les performances sont acceptables
- [ ] L'UI/UX est satisfaisante
- [ ] La documentation est complète
- [ ] Prêt pour le déploiement en production

**Approuvé par :** ________________  **Date :** __________
