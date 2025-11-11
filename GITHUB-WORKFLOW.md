# Using Git Namespaces with GitHub

## Overview

Git namespaces can be pushed to and pulled from GitHub, allowing you to store multiple submodule repositories in a single GitHub repository.

## Setup on GitHub

### 1. Push Namespaced Refs

Each namespace can be pushed independently:

```bash
# Push submodule1 to namespace ns1
cd submodule1
git remote add github git@github.com:username/unified-repo.git
GIT_NAMESPACE=ns1 git push github master:refs/heads/master

# Push submodule2 to namespace ns2
cd ../submodule2
git remote add github git@github.com:username/unified-repo.git
GIT_NAMESPACE=ns2 git push github master:refs/heads/master

# Push main project to namespace main
cd ../main-repo
git remote add github git@github.com:username/unified-repo.git
GIT_NAMESPACE=main git push github master:refs/heads/master
```

### 2. Verify on GitHub

On GitHub, the refs will appear as:
- `refs/namespaces/ns1/refs/heads/master`
- `refs/namespaces/ns2/refs/heads/master`
- `refs/namespaces/main/refs/heads/master`

Note: GitHub's web interface won't show these as separate branches, but they exist in the ref namespace.

## Cloning from GitHub

### Clone Main Project

```bash
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=main %s https://github.com/username/unified-repo.git" \
  my-project
```

### Initialize Submodules

If your `.gitmodules` uses namespace URLs:

```gitmodules
[submodule "lib1"]
    path = lib1
    url = ext::git --namespace=ns1 %s https://github.com/username/unified-repo.git
[submodule "lib2"]
    path = lib2
    url = ext::git --namespace=ns2 %s https://github.com/username/unified-repo.git
```

Then:

```bash
cd my-project
git -c protocol.ext.allow=always submodule update --init --recursive
```

## Using git-remote-ext Helper

For repeated clones, you can configure git to allow ext protocol for specific hosts:

```bash
# In ~/.gitconfig or .git/config
[protocol "ext"]
    allow = always
```

Or use a wrapper script:

```bash
#!/bin/bash
# clone-namespaced.sh
NAMESPACE="$1"
REPO="$2"
DEST="$3"

git -c protocol.ext.allow=always clone \
  "ext::git --namespace=$NAMESPACE %s $REPO" \
  "$DEST"
```

Usage:
```bash
./clone-namespaced.sh ns1 https://github.com/username/repo.git my-lib
```

## Verifying Namespace Isolation

After cloning submodules, verify each has only its own objects:

```bash
cd my-project/lib1
LIB2_COMMIT=$(git -C ../lib2 rev-parse HEAD)
git cat-file -t $LIB2_COMMIT
# Should fail: fatal: git cat-file: could not get object info
```

This confirms lib1 doesn't have lib2's objects.

## Advantages of This Approach

1. **Single Repository on GitHub**: No need for multiple repos
2. **Reduced Storage**: Common objects stored once
3. **Simplified Management**: One repository to manage permissions/settings
4. **Atomic Updates**: Can update multiple namespaces in single push

## Limitations and Considerations

### Security

The `ext::` protocol executes git commands, which could be a security risk:
- Only use with trusted repositories
- Consider restricting via `protocol.ext.allow` configuration
- Document requirements for team members

### User Experience

- Non-standard workflow requires documentation
- Git UIs (GitHub Desktop, GitKraken, etc.) may not support ext:: URLs
- Team members need to understand namespace concept

### Alternative: Separate GitHub Repos

For public projects or teams unfamiliar with namespaces, consider:
- Separate GitHub repositories (standard approach)
- Use git submodules normally
- Accept the duplication of common objects

## Advanced: HTTP Backend with Namespaces

For HTTP access, you can configure git-http-backend to expose namespaces:

Apache configuration:
```apache
SetEnv GIT_NAMESPACE myproject/lib1
ScriptAlias /git/lib1/ /usr/lib/git-core/git-http-backend/
```

This allows:
```bash
git clone https://example.com/git/lib1/ lib1
```

But requires server-side configuration, not available on GitHub.

## Recommendation

✅ **Use for**: Internal projects, monorepos, advanced users
⚠️ **Avoid for**: Public OSS, teams unfamiliar with git internals, CI/CD without ext:: support

For most projects, separate repositories remain the simpler, more standard approach.
