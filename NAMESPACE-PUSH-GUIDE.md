# Guide: Pushing Repository with Nested Namespaces

## Summary

This guide documents how to push a Git repository and all its submodules to a remote using **nested namespaces**, where submodule hierarchy is preserved (e.g., `main-repo/sub1` creates `refs/namespaces/main-repo/refs/namespaces/sub1/`).

## Quick Start

```bash
# Add your GitHub remote (if not already added)
git remote add origin https://github.com/yarikoptic/test-git-namespaces

# Push everything with namespaces
./push-with-namespaces.sh origin main
```

## Script Usage

```bash
./push-with-namespaces.sh <remote-name> [main-namespace]
```

**Parameters:**
- `remote-name`: Git remote name (e.g., `origin`, `github`)
- `main-namespace`: Namespace for main repository (default: `main`)

**Examples:**
```bash
# Push to origin with 'main' namespace
./push-with-namespaces.sh origin main

# Push to different remote with custom namespace
./push-with-namespaces.sh github experiment

# Test locally first
./push-with-namespaces.sh local_test test
```

## What the Script Does

1. **Pushes main repository** to `<main-namespace>` namespace
2. **Iterates through all submodules** (including nested ones)
3. **Pushes each submodule** to its own namespace using the submodule path

### Namespace Mapping

| Submodule Path | Namespace | Ref Path |
|---------------|-----------|----------|
| (main) | `main` | `refs/namespaces/main/refs/heads/master` |
| `submodule1` | `submodule1` | `refs/namespaces/submodule1/refs/heads/master` |
| `main-repo` | `main-repo` | `refs/namespaces/main-repo/refs/heads/master` |
| `main-repo/sub1` | `main-repo/sub1` | `refs/namespaces/main-repo/refs/namespaces/sub1/refs/heads/master` |
| `test-main-clone/sub2` | `test-main-clone/sub2` | `refs/namespaces/test-main-clone/refs/namespaces/sub2/refs/heads/master` |

**Key Point:** The `/` in submodule paths is preserved, creating hierarchical nested namespaces!

## Local Testing (Recommended!)

Before pushing to GitHub, test locally:

```bash
# 1. Add local bare repo as remote
git remote add local_test /path/to/bare-repo

# 2. Push with namespaces
./push-with-namespaces.sh local_test test

# 3. Verify namespace structure
git --git-dir=/path/to/bare-repo for-each-ref | grep namespaces
```

### Verification Output

You should see refs like:
```
commit refs/namespaces/test/refs/heads/master
commit refs/namespaces/submodule1/refs/heads/master  
commit refs/namespaces/main-repo/refs/heads/master
commit refs/namespaces/main-repo/refs/namespaces/sub1/refs/heads/master
commit refs/namespaces/main-repo/refs/namespaces/sub2/refs/heads/master
```

## Pushing to GitHub

Once tested locally:

```bash
# Push to GitHub
./push-with-namespaces.sh origin main
```

**Note:** You need push access and proper authentication (SSH keys or access token).

## Viewing Namespaces on GitHub

After pushing:

```bash
# View all namespace refs
git ls-remote origin 'refs/namespaces/*'

# Or clone and inspect
git clone https://github.com/yarikoptic/test-git-namespaces temp
cd temp
git --git-dir=.git for-each-ref | grep namespaces
```

## Cloning from Namespaces

To clone a specific namespace from GitHub:

```bash
# Clone main repository
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=main %s https://github.com/yarikoptic/test-git-namespaces" \
  my-clone

# Clone a nested submodule
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=main-repo/sub1 %s https://github.com/yarikoptic/test-git-namespaces" \
  my-submodule
```

## Updating .gitmodules

To make the repository work with GitHub namespaces, update `.gitmodules`:

```bash
# Use the prepared template
cp .gitmodules.github .gitmodules

# Or manually update each [submodule] section:
[submodule "main-repo/sub1"]
    path = main-repo/sub1
    url = ext::git --namespace=main-repo/sub1 %s https://github.com/yarikoptic/test-git-namespaces
```

Then commit and push:
```bash
git add .gitmodules
git commit -m "Update .gitmodules for GitHub namespaces"
GIT_NAMESPACE=main git push origin master:refs/heads/master
```

## Troubleshooting

### Authentication Errors

If you get "could not read Username" or "Host key verification failed":

**SSH:**
```bash
# Test SSH connection
ssh -T git@github.com

# Ensure your remote uses SSH
git remote set-url origin git@github.com:yarikoptic/test-git-namespaces.git
```

**HTTPS with Token:**
```bash
# Use personal access token
git remote set-url origin https://YOUR_TOKEN@github.com/yarikoptic/test-git-namespaces
```

### Push Rejected / Already Up-to-Date

This is normal if:
- The namespace already exists with the same content
- You're re-running the script

The script handles this gracefully and continues.

### Submodule Not Initialized

If submodules show as "not initialized":
```bash
git submodule update --init --recursive
```

## Files Generated

- `push-with-namespaces.sh` - Main push script
- `.gitmodules.github` - Updated .gitmodules for GitHub
- `NAMESPACE-PUSH-GUIDE.md` - This guide

## Benefits of Nested Namespaces

1. **Preserves hierarchy**: `main-repo/sub1` maintains logical structure
2. **Clear organization**: Easy to understand relationship between modules
3. **Git-native**: Uses built-in namespace feature
4. **Object sharing**: All namespaces share the same object store in the remote repository

## Namespace Structure Example

```
github.com/yarikoptic/test-git-namespaces
└── refs/namespaces/
    ├── main/                          (main repository)
    │   └── refs/heads/master
    ├── submodule1/                    (top-level submodule)
    │   └── refs/heads/master
    ├── main-repo/                     (top-level submodule)
    │   ├── refs/heads/master
    │   └── refs/namespaces/           (nested!)
    │       ├── sub1/
    │       │   └── refs/heads/master
    │       └── sub2/
    │           └── refs/heads/master
    └── test-main-clone/               (another top-level)
        ├── refs/heads/master
        └── refs/namespaces/
            ├── sub1/
            │   └── refs/heads/master
            └── sub2/
                └── refs/heads/master
```

## Next Steps

1. **Test locally** with `./push-with-namespaces.sh local_test test`
2. **Verify** namespace structure
3. **Push to GitHub** with `./push-with-namespaces.sh origin main`
4. **Update .gitmodules** if needed
5. **Share clone instructions** with collaborators

## Reference

- Git Namespaces: `man gitnamespaces`
- Git Remote Ext: `man git-remote-ext`
- Experiment docs: See other markdown files in this directory
