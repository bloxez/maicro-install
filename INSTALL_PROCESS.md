# Maintaining the Install Process

## Problem: Old Workflow (Causes Mistakes)

Previously, `maicro-install/` was treated as a separate git repository with its own remote. This caused:
- Confusion about which repo to commit to
- Easy to accidentally reset the wrong repo (as happened)
- Need to manually track two separate repositories
- Changes had to be applied to both repos separately

## New Workflow: Unified Management Using Existing Script

### Source of Truth: `maicro` repo

All install-related files now live in `/workspaces/maicro/maicro-install/`:
- `run.sh`
- `run.ps1`
- `README.md`
- `LICENSE`

These are committed and pushed to `origin/main` (the main `maicro` repo) **just like any other files**.

### Publishing to the External Install Repo

When install scripts need to be published to the external `bloxez/maicro-install` repo, use the deno task:

```bash
deno task 35-publish-install
```

**That's it.** The task:
1. Clones the external install repo temporarily
2. Copies your changes from `maicro-install/` folder
3. Commits with a timestamp message
4. Pushes to `bloxez/maicro-install` main branch
5. Cleans up temp files
6. Shows success confirmation

### Workflow Example

```bash
# 1. Make changes to install scripts
edit maicro-install/run.sh
edit maicro-install/run.ps1
edit maicro-install/README.md

# 2. Commit to main maicro repo (normal workflow)
git add maicro-install/
git commit -m "feat: add project:key authentication to install scripts"
git push origin main

# 3. Publish to external install repo when ready
deno task 35-publish-install
```

## Safety Guarantees

✅ **Single source of truth**: `maicro-install/` in main repo
✅ **Clear separation**: Install changes go through normal maicro commit process first
✅ **Easy to review**: Changes are tracked in main repo history
✅ **Automatic sync**: Script handles the external repo details
✅ **No accidental resets**: Can't mix up remotes—there's only one remote per repo

## Benefits

| Before | After |
|--------|-------|
| Confusion about which repo to use | Single workflow—commit to maicro |
| Easy to make git mistakes | Existing script handles external repo |
| Manual sync required for two repos | One command publishes changes |
| Hard to track changes | All history in main repo |

## Notes

- The sync script requires `git` SSH access to `bloxez/maicro-install`
- Changes are always committed to the main `maicro` repo first
- You can sync multiple commits at once
- The external install repo will have flattened history (squash commits) to keep it clean
