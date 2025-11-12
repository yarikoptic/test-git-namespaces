# How to Push with Namespaces

## The Safe Script (No Forcing)

```bash
./push-with-namespaces.sh origin main
```

This script:
- ✅ Uses flattened namespaces (`--` separator for GitHub)
- ✅ Reports errors accurately
- ✅ Does NOT force-push
- ✅ Exits with error code on failures
- ✅ Continues with remaining submodules if one fails

## What Happens

The script will push:
1. Main repository to namespace `main`
2. Each submodule to its flattened namespace:
   - `submodule1` → `submodule1`
   - `main-repo` → `main-repo`
   - `main-repo/sub1` → `main-repo--sub1` (flattened!)
   - `main-repo/sub2` → `main-repo--sub2` (flattened!)

## If You Get "fetch first" Errors

This means a namespace already exists with different content. You have options:

### Option 1: Delete Specific Namespaces

```bash
# Delete the conflicting namespace
git push origin --delete refs/namespaces/NAMESPACE_NAME/refs/heads/master

# Example: Delete main-repo--sub1 namespace
git push origin --delete refs/namespaces/main-repo--sub1/refs/heads/master

# Then push again
./push-with-namespaces.sh origin main
```

### Option 2: Delete All Namespaces and Start Fresh

```bash
# List all namespaces
git ls-remote origin 'refs/namespaces/*'

# Delete each one
git ls-remote origin 'refs/namespaces/*' | while read hash ref; do
    git push origin --delete "$ref"
done

# Then push
./push-with-namespaces.sh origin main
```

### Option 3: Investigate First

```bash
# See what's in a namespace
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=main-repo--sub1 %s https://github.com/yarikoptic/test-git-namespaces" \
  temp-check

cd temp-check
git log
```

## Expected Output

### Success
```
📦 main-repo/sub1
   → namespace: main-repo--sub1
   → branch: master
   Running: GIT_NAMESPACE=main-repo--sub1 git -C main-repo/sub1 push ns_push master:refs/heads/master
   ✅ SUCCESS
```

### Already Up-to-Date
```
📦 submodule1
   → namespace: submodule1
   → branch: master
   Running: GIT_NAMESPACE=submodule1 git -C submodule1 push ns_push master:refs/heads/master
   ⏭️  Already up-to-date
```

### Error (Different History)
```
📦 clone-ns1
   → namespace: clone-ns1
   → branch: master
   Running: GIT_NAMESPACE=clone-ns1 git -C clone-ns1 push ns_push master:refs/heads/master
   ❌ FAILED: Remote has different history
   Namespace 'clone-ns1' already exists with different content
   Error output:
      To github.com:yarikoptic/test-git-namespaces
      ! [rejected]        master -> master (fetch first)
```

## Final Summary

The script will show:
```
========================================
Summary
========================================

✅ Successful pushes: 10
⏭️  Already up-to-date: 2
❌ Failed pushes: 1

Failed repositories:
  - clone-ns1 (namespace: clone-ns1)

❌ Push completed with ERRORS
```

## After Successful Push

Verify on GitHub:
```bash
git ls-remote origin 'refs/namespaces/*'
```

You should see flattened namespaces:
```
refs/namespaces/main/refs/heads/master
refs/namespaces/main-repo--sub1/refs/heads/master
refs/namespaces/main-repo--sub2/refs/heads/master
```

## Quick Reference

```bash
# Push to GitHub
./push-with-namespaces.sh origin main

# Check exit code
echo $?  # 0 = success, 1 = had errors

# View what's on GitHub
git ls-remote origin 'refs/namespaces/*'

# Delete a namespace if needed
git push origin --delete refs/namespaces/NAME/refs/heads/master
```

## You're in Control

This script:
- ❌ Does NOT force-push
- ✅ Reports exactly what succeeded/failed
- ✅ Lets you decide how to handle conflicts
- ✅ Uses safe, standard git push
