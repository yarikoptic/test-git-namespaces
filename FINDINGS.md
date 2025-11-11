# Git Namespaces for Submodule Hierarchies - Findings

## Summary

Git namespaces CAN be used to store multiple submodules in the same repository while maintaining object isolation during clone operations, using the `ext::` protocol in `.gitmodules`.

## Key Findings

### 1. Namespace Basics
- Namespaces are stored under `refs/namespaces/<name>/refs/`
- Set via `GIT_NAMESPACE` environment variable or `--namespace` flag
- Operations within a namespace see refs from ALL namespaces but can only modify their own

### 2. Object Storage
- **Objects are shared** across all namespaces in the same physical repository
- This avoids duplication when multiple namespaces have common history
- However, during clone with namespace specification, only required objects are fetched

### 3. Submodule Integration with Namespaces

#### Using ext:: Protocol in .gitmodules
```gitmodules
[submodule "sub1"]
    path = sub1
    url = ext::git --namespace=ns1 %s /path/to/bare-remote
[submodule "sub2"]
    path = sub2
    url = ext::git --namespace=ns2 %s /path/to/bare-remote
```

#### Cloning Behavior
When cloning with namespace-aware URLs:
- Each submodule only fetches objects reachable from its namespace
- Other namespace objects are NOT transferred
- This provides effective isolation despite shared object store

### 4. Protocol Configuration Required
- The `ext::` protocol must be explicitly allowed: `-c protocol.ext.allow=always`
- This is a security feature since ext:// can execute arbitrary commands

## Tested Scenarios

### Scenario 1: Basic Namespace Clone
```bash
GIT_NAMESPACE=ns1 git clone /path/to/bare-remote clone-ns1
```
Result: Gets refs from ns1 namespace but ALL objects

### Scenario 2: Clone with ext:: Protocol
```bash
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=ns1 %s /path/to/bare-remote" \
  clone-ns1-ext
```
Result: Gets only objects reachable from ns1 refs

### Scenario 3: Submodules from Same Repo, Different Namespaces
Main repo `.gitmodules`:
```
[submodule "sub1"]
    url = ext::git --namespace=ns1 %s /bare-repo
[submodule "sub2"]
    url = ext::git --namespace=ns2 %s /bare-repo
```

Command:
```bash
git -c protocol.ext.allow=always submodule update --init --recursive
```

Result: ✅ Each submodule gets only its namespace objects!

## Advantages

1. **Single Repository**: All submodule content in one repo
2. **Object Sharing**: Common history stored once in bare repo
3. **Selective Clone**: Each submodule clone gets only needed objects
4. **GitHub Compatible**: Can push namespaced refs to GitHub

## Limitations

1. **ext:: Protocol Required**: Must enable potentially dangerous protocol
2. **Not Standard**: Most git UIs don't support namespace URLs
3. **Security Concerns**: See gitnamespaces(7) documentation
4. **HTTP/SSH**: Namespace specification via protocol, not via URL path

## Recommendations

### For Local Development
✅ Excellent for monorepo with many submodules
✅ Reduces disk usage significantly
✅ Works well with bare repository as central storage

### For GitHub/Public Hosting
⚠️ Requires ext:: protocol on clone side
⚠️ Need to document setup for users
⚠️ Consider security implications

### Alternative Approaches
- Use separate repositories (standard approach)
- Use git alternates for object sharing
- Use shallow clones to reduce individual repo size

## Testing with GitHub

The repository structure can be pushed to GitHub:
```bash
# Push different namespaces
GIT_NAMESPACE=ns1 git push origin master:refs/heads/master
GIT_NAMESPACE=ns2 git push origin master:refs/heads/master
GIT_NAMESPACE=main git push origin master:refs/heads/master
```

However, cloning from GitHub with namespaces requires:
```bash
git clone "ext::git --namespace=ns1 %s https://github.com/user/repo.git"
```

## Nested Namespace Hierarchy

Git supports nested namespaces via `/` in namespace names:
- `GIT_NAMESPACE=project1/submod1` → `refs/namespaces/project1/refs/namespaces/submod1/`
- Allows organizing submodules hierarchically
- Could structure as: `main-project/submodule-name/version`

## Practical Example Structure

```
bare-remote (single repository)
├── refs/namespaces/myproject/refs/heads/master (main project)
├── refs/namespaces/myproject/lib1/refs/heads/master (submodule lib1)
├── refs/namespaces/myproject/lib2/refs/heads/master (submodule lib2)
└── refs/namespaces/myproject/lib3/refs/heads/master (submodule lib3)
```

With .gitmodules:
```
[submodule "lib1"]
    path = lib1
    url = ext::git --namespace=myproject/lib1 %s /path/to/bare-remote
```

## Conclusion

✅ **Feasible**: Yes, namespaces can contain entire hierarchies of submodules
✅ **Object Isolation on Clone**: Yes, with ext:: protocol
✅ **Same Repository**: Yes, all content in one physical repo
⚠️ **Practical for Production**: Depends on security policies and team familiarity with ext:: protocol

The approach works technically but requires careful consideration of security and usability trade-offs.
