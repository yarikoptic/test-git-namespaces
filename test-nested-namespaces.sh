#!/bin/bash
set -e

echo "=== Testing Nested Namespace Hierarchy ==="

# Create a nested namespace structure
BARE_REPO="$PWD/bare-remote"

# Create a nested submodule
mkdir -p nested-sub
cd nested-sub
git init
echo "Nested submodule content" > nested.txt
git add nested.txt
git commit -m "Nested submodule initial commit"

# Push to nested namespace
git remote add bare "$BARE_REPO"
GIT_NAMESPACE=myproject/libs/nested git push bare master:refs/heads/master
cd ..

echo ""
echo "=== Verifying Nested Namespace Structure ==="
git --git-dir="$BARE_REPO" for-each-ref | grep myproject

echo ""
echo "=== Testing Clone from Nested Namespace ==="
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=myproject/libs/nested %s $BARE_REPO" \
  clone-nested

echo ""
echo "Content from nested namespace clone:"
cat clone-nested/nested.txt

echo ""
echo "=== Namespace Hierarchy ==="
echo "Nested namespaces create hierarchical structure:"
git --git-dir="$BARE_REPO" show-ref | grep myproject || echo "No myproject refs yet"

echo ""
echo "✅ Nested namespace test complete!"
