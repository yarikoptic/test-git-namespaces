# GitHub Namespace Limitation - Important Discovery

## The Problem

**GitHub does not support nested namespaces.**

Reference: https://github.com/orgs/community/discussions/45611

## What This Means

While Git natively supports nested namespaces like:
```
refs/namespaces/main-repo/refs/namespaces/sub1/refs/heads/master
```

GitHub only supports flat namespaces like:
```
refs/namespaces/main-repo/refs/heads/master
```

## The Solution: Flattening with `--`

We flatten the hierarchy by replacing `/` with `--` in namespace names:

| Submodule Path | ❌ Nested (doesn't work on GitHub) | ✅ Flattened (works) |
|---------------|-----------------------------------|---------------------|
| `submodule1` | `submodule1` | `submodule1` |
| `main-repo` | `main-repo` | `main-repo` |
| `main-repo/sub1` | `main-repo/sub1` | `main-repo--sub1` |
| `main-repo/sub2` | `main-repo/sub2` | `main-repo--sub2` |
| `test-main-clone/sub1` | `test-main-clone/sub1` | `test-main-clone--sub1` |

## Updated Scripts

Both scripts now use flattened namespaces:

```bash
# Main script - flattens automatically
./push-with-namespaces.sh origin main

# Force push version - also flattened
./push-with-namespaces-force.sh origin main
```

### What Changed

```bash
# OLD (nested - doesn't work on GitHub)
namespace="$path"  # Keeps / as-is

# NEW (flattened - works on GitHub)
namespace="${path//\//--}"  # Replaces / with --
```

## GitHub Namespace Structure

After pushing, your GitHub repository will have:

```
github.com/yarikoptic/test-git-namespaces
└── refs/namespaces/
    ├── main/refs/heads/master                   (main repo)
    ├── submodule1/refs/heads/master             (top-level)
    ├── submodule2/refs/heads/master             (top-level)
    ├── main-repo/refs/heads/master              (top-level)
    ├── main-repo--sub1/refs/heads/master        (flattened!)
    ├── main-repo--sub2/refs/heads/master        (flattened!)
    ├── test-main-clone/refs/heads/master        (top-level)
    ├── test-main-clone--sub1/refs/heads/master  (flattened!)
    └── test-main-clone--sub2/refs/heads/master  (flattened!)
```

## Updated .gitmodules

The `.gitmodules.github` file now uses flattened namespaces:

```gitmodules
[submodule "main-repo/sub1"]
    path = main-repo/sub1
    url = ext::git --namespace=main-repo--sub1 %s https://github.com/yarikoptic/test-git-namespaces
```

Note: The **path** stays as `main-repo/sub1`, but the **namespace** is `main-repo--sub1`.

## Cloning from Flattened Namespaces

```bash
# Clone main repository
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=main %s https://github.com/yarikoptic/test-git-namespaces" \
  cloned-main

# Clone a nested submodule (use flattened name!)
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=main-repo--sub1 %s https://github.com/yarikoptic/test-git-namespaces" \
  cloned-submodule
```

## Local Testing Still Supports Nested

Interestingly, **local bare repositories DO support nested namespaces**:

```bash
# This works locally
git --git-dir=bare-remote for-each-ref | grep "main-repo/refs/namespaces/sub1"
```

But since we need GitHub compatibility, we use flattened namespaces everywhere for consistency.

## Verification

After pushing to GitHub with flattened namespaces:

```bash
# List all namespaces on GitHub
git ls-remote origin 'refs/namespaces/*'

# You should see:
# refs/namespaces/main/refs/heads/master
# refs/namespaces/main-repo--sub1/refs/heads/master  (note the --)
# refs/namespaces/main-repo--sub2/refs/heads/master
```

## Impact on Original Experiment

The original experiment in this directory demonstrated nested namespaces working **locally**. That still works! But for GitHub, we must use the flattened approach.

### Local (Nested) vs GitHub (Flattened)

| Location | Supports Nested? | Namespace Format |
|----------|-----------------|------------------|
| Local bare repo | ✅ Yes | `main-repo/sub1` |
| GitHub | ❌ No | `main-repo--sub1` |

## Summary

- ✅ Scripts updated to use `--` flattening
- ✅ `.gitmodules.github` updated with flattened names
- ✅ Works with GitHub's namespace limitations
- ✅ Maintains logical relationship (path still shows hierarchy)
- ✅ Easy to understand: `main-repo--sub1` clearly indicates nested relationship

## Ready to Push

```bash
# Use the updated scripts (already flattened)
./push-with-namespaces-force.sh origin main
```

This will push with flattened namespaces that work on GitHub!
