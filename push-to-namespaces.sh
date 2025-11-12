#!/bin/bash
# Script to push main repository and all submodules to GitHub using namespaces
# Each submodule path will have '/' replaced with '--' in the namespace name

set -e

GITHUB_REPO="origin"
MAIN_BRANCH="master"

echo "========================================="
echo "Pushing to GitHub with Git Namespaces"
echo "========================================="
echo ""

# Function to push a repository to a namespace
push_to_namespace() {
    local repo_path="$1"
    local namespace="$2"
    local branch="${3:-master}"
    
    echo "📦 Pushing $repo_path to namespace: $namespace"
    
    if [ -z "$repo_path" ]; then
        # Main repository
        GIT_NAMESPACE="$namespace" git push "$GITHUB_REPO" "$branch:refs/heads/$branch"
    else
        # Submodule
        git -C "$repo_path" remote add github_ns https://github.com/yarikoptic/test-git-namespaces 2>/dev/null || true
        GIT_NAMESPACE="$namespace" git -C "$repo_path" push github_ns "$branch:refs/heads/$branch"
    fi
    
    echo "✅ Successfully pushed $namespace"
    echo ""
}

# Push main repository
echo "1. Pushing main repository..."
push_to_namespace "" "main" "$MAIN_BRANCH"

# Get all submodules and push each to its namespace
echo "2. Pushing submodules..."

# Parse git submodule status output
git submodule status --recursive | while read -r commit path rest; do
    # Remove leading space and commit hash
    commit="${commit# }"
    
    # Replace '/' with '--' for namespace
    namespace="${path//\/\/--}"
    
    echo "Processing submodule: $path -> namespace: $namespace"
    
    # Check if submodule directory exists and has .git
    if [ -d "$path/.git" ] || [ -f "$path/.git" ]; then
        # Get the current branch or use master
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
echo "View namespaces on GitHub:"
echo "  git clone https://github.com/yarikoptic/test-git-namespaces temp-check"
echo "  cd temp-check"
echo "  git --git-dir=.git for-each-ref"
echo ""
