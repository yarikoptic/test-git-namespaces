#!/bin/bash
# Script to push repository and all submodules using namespaces
# Flattens nested paths using -- separator (e.g., main-repo/sub1 → main-repo--sub1)
# GitHub does not support nested namespaces, so we must flatten the hierarchy
#
# Usage:
#   ./push-with-namespaces.sh <remote-name> [main-namespace]
#
# Examples:
#   ./push-with-namespaces.sh origin main

set -e

# Configuration
REMOTE_NAME="${1:-origin}"
MAIN_NAMESPACE="${2:-main}"
MAIN_BRANCH="master"

# Counters for summary
SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0
declare -a FAILED_REPOS

echo "========================================"
echo "Push with Git Namespaces"
echo "========================================"
echo "Remote: $REMOTE_NAME"
echo "Main namespace: $MAIN_NAMESPACE"
echo "Flattening nested paths with '--'"
echo "  (e.g., main-repo/sub1 → main-repo--sub1)"
echo "========================================"
echo ""

# Check if remote exists
if ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
    echo "❌ Error: Remote '$REMOTE_NAME' not found"
    echo ""
    echo "Available remotes:"
    git remote -v
    exit 1
fi

REMOTE_URL=$(git remote get-url "$REMOTE_NAME")
echo "Remote URL: $REMOTE_URL"
echo ""

# Function to push a repository to a namespace
push_to_namespace() {
    local repo_path="$1"
    local namespace="$2"
    local branch="${3:-master}"
    local remote="$4"
    local display_name="${repo_path:-(main)}"
    
    echo "📦 $display_name"
    echo "   → namespace: $namespace"
    echo "   → branch: $branch"
    
    local push_output
    local push_status
    
    if [ -z "$repo_path" ]; then
        # Main repository - NO FORCE
        echo "   Running: GIT_NAMESPACE=$namespace git push $remote $branch:refs/heads/$branch"
        push_output=$(GIT_NAMESPACE="$namespace" git push "$remote" "$branch:refs/heads/$branch" 2>&1)
        push_status=$?
    else
        # Submodule - NO FORCE
        local remote_url=$(git remote get-url "$remote")
        
        # Ensure submodule has the remote
        git -C "$repo_path" remote remove ns_push 2>/dev/null || true
        git -C "$repo_path" remote add ns_push "$remote_url"
        
        # Push to namespace - NO FORCE
        echo "   Running: GIT_NAMESPACE=$namespace git -C $repo_path push ns_push $branch:refs/heads/$branch"
        push_output=$(GIT_NAMESPACE="$namespace" git -C "$repo_path" push ns_push "$branch:refs/heads/$branch" 2>&1)
        push_status=$?
    fi
    
    # Analyze the result
    if [ $push_status -eq 0 ]; then
        if echo "$push_output" | grep -q "Everything up-to-date"; then
            echo "   ⏭️  Already up-to-date"
            ((SKIP_COUNT++))
        else
            echo "   ✅ SUCCESS"
            ((SUCCESS_COUNT++))
        fi
    else
        # Check for specific error types
        if echo "$push_output" | grep -q "rejected.*fetch first"; then
            echo "   ❌ FAILED: Remote has different history"
            echo "   Namespace '$namespace' already exists with different content"
        elif echo "$push_output" | grep -q "rejected.*non-fast-forward"; then
            echo "   ❌ FAILED: Non-fast-forward push rejected"
        elif echo "$push_output" | grep -q "Authentication failed\|Permission denied"; then
            echo "   ❌ FAILED: Authentication error"
        else
            echo "   ❌ FAILED"
        fi
        
        # Show error details
        echo "   Error output:"
        echo "$push_output" | head -3 | sed 's/^/      /'
        
        FAILED_REPOS+=("$display_name (namespace: $namespace)")
        ((FAIL_COUNT++))
        
        return 1
    fi
    
    echo ""
    return 0
}

# Push main repository
echo "1️⃣  Pushing main repository..."
echo ""
push_to_namespace "" "$MAIN_NAMESPACE" "$MAIN_BRANCH" "$REMOTE_NAME" || {
    echo "⚠️  Main repository push failed - continuing with submodules..."
    echo ""
}

# Get all submodules and push each to its namespace
echo "2️⃣  Pushing submodules..."
echo ""

# Parse git submodule status output
while read -r commit_info path rest; do
    # Remove leading space/indicator from commit
    commit="${commit_info# }"
    commit="${commit#-}"
    commit="${commit#+}"
    
    # Flatten path: replace / with --
    namespace="${path//\//--}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if submodule directory exists and has .git
    if [ -d "$path/.git" ] || [ -f "$path/.git" ]; then
        # Get the current branch
        current_branch=$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")
        
        push_to_namespace "$path" "$namespace" "$current_branch" "$REMOTE_NAME" || {
            # Continue even if one submodule fails
            true
        }
    else
        echo "📦 $path"
        echo "   ⏭️  Skipping - not initialized"
        echo ""
        ((SKIP_COUNT++))
    fi
done < <(git submodule status --recursive)

echo "========================================"
echo "Summary"
echo "========================================"
echo ""
echo "✅ Successful pushes: $SUCCESS_COUNT"
echo "⏭️  Already up-to-date: $SKIP_COUNT"
echo "❌ Failed pushes: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo "Failed repositories:"
    for repo in "${FAILED_REPOS[@]}"; do
        echo "  - $repo"
    done
    echo ""
    echo "❌ Push completed with ERRORS"
    echo ""
    echo "To resolve conflicts, you can:"
    echo "  1. Delete conflicting namespace refs manually:"
    echo "     git push $REMOTE_NAME --delete refs/namespaces/NAMESPACE/refs/heads/master"
    echo "  2. Or investigate what's in the remote namespace"
    echo "  3. Then run this script again"
    echo ""
    exit 1
else
    echo "✅ All pushes completed successfully!"
    echo ""
fi

echo "View namespaces:"
if [[ "$REMOTE_URL" == http* ]] || [[ "$REMOTE_URL" == git@* ]]; then
    echo "  git ls-remote $REMOTE_NAME 'refs/namespaces/*'"
else
    echo "  git --git-dir=$REMOTE_URL for-each-ref | grep namespaces"
fi
echo ""
