#!/bin/bash
# Script to create PR for modal unification changes
# This script pushes feature/unify-modals and creates a draft PR

set -e

echo "=== DNS3 Modal Unification PR Creation Script ==="
echo ""

# Check if we're on the right branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "feature/unify-modals" ]; then
    echo "Switching to feature/unify-modals branch..."
    git checkout feature/unify-modals
fi

# Show summary of changes
echo "Summary of changes:"
git log --oneline HEAD~3..HEAD
echo ""

# Show file changes
echo "Files modified:"
git diff HEAD~3..HEAD --stat
echo ""

# Push the branch
echo "Pushing feature/unify-modals to origin..."
git push -u origin feature/unify-modals

echo ""
echo "Branch pushed successfully!"
echo ""

# Try to create PR using gh CLI if available
if command -v gh &> /dev/null; then
    echo "Creating DRAFT PR using GitHub CLI..."
    gh pr create \
        --draft \
        --base main \
        --head feature/unify-modals \
        --title "Unify Modal System - 720px Fixed Height & Standardized UI" \
        --body-file docs/archive/PR_UNIFY_MODALS.md
    
    echo ""
    echo "DRAFT PR created successfully!"
    gh pr view --web
else
    echo "GitHub CLI (gh) not found."
    echo "Please create the DRAFT PR manually:"
    echo ""
    echo "1. Go to: https://github.com/guittou/dns3/compare/main...feature/unify-modals"
    echo "2. Click 'Create pull request'"
    echo "3. Use the title: 'Unify Modal System - 720px Fixed Height & Standardized UI'"
    echo "4. Copy the content from docs/archive/PR_UNIFY_MODALS.md as the PR description"
    echo "5. Mark the PR as DRAFT"
fi

echo ""
echo "=== Done ==="
