#!/bin/bash
# Script to push feature branch and create PR
# Run this script to complete the PR creation process

set -e

echo "=== DNS3 Admin Changes PR Creation Script ==="
echo ""

# Check if we're on the right branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "feature/fix-admin-db-only" ]; then
    echo "Switching to feature/fix-admin-db-only branch..."
    git checkout feature/fix-admin-db-only
fi

# Show summary of changes
echo "Summary of changes:"
git log --oneline main..HEAD
echo ""

# Show file changes
echo "Files modified:"
git diff main..HEAD --stat
echo ""

# Push the branch
echo "Pushing feature/fix-admin-db-only to origin..."
git push -u origin feature/fix-admin-db-only

echo ""
echo "Branch pushed successfully!"
echo ""

# Try to create PR using gh CLI if available
if command -v gh &> /dev/null; then
    echo "Creating PR using GitHub CLI..."
    gh pr create \
        --base main \
        --head feature/fix-admin-db-only \
        --title "Enforce DB-Only User Creation and AD/LDAP Mapping Integration" \
        --body-file PR_DESCRIPTION.md
    
    echo ""
    echo "PR created successfully!"
    gh pr view --web
else
    echo "GitHub CLI (gh) not found."
    echo "Please create the PR manually:"
    echo ""
    echo "1. Go to: https://github.com/guittou/dns3/compare/main...feature/fix-admin-db-only"
    echo "2. Click 'Create pull request'"
    echo "3. Use the title: 'Enforce DB-Only User Creation and AD/LDAP Mapping Integration'"
    echo "4. Copy the content from PR_DESCRIPTION.md as the PR description"
fi

echo ""
echo "=== Done ==="
