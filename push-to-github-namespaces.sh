#!/bin/bash
# Script to push git-ns-experiment and all submodules to GitHub using namespaces
# Uses nested namespaces for hierarchical submodules (e.g., main-repo/sub1)

set -e

GITHUB_REPO="https://github.com/yarikoptic/test-git-namespaces"
MAIN_BRANCH="master"

echo "========================================="
echo "Pushing to GitHub with Git Namespaces"
echo "Repository: $GITHUB_REPO"
echo "Using nested namespaces for hierarchy"
echo "========================================="
echo ""

# Function to push a repository to a namespace
push_to_namespace() {
    local repo_path="$1"
    local namespace="$2"
    local branch="${3:-master}"
    
    echo "📦 Pushing: $repo_path"
    echo "   Namespace: $namespace"
    echo "   Branch: $branch"
    
    if [ -z "$repo_path" ]; then
        # Main repository
        GIT_NAMESPACE="$namespace" git push "$GITHUB_REPO" "$branch:refs/heads/$branch"
    else
        # Submodule - add remote if it doesn't exist
        git -C "$repo_path" remote remove github_ns 2>/dev/null || true
        git -C "$repo_path" remote add github_ns "$GITHUB_REPO"
        
        # Push to namespace
        GIT_NAMESPACE="$namespace" git -C "$repo_path" push github_ns "$branch:refs/heads/$branch"
    fi
    
    echo "   ✅ Success!"
    echo ""
}

# Push main repository
echo "1️⃣  Pushing main repository..."
push_to_namespace "" "main" "$MAIN_BRANCH"

# Get all submodules and push each to its namespace
echo "2️⃣  Pushing submodules..."
echo ""

# Parse git submodule status output
git submodule status --recursive | while read -r commit_info path rest; do
    # Remove leading space from commit
    commit="${commit_info# }"
    
    # Use path directly as namespace (preserving /)
    namespace="$path"
    
    echo "Processing: $path → namespace: $namespace"
    
    # Check if submodule directory exists and has .git
    if [ -d "$path/.git" ] || [ -f "$path/.git" ]; then
        # Get the current branch
        current_branch=$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")
        
        push_to_namespace "$path" "$namespace" "$current_branch"
    else
        echo "⚠️  Skipping $path - not initialized"
        echo ""
    fi
done

echo "========================================="
echo "✅ All repositories pushed successfully!"
echo "========================================="
echo ""
echo "Namespace structure created:"
echo "  main → main repository"
echo "  submodule1 → top-level submodule"
echo "  main-repo/sub1 → nested namespace"
echo "  (refs/namespaces/main-repo/refs/namespaces/sub1/)"
echo ""
echo "View all namespaces:"
echo "  git ls-remote $GITHUB_REPO 'refs/namespaces/*'"
echo ""
