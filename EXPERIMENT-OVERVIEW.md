# Complete Experiment Overview

## What We Built

A complete demonstration of git namespaces for managing submodule hierarchies in a single repository.

## Directory Structure

```
git-ns-experiment/
│
├── Documentation
│   ├── SUMMARY.md              # Executive summary and conclusion
│   ├── FINDINGS.md             # Detailed technical findings
│   ├── GITHUB-WORKFLOW.md      # GitHub integration guide
│   └── README.md               # Quick start guide
│
├── Source Repositories
│   ├── submodule1/             # Source for namespace ns1
│   │   └── file1.txt          # "Content for submodule 1"
│   ├── submodule2/             # Source for namespace ns2
│   │   └── file2.txt          # "Content for submodule 2"
│   ├── nested-sub/             # Source for nested namespace
│   │   └── nested.txt         # "Nested submodule content"
│   └── main-repo/              # Main project with .gitmodules
│       ├── README.md
│       ├── .gitmodules        # Uses ext:: protocol for namespaces
│       ├── sub1/              # → points to ns1
│       └── sub2/              # → points to ns2
│
├── Central Repository
│   └── bare-remote/            # Single bare repo with all namespaces
│       └── refs/namespaces/
│           ├── ns1/refs/heads/master
│           ├── ns2/refs/heads/master
│           ├── main/refs/heads/master
│           └── myproject/libs/nested/refs/heads/master
│
├── Test Clones
│   ├── clone-ns1/              # Direct clone (gets ALL objects)
│   ├── clone-ns1-ext/          # ext:: clone (isolated objects) ✅
│   ├── test-clone-ns2/         # GIT_NAMESPACE clone
│   ├── test-main-clone/        # Full demo with submodules
│   │   ├── sub1/              # ✅ Only has ns1 objects
│   │   └── sub2/              # ✅ Only has ns2 objects
│   └── clone-nested/           # Nested namespace test
│
└── Scripts
    └── test-nested-namespaces.sh  # Automated nested namespace test
```

## Key Demonstrations

### 1. Basic Namespace Storage
**Location:** `bare-remote/`
**Shows:** Single repository storing multiple namespace refs

```bash
git --git-dir=bare-remote for-each-ref
```

Output:
```
refs/namespaces/main/refs/heads/master
refs/namespaces/ns1/refs/heads/master
refs/namespaces/ns2/refs/heads/master
refs/namespaces/myproject/refs/namespaces/libs/refs/namespaces/nested/refs/heads/master
```

### 2. Namespace-Aware .gitmodules
**Location:** `main-repo/.gitmodules`
**Shows:** How to reference namespaces in submodule URLs

```gitmodules
[submodule "sub1"]
    path = sub1
    url = ext::git --namespace=ns1 %s /path/to/bare-remote
[submodule "sub2"]
    path = sub2
    url = ext::git --namespace=ns2 %s /path/to/bare-remote
```

### 3. Object Isolation Verification
**Location:** `test-main-clone/`
**Shows:** Each submodule only has its own objects

Test in `sub1`:
```bash
cd test-main-clone/sub1
git cat-file -t $(git -C ../sub2 rev-parse HEAD)
# Result: fatal: git cat-file: could not get object info ✅
```

This proves sub1 doesn't have sub2's commit!

### 4. Nested Namespace Hierarchy
**Location:** `clone-nested/`
**Shows:** Multi-level namespace paths work

```bash
GIT_NAMESPACE=myproject/libs/nested
# Creates hierarchical ref path
```

## Quick Start Commands

### View All Namespaces
```bash
cd git-ns-experiment
git --git-dir=bare-remote for-each-ref
```

### Clone from Specific Namespace
```bash
git -c protocol.ext.allow=always clone \
  "ext::git --namespace=ns1 %s $PWD/bare-remote" \
  my-clone
```

### Clone Main Project with Submodules
```bash
# Clone main project
GIT_NAMESPACE=main git clone bare-remote my-project
cd my-project

# Initialize submodules (gets isolated objects per namespace!)
git -c protocol.ext.allow=always submodule update --init --recursive
```

### Run Nested Namespace Test
```bash
cd git-ns-experiment
./test-nested-namespaces.sh
```

## What This Proves

✅ **Feasibility**: Git namespaces CAN manage submodule hierarchies
✅ **Object Isolation**: ext:: protocol provides proper isolation on clone
✅ **Same Repository**: All content in single bare repository
✅ **Hierarchical**: Supports nested namespace organization
✅ **GitHub Compatible**: Can push/pull from GitHub
✅ **Selective Clone**: Each submodule gets only needed objects

## Object Count Comparison

| Repository | Object Count | Contains |
|------------|--------------|----------|
| bare-remote | 18 | All objects from all namespaces |
| test-main-clone | 18 | Main repo + all submodule objects |
| test-main-clone/sub1 | 3 (packed) | Only ns1 objects ✅ |
| test-main-clone/sub2 | 3 (packed) | Only ns2 objects ✅ |
| clone-ns1-ext | 3 | Only ns1 objects ✅ |

## Security Consideration

The `ext::` protocol executes git commands:
- Only use with **trusted repositories**
- Configure via: `git -c protocol.ext.allow=always`
- Consider security implications for your use case

## Next Steps

To experiment further:
1. Modify content in submodule1 or submodule2
2. Push to different namespaces
3. Clone and verify isolation
4. Try with GitHub repository (if you have access)

## References

- Git documentation: `man gitnamespaces`
- Git remote ext: `man git-remote-ext`
- All findings: `FINDINGS.md`
- GitHub workflow: `GITHUB-WORKFLOW.md`
