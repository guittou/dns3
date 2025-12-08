# Guide de Contribution à la Documentation

Ce document explique comment ajouter, modifier ou organiser la documentation du projet DNS3.

---

## Table des Matières

- [Principes Généraux](#principes-généraux)
- [Structure de la Documentation](#structure-de-la-documentation)
- [Ajouter un Nouveau Document](#ajouter-un-nouveau-document)
- [Mettre à Jour SUMMARY.md](#mettre-à-jour-summarymd)
- [Conventions de Nommage](#conventions-de-nommage)
- [Style et Format](#style-et-format)
- [Traduction](#traduction)
- [Vérification et Tests](#vérification-et-tests)

---

## Principes Généraux

### Langue

- **Français** : Langue principale de la documentation
- Les documents existants en anglais sont progressivement traduits
- Les termes techniques (DNS, API, tokens, etc.) peuvent rester en anglais s'ils sont universellement reconnus
- Les exemples de code et commandes restent en anglais (conventions internationales)

### Organisation

- **Un document = un sujet** : Chaque fichier doit traiter un seul sujet clairement défini
- **Hiérarchie logique** : Organisez les sections par ordre d'utilisation (installation → configuration → utilisation → maintenance)
- **Liens croisés** : Référencez les documents connexes pour faciliter la navigation

### Audience

- **Utilisateurs** : Administrateurs système, développeurs, gestionnaires DNS
- **Niveau technique** : Intermédiaire à avancé
- **Objectif** : Permettre l'auto-apprentissage et servir de référence rapide

---

## Structure de la Documentation

```
dns3/
├── README.md                          # Vue d'ensemble du projet
├── docs/
│   ├── SUMMARY.md                     # INDEX GLOBAL (à mettre à jour)
│   ├── CONTRIBUTING_DOCS.md           # Ce fichier
│   │
│   ├── GETTING_STARTED_API_TOKENS.md  # Guide de démarrage rapide
│   ├── INSTALL.md                     # Installation
│   ├── DB_SCHEMA.md                   # Schéma de base de données
│   │
│   ├── ADMIN_*.md                     # Documentation administration
│   ├── DNS_*.md                       # Documentation gestion DNS
│   ├── ZONE_*.md                      # Documentation fichiers de zone
│   ├── API_*.md                       # Documentation API
│   ├── UI_*.md                        # Documentation interface utilisateur
│   ├── MODAL_*.md                     # Documentation composants modaux
│   ├── TESTING_*.md                   # Documentation tests
│   ├── VALIDATION_*.md                # Documentation validation
│   ├── IMPLEMENTATION_*.md            # Notes d'implémentation
│   │
│   ├── import_bind_zones.md           # Import de zones BIND
│   ├── api_token_authentication.md    # Authentification API
│   ├── UPDATE_LAST_SEEN_FROM_BIND_LOGS.md
│   │
│   ├── backup/                        # Backups des versions anglaises
│   │   └── (fichiers .en.md)
│   │
│   └── archive/                       # Documents historiques
│       └── (anciens PR, notes obsolètes)
│
├── jobs/README.md                     # Documentation workers
└── migrations/README.md               # Documentation migrations
```

---

## Ajouter un Nouveau Document

### 1. Choisir l'Emplacement

Déterminez où placer votre document :

- **Racine** (`/`) : README.md uniquement
- **docs/** : Documentation principale (guides, références, implémentation, guides de démarrage)
- **docs/backup/** : Backups des versions originales anglaises
- **docs/archive/** : Documents obsolètes ou historiques (ne pas éditer)
- **Sous-dossiers** (`jobs/`, `migrations/`) : Documentation spécifique au composant

### 2. Choisir un Nom de Fichier

Suivez les conventions :

```
# Bon
ADMIN_INTERFACE_GUIDE.md
DNS_MANAGEMENT_GUIDE.md
api_token_authentication.md

# Mauvais
guide.md                    # Trop vague
admin_guide_v2_final.md    # Versionnage inutile
GuideAdmin.md              # Casse mixte
```

### 3. Créer le Fichier

```bash
# Template de base
cd docs/
touch NOUVEAU_GUIDE.md
```

**Contenu minimal** :

```markdown
# Titre du Document

## Vue d'ensemble

Brève description du sujet traité (2-3 phrases).

## Prérequis

- Liste des prérequis
- Connaissances nécessaires
- Outils requis

## Contenu Principal

### Section 1

...

### Section 2

...

## Exemples

### Exemple 1

```bash
# Commandes
```

## Dépannage

### Problème 1

**Symptôme** : Description

**Solution** : ...

## Voir Aussi

- [Document Connexe](autre_doc.md)
- [Guide Associé](guide.md)
```

### 4. Mettre à Jour SUMMARY.md

**IMPORTANT** : Chaque nouveau document DOIT être référencé dans `docs/SUMMARY.md`.

Voir la section [Mettre à Jour SUMMARY.md](#mettre-à-jour-summarymd) ci-dessous.

---

## Mettre à Jour SUMMARY.md

Le fichier `docs/SUMMARY.md` est l'**index global** de toute la documentation. Il DOIT être mis à jour chaque fois qu'un document est ajouté, renommé ou déplacé.

### Processus

1. **Ouvrez** `docs/SUMMARY.md`
2. **Identifiez** la section appropriée (Administration, API, Tests, etc.)
3. **Ajoutez** une ligne dans la liste avec :
   - Un titre descriptif en français
   - Un chemin relatif correct
   - Une brève description

**Format** :

```markdown
- [Titre du Document](chemin/relatif/fichier.md) - Brève description
```

### Exemple Complet

**Avant** :

```markdown
### 🔧 Administration et Configuration

- [Guide d'utilisation de l'interface admin](ADMIN_INTERFACE_GUIDE.md) - Guide complet
- [Référence rapide admin](ADMIN_QUICK_REFERENCE.md) - Référence rapide
```

**Après** (ajout d'un nouveau document) :

```markdown
### 🔧 Administration et Configuration

- [Guide d'utilisation de l'interface admin](ADMIN_INTERFACE_GUIDE.md) - Guide complet
- [Référence rapide admin](ADMIN_QUICK_REFERENCE.md) - Référence rapide
- [Gestion des utilisateurs AD/LDAP](ADMIN_USER_MANAGEMENT.md) - Gestion des utilisateurs externes
```

### Règles de Placement

- **Introduction et Démarrage** : README, installation, démarrage rapide
- **Administration** : Gestion des utilisateurs, rôles, authentification
- **Gestion DNS** : Zones, enregistrements, validation
- **API** : Documentation des endpoints, authentification
- **Scripts** : Utilitaires, imports, migrations
- **Base de Données** : Schéma, migrations
- **Architecture** : Design, implémentation, diagrammes
- **Interface** : UI, modals, composants
- **Tests** : Plans de test, guides de test, validation
- **Livraison** : Résumés de complétion, vérifications
- **Archives** : Documents historiques (ne pas ajouter de nouveaux)

---

## Conventions de Nommage

### Fichiers

| Type | Convention | Exemples |
|------|-----------|----------|
| Guides principaux | `NOM_GUIDE.md` (majuscules + underscores) | `ADMIN_INTERFACE_GUIDE.md`, `DNS_MANAGEMENT_GUIDE.md` |
| Documentation technique | `nom_technique.md` (minuscules + underscores) | `api_token_authentication.md`, `import_bind_zones.md` |
| Notes d'implémentation | `IMPLEMENTATION_*.md` | `IMPLEMENTATION_NOTES.md`, `IMPLEMENTATION_SUMMARY_PAGINATION.md` |
| Tests | `TESTING_*.md` ou `TEST_*.md` | `TESTING_GUIDE.md`, `TEST_PLAN.md` |

### Sections

- Utilisez des titres clairs et descriptifs
- Hiérarchie : `#` pour le titre, `##` pour sections principales, `###` pour sous-sections
- Emojis optionnels dans SUMMARY.md pour clarté visuelle (📚, 🔧, 🌐, etc.)

---

## Style et Format

### Markdown

- **Titres** : Une seule `#` pour le titre principal
- **Listes** : `-` pour les listes non ordonnées, `1.` pour les ordonnées
- **Code inline** : \`code\` pour commandes, variables, noms de fichiers
- **Blocs de code** : \`\`\`bash ou \`\`\`php ou \`\`\`sql avec le langage spécifié
- **Liens** : `[texte](chemin/relatif.md)` pour liens internes, `[texte](https://...)` pour externes
- **Notes** : `> **Note** : ...` pour les notes importantes
- **Avertissements** : `⚠️ **ATTENTION** : ...` pour les avertissements

### Structure Recommandée

1. **Titre principal** (`#`)
2. **Vue d'ensemble** : 2-3 phrases décrivant le document
3. **Table des matières** (optionnel pour documents longs)
4. **Prérequis** : Ce qui est nécessaire avant de commencer
5. **Contenu principal** : Sections logiques avec titres clairs
6. **Exemples pratiques** : Au moins 2-3 exemples concrets
7. **Dépannage** : Problèmes courants et solutions
8. **Voir aussi** : Liens vers documents connexes

### Exemple de Bon Format

```markdown
# Import de Zones BIND

## Vue d'ensemble

Ce document explique comment importer des fichiers de zone BIND existants dans DNS3.

## Prérequis

- Accès à un serveur avec Python 3.6+
- Fichiers de zone BIND valides
- Droits d'accès à l'API DNS3

## Installation

### 1. Installer les dépendances

```bash
pip3 install dnspython requests
```

### 2. Configurer les credentials

...

## Utilisation

### Commande de base

```bash
python3 scripts/import_bind_zones.py --dir /var/named/zones
```

## Exemples

### Exemple 1 : Import avec dry-run

...

## Dépannage

### Erreur "Module not found"

**Symptôme** : `ImportError: No module named 'dns'`

**Solution** :
```bash
pip3 install dnspython
```

## Voir Aussi

- [API Authentication](api_token_authentication.md)
- [DNS Management Guide](DNS_MANAGEMENT_GUIDE.md)
```

---

## Traduction

### Langues

- **Français** : Langue cible pour toute la documentation
- **Anglais** : Certains documents historiques restent en anglais dans `docs/backup/`

### Processus de Traduction

Si vous traduisez un document existant en anglais :

1. **Créer un backup** :
   ```bash
   mkdir -p docs/backup
   cp docs/original.md docs/backup/original.en.md
   ```

2. **Traduire le contenu** :
   - Traduisez les titres, paragraphes, notes
   - **NE TRADUISEZ PAS** :
     - Blocs de code (commandes, SQL, PHP, etc.)
     - Noms de fichiers et chemins
     - Variables et noms techniques
     - URLs et commandes shell

3. **Mettre à jour les liens** :
   - Vérifiez que tous les liens relatifs sont corrects
   - Mettez à jour les références dans SUMMARY.md

4. **Réviser** :
   - Relisez pour la cohérence
   - Vérifiez la terminologie technique
   - Testez les liens

### Terminologie

| Anglais | Français | Notes |
|---------|----------|-------|
| Guide | Guide | OK |
| Overview | Vue d'ensemble | |
| Quick Start | Démarrage rapide | |
| Reference | Référence | |
| Implementation | Implémentation | OK technique |
| Testing | Tests | |
| Troubleshooting | Dépannage | |
| API Token | Token API | Garder "token" |
| DNS Record | Enregistrement DNS | |
| Zone File | Fichier de zone | |

---

## Vérification et Tests

### Avant de Committer

1. **Vérifier la syntaxe Markdown** :
   ```bash
   # Installer un linter (optionnel)
   npm install -g markdownlint-cli
   markdownlint docs/**/*.md
   ```

2. **Tester les liens relatifs** :
   ```bash
   # Vérifier que tous les fichiers existent
   grep -r "\[.*\](.*\.md)" docs/SUMMARY.md | grep -v "http" | \
     awk -F'[()]' '{print $2}' | while read file; do
       [ -f "docs/$file" ] || echo "MISSING: $file"
     done
   ```

3. **Vérifier l'encodage UTF-8** :
   ```bash
   file docs/NOUVEAU_DOC.md
   # Doit afficher : UTF-8 Unicode text
   ```

4. **Prévisualiser** :
   - Ouvrez le fichier dans un viewer Markdown
   - Vérifiez le rendu des tableaux, listes, blocs de code
   - Testez les liens en cliquant dessus

### Checklist de Relecture

- [ ] Le titre principal est clair et descriptif
- [ ] Le document est ajouté à `docs/SUMMARY.md`
- [ ] Tous les liens relatifs fonctionnent
- [ ] Les blocs de code ont le bon langage spécifié
- [ ] La terminologie est cohérente avec les autres documents
- [ ] Les exemples sont testés et fonctionnels
- [ ] L'encodage est UTF-8
- [ ] Pas de mots anglais inutiles (sauf termes techniques)

---

## Commandes Utiles

### Rechercher des Références

```bash
# Trouver où un document est référencé
grep -r "mon_document.md" docs/

# Lister tous les documents non référencés dans SUMMARY.md
comm -23 \
  <(find docs -name "*.md" -not -path "*/archive/*" | sort) \
  <(grep -o "[^(]*\.md" docs/SUMMARY.md | sort | sed 's|^|docs/|')
```

### Vérifier la Cohérence

```bash
# Trouver des mots anglais courants (à réviser manuellement)
grep -riE "\b(the|and|or|with|for)\b" docs/*.md | grep -v "```" | head -20

# Compter les documents par catégorie
grep "^###" docs/SUMMARY.md
```

---

## Exemples de Contributions

### Ajouter un Guide d'Utilisation

```bash
# 1. Créer le fichier
cd docs/
vi NOUVEAU_FEATURE_GUIDE.md

# 2. Éditer SUMMARY.md
vi SUMMARY.md
# Ajouter la ligne appropriée dans la section correspondante

# 3. Vérifier
grep "NOUVEAU_FEATURE_GUIDE" SUMMARY.md

# 4. Committer
git add NOUVEAU_FEATURE_GUIDE.md SUMMARY.md
git commit -m "docs: add guide for new feature"
```

### Traduire un Document

```bash
# 1. Backup de l'original
mkdir -p docs/backup
cp docs/old_doc.md docs/backup/old_doc.en.md

# 2. Traduire
vi docs/old_doc.md
# (traduire le contenu)

# 3. Mettre à jour SUMMARY.md si nécessaire
vi docs/SUMMARY.md

# 4. Committer
git add docs/old_doc.md docs/backup/old_doc.en.md docs/SUMMARY.md
git commit -m "docs: translate old_doc.md to French"
```

---

## Support et Questions

- **Issues** : Ouvrir une issue GitHub avec le tag `documentation`
- **Pull Requests** : Proposer des changements via PR avec une description claire
- **Révision** : Toute modification de SUMMARY.md doit être révisée

---

**Dernière mise à jour** : 2025-12-08  
**Mainteneur** : Équipe DNS3
