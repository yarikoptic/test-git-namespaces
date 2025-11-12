# Push Troubleshooting Guide

## The "fetch first" Error

### What You Saw

```
! [rejected]        master -> master (fetch first)
error: failed to push some refs
```

### What This Means

The remote repository already has a ref at that namespace location with **different history**. This happens when:

1. You previously pushed to these namespaces with different content
2. Someone else pushed to these namespaces
3. The remote has these refs from a previous experiment

### Solutions

## Option 1: Clean Slate (Recommended if this is a fresh repository)

If the GitHub repository should start fresh, you can delete the namespace refs and push again:

```bash
# Delete all namespace refs from remote (CAREFUL!)
git push origin --delete refs/namespaces/clone-ns1-ext/refs/heads/master
git push origin --delete refs/namespaces/main-repo/refs/heads/master
# ... repeat for each rejected namespace

# Then push again
./push-with-namespaces.sh origin main
```

## Option 2: Force Push (OVERWRITES REMOTE)

If you want to **overwrite** the remote with your local content:

```bash
# Use the force-push script
./push-with-namespaces-force.sh origin main
```

**WARNING:** This overwrites remote history. Only use if you're sure!

## Option 3: Investigate First

See what's currently in the remote namespaces:

```bash
# List all namespace refs on GitHub
git ls-remote origin 'refs/namespaces/*'

# Clone and inspect a specific namespace
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=clone-ns1-ext %s https://github.com/yarikoptic/test-git-namespaces" \
  temp-check

cd temp-check
git log
```

## Fixed Script Behavior

The new `push-with-namespaces.sh` now:

✅ **Properly detects push failures**
- Checks exit status of git push
- Shows specific error type
- Provides hints for resolution

✅ **Provides accurate summary**
```
✅ Successful pushes: X
⏭️  Already up-to-date: Y  
❌ Failed pushes: Z

Failed repositories:
  - clone-ns1-ext (namespace: clone-ns1-ext)
  - main-repo (namespace: main-repo)
```

✅ **Exits with error code** if any pushes fail

## Testing the Fixed Script

Test locally first:

```bash
# Test push
./push-with-namespaces.sh local_test experiment

# Check results
echo "Exit code: $?"

# Verify what was pushed
git --git-dir=bare-remote for-each-ref | grep experiment
```

## Recommended Workflow

1. **First time setup:**
   ```bash
   # Push to GitHub
   ./push-with-namespaces.sh origin main
   ```

2. **If you get "fetch first" errors:**
   
   **Option A - Start fresh (if repository is new):**
   ```bash
   # Use force push
   ./push-with-namespaces-force.sh origin main
   ```
   
   **Option B - Selective cleanup (if some namespaces are okay):**
   ```bash
   # Delete only problematic namespaces
   git push origin --delete refs/namespaces/NAMESPACE_NAME/refs/heads/master
   
   # Push again
   ./push-with-namespaces.sh origin main
   ```

3. **Verify results:**
   ```bash
   # Check what's on GitHub
   git ls-remote origin 'refs/namespaces/*' | wc -l
   # Should match your number of modules + main
   ```

## Understanding the Error

When you see:
```
! [rejected]        master -> master (fetch first)
```

Git is saying: "The remote has commits at this ref that you don't have locally."

For namespaces, this usually means:
- The namespace exists with different content
- Previous experiment data is there
- Need to decide: merge, overwrite, or investigate?

## Quick Decision Tree

```
Do you care about what's already in the remote namespace?
│
├─ NO: Use ./push-with-namespaces-force.sh origin main
│      (Overwrites everything)
│
└─ YES: 
   ├─ Clone and inspect the namespace
   ├─ Decide if you want to merge or replace
   └─ Use appropriate git commands
```

## Files Available

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `push-with-namespaces.sh` | Safe push with error detection | First attempt, normal updates |
| `push-with-namespaces-force.sh` | Force overwrite remote | "fetch first" errors, fresh start |

## Summary

**The fixed script now:**
- ✅ Accurately reports success/failure
- ✅ Shows clear error messages
- ✅ Exits with error code on failure
- ✅ Provides actionable hints

**Your next step:**
```bash
# If you want to overwrite GitHub namespaces
./push-with-namespaces-force.sh origin main

# Or investigate first
git ls-remote origin 'refs/namespaces/*'
```
