#!/bin/bash
# Force-push version with flattened namespaces (using --)
# WARNING: This will overwrite remote history - use with caution!
#
# Usage:
#   ./push-with-namespaces-force.sh <remote-name> [main-namespace]

set -e

REMOTE_NAME="${1:-origin}"
MAIN_NAMESPACE="${2:-main}"
MAIN_BRANCH="master"

SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0
declare -a FAILED_REPOS

echo "========================================"
echo "FORCE Push with Git Namespaces"
echo "⚠️  WARNING: Using --force"
echo "========================================"
echo "Remote: $REMOTE_NAME"
echo "Main namespace: $MAIN_NAMESPACE"
echo "Flattening nested paths with '--'"
echo ""

read -p "This will OVERWRITE remote history. Continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Aborted."
    exit 0
fi
echo ""

if ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
    echo "❌ Error: Remote '$REMOTE_NAME' not found"
    git remote -v
    exit 1
fi

REMOTE_URL=$(git remote get-url "$REMOTE_NAME")
echo "Remote URL: $REMOTE_URL"
echo ""

push_to_namespace() {
    local repo_path="$1"
    local namespace="$2"
    local branch="${3:-master}"
    local remote="$4"
    local display_name="${repo_path:-(main)}"
    
    echo "📦 $display_name"
    echo "   → namespace: $namespace (force)"
    
    local push_output
    local push_status
    
    if [ -z "$repo_path" ]; then
        push_output=$(GIT_NAMESPACE="$namespace" git push --force "$remote" "$branch:refs/heads/$branch" 2>&1)
        push_status=$?
    else
        local remote_url=$(git remote get-url "$remote")
        git -C "$repo_path" remote remove ns_push 2>/dev/null || true
        git -C "$repo_path" remote add ns_push "$remote_url"
        push_output=$(GIT_NAMESPACE="$namespace" git -C "$repo_path" push --force ns_push "$branch:refs/heads/$branch" 2>&1)
        push_status=$?
    fi
    
    if [ $push_status -eq 0 ]; then
        if echo "$push_output" | grep -q "Everything up-to-date"; then
            echo "   ⏭️  Already up-to-date"
            ((SKIP_COUNT++))
        else
            echo "   ✅ SUCCESS (forced)"
            ((SUCCESS_COUNT++))
        fi
    else
        echo "   ❌ FAILED"
        echo "$push_output" | head -5 | sed 's/^/      /'
        FAILED_REPOS+=("$display_name (namespace: $namespace)")
        ((FAIL_COUNT++))
        return 1
    fi
    
    echo ""
    return 0
}

echo "1️⃣  Force-pushing main repository..."
echo ""
push_to_namespace "" "$MAIN_NAMESPACE" "$MAIN_BRANCH" "$REMOTE_NAME" || true

echo "2️⃣  Force-pushing submodules..."
echo ""

while read -r commit_info path rest; do
    # Flatten path: replace / with --
    namespace="${path//\//--}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ -d "$path/.git" ] || [ -f "$path/.git" ]; then
        current_branch=$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")
        push_to_namespace "$path" "$namespace" "$current_branch" "$REMOTE_NAME" || true
    else
        echo "📦 $path - skipped (not initialized)"
        ((SKIP_COUNT++))
    fi
done < <(git submodule status --recursive)

echo "========================================"
echo "Summary"
echo "========================================"
echo ""
echo "✅ Successful pushes: $SUCCESS_COUNT"
echo "⏭️  Skipped: $SKIP_COUNT"
echo "❌ Failed: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo "Failed repositories:"
    for repo in "${FAILED_REPOS[@]}"; do
        echo "  - $repo"
    done
    exit 1
else
    echo "✅ All force-pushes completed!"
fi
echo ""
