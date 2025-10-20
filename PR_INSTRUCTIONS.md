# Pull Request Instructions

## Branch Status

The implementation has been completed on the local branch `feature/fix-admin-db-only` with the following commits:

```
1370456 Final updates to feature branch
61e7f1a Add documentation for admin authentication changes  
d40e3aa Implement database-only user creation and AD/LDAP mapping integration
```

Base branch: `main` (commit 5bae02a)

## How to Create the PR

Since the automated push is not available, please manually push the branch and create the PR:

```bash
# Push the feature branch to GitHub
git push -u origin feature/fix-admin-db-only

# Create a PR via GitHub UI or gh CLI
gh pr create --base main --head feature/fix-admin-db-only \
  --title "Enforce DB-Only User Creation and AD/LDAP Mapping Integration" \
  --body-file PR_DESCRIPTION.md
```

## Alternative: Use the Copilot Branch

The same changes are also available on `copilot/implement-admin-changes-mapping-integration`:

```bash
# Rename the copilot branch to the feature branch name
git push origin copilot/implement-admin-changes-mapping-integration:feature/fix-admin-db-only

# Or create PR from copilot branch and rename later
gh pr create --base main --head copilot/implement-admin-changes-mapping-integration \
  --title "Enforce DB-Only User Creation and AD/LDAP Mapping Integration" \
  --body-file PR_DESCRIPTION.md
```

## Verification

Before creating the PR, verify the changes:

```bash
# View changes between main and feature branch
git diff main..feature/fix-admin-db-only --stat

# Expected output:
# admin.php                | 20 ++++----------------
# api/admin_api.php        | 31 ++++++++++++++-----------------
# assets/js/admin.js       | 49 ++++++++++++++++++++++---------------------------
# includes/auth.php        | 88 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++----------
# includes/models/User.php | 21 +++++++++++----------
# ADMIN_AUTH_CHANGES.md    | 146 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 6 files changed, 273 insertions(+), 82 deletions(-)
```

## Testing Checklist

Before merging, ensure the following tests pass:

- [ ] Create user via admin UI → auth_method='database' in DB
- [ ] Craft POST with auth_method:'ad' → Server persists auth_method='database'  
- [ ] Try update user's auth_method to 'ldap' → Returns 400 error
- [ ] Admin panel shows only 3 tabs (no ACL tab)
- [ ] Create AD/LDAP mapping via UI
- [ ] Login with AD/LDAP user → User created with correct auth_method
- [ ] AD/LDAP login with mapped group → Role assigned in user_roles table

See [ADMIN_AUTH_CHANGES.md](./ADMIN_AUTH_CHANGES.md) for detailed testing procedures.
