# Start Here: Push to GitHub with Namespaces

## Quick Start

You've successfully logged in! Now you can push:

```bash
cd /workspace/git-ns-experiment
./push-with-namespaces.sh origin main
```

## What This Does

Pushes your repository and all submodules to GitHub using flattened namespaces:

- Main repo → namespace `main`
- `submodule1` → namespace `submodule1`  
- `main-repo/sub1` → namespace `main-repo--sub1` (flattened with `--`)
- `main-repo/sub2` → namespace `main-repo--sub2` (flattened with `--`)
- ... and all other submodules

## The Script is Safe

- ✅ No force-pushing
- ✅ Accurate error reporting
- ✅ GitHub-compatible flattening
- ✅ You stay in control

## If You Get Errors

The script will clearly show what failed:

```
❌ Failed pushes: 2

Failed repositories:
  - clone-ns1 (namespace: clone-ns1)
  - main-repo (namespace: main-repo)
```

Common cause: Those namespaces already exist with different content.

**Solution:** Delete conflicting namespaces:
```bash
# Delete one namespace
git push origin --delete refs/namespaces/clone-ns1/refs/heads/master

# Then try again
./push-with-namespaces.sh origin main
```

## After Successful Push

View your namespaces on GitHub:
```bash
git ls-remote origin 'refs/namespaces/*'
```

## More Details

- **Full usage guide:** `PUSH-USAGE.md`
- **GitHub limitations:** `GITHUB-NAMESPACE-LIMITATION.md`
- **Troubleshooting:** `PUSH-TROUBLESHOOTING.md`

---

**Ready?** Run:
```bash
./push-with-namespaces.sh origin main
```
