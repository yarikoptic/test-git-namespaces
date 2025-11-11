# Git Namespaces Experiment

This directory contains a working demonstration of using git namespaces to store multiple submodules in a single repository.

## Directory Structure

```
git-ns-experiment/
├── bare-remote/           # Bare repository with multiple namespaces
├── submodule1/            # Source for namespace ns1
├── submodule2/            # Source for namespace ns2
├── main-repo/             # Main repository with submodules
├── test-main-clone/       # Clone demonstrating namespace-based submodules
├── clone-ns1/             # Direct clone from ns1
├── clone-ns1-ext/         # Clone using ext:: protocol
└── test-clone-ns2/        # Clone from ns2 namespace
```

## What's in the bare-remote Repository?

The bare repository contains three namespaces:

1. **ns1**: Contains submodule1 content
2. **ns2**: Contains submodule2 content  
3. **main**: Contains main project with references to ns1 and ns2 as submodules

View all refs:
```bash
git --git-dir=bare-remote for-each-ref
```

## Key Demonstration: Namespace-Based Submodules

The `main-repo/.gitmodules` file uses the `ext::` protocol to specify namespaces:

```gitmodules
[submodule "sub1"]
    path = sub1
    url = ext::git --namespace=ns1 %s /path/to/bare-remote
[submodule "sub2"]
    path = sub2
    url = ext::git --namespace=ns2 %s /path/to/bare-remote
```

## How to Test

### Clone from specific namespace
```bash
GIT_NAMESPACE=main git clone bare-remote test-clone
cd test-clone
```

### Initialize submodules (requires ext:: protocol)
```bash
git -c protocol.ext.allow=always submodule update --init --recursive
```

### Verify object isolation
```bash
# Check that sub1 doesn't have sub2's commit
cd sub1
git cat-file -t $(git -C ../sub2 rev-parse HEAD)
# Should fail: fatal: git cat-file: could not get object info
```

## Results

✅ Each submodule gets ONLY objects from its namespace
✅ All content stored in single bare repository
✅ Object sharing in bare repo reduces disk usage
✅ Selective cloning works correctly

See FINDINGS.md for complete analysis.
