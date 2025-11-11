# Git Namespaces Architecture Diagram

## Traditional Submodule Approach

```
GitHub/Remote Servers
┌─────────────────────────────────────────────────────────┐
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ main-repo    │  │ submodule1   │  │ submodule2   │  │
│  │ .git/        │  │ .git/        │  │ .git/        │  │
│  │              │  │              │  │              │  │
│  │ objects: 9   │  │ objects: 3   │  │ objects: 3   │  │
│  │              │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
         ↓                  ↓                  ↓
         └──────────────────┴──────────────────┘
                            ↓
                  3 separate repositories
                  Total storage: ~15 objects
                  (with potential duplication)
```

## Git Namespaces Approach

```
GitHub/Remote Server
┌─────────────────────────────────────────────────────────┐
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │ unified-repo.git (single repository)             │   │
│  │                                                   │   │
│  │  objects/  (shared object store)                 │   │
│  │  └── 18 objects total (no duplication!)          │   │
│  │                                                   │   │
│  │  refs/namespaces/                                │   │
│  │  ├── main/refs/heads/master    (9 objects)      │   │
│  │  ├── ns1/refs/heads/master     (3 objects)      │   │
│  │  └── ns2/refs/heads/master     (3 objects)      │   │
│  │                                                   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
└─────────────────────────────────────────────────────────┘
                            ↓
                  1 repository, 3 namespaces
                  Total storage: 18 objects
                  (optimal deduplication)
```

## Clone Behavior Comparison

### Traditional Clone (Gets All Objects)

```bash
git clone /path/to/unified-repo.git
```

```
bare-remote               clone
┌──────────────┐         ┌──────────────┐
│ objects (18) │ ══════> │ objects (18) │
│              │  ALL    │              │
│ ns1 refs     │ ══════> │ ns1 refs     │
│ ns2 refs     │ ══════> │ ns2 refs     │
│ main refs    │ ══════> │ main refs    │
└──────────────┘         └──────────────┘
```

### Namespace Clone with ext:: Protocol (Isolated)

```bash
git clone "ext::git --namespace=ns1 %s /path/to/unified-repo.git"
```

```
bare-remote               clone-ns1
┌──────────────┐         ┌──────────────┐
│ objects (18) │         │ objects (3)  │
│   3 ns1 ─────│ ══════> │              │
│   3 ns2      │  ONLY   │ refs/heads/  │
│   9 main     │  ns1    │   master     │
│ ns1 refs ────│ ══════> │              │
└──────────────┘         └──────────────┘
```

## Submodule Integration Flow

### Step 1: Main Repo .gitmodules

```
main-repo/.gitmodules
┌────────────────────────────────────────────────┐
│ [submodule "sub1"]                             │
│   path = sub1                                  │
│   url = ext::git --namespace=ns1 %s REPO ─┐   │
│                                             │   │
│ [submodule "sub2"]                          │   │
│   path = sub2                               │   │
│   url = ext::git --namespace=ns2 %s REPO ─┐│   │
└─────────────────────────────────────────────┼┼──┘
                                              ││
                                              ││
                                              ││
### Step 2: Submodule Clone Flow                ││
                                              ││
unified-repo.git                              ││
┌────────────────────────────────┐            ││
│ refs/namespaces/               │            ││
│   ├── ns1/refs/heads/master ◄──┼────────────┘│
│   ├── ns2/refs/heads/master ◄──┼─────────────┘
│   └── main/refs/heads/master   │
└────────────────────────────────┘
         │                │
         │ 3 objects      │ 3 objects
         ↓                ↓
    ┌────────┐       ┌────────┐
    │  sub1/ │       │  sub2/ │
    │ (ns1)  │       │ (ns2)  │
    └────────┘       └────────┘
```

### Step 3: Final Structure After Submodule Init

```
my-project/
├── .git/              (9 objects - main repo)
├── .gitmodules        (namespace URLs)
├── README.md
│
├── sub1/              
│   └── .git/          (3 objects - only ns1)
│       └── No access to ns2 objects! ✅
│
└── sub2/
    └── .git/          (3 objects - only ns2)
        └── No access to ns1 objects! ✅
```

## Namespace Hierarchy Visualization

```
bare-remote/refs/namespaces/
│
├── main/
│   └── refs/heads/master → c10c0f1 (main project commit)
│
├── ns1/
│   └── refs/heads/master → 4e44a56 (submodule1 commit)
│
├── ns2/
│   └── refs/heads/master → e854341 (submodule2 commit)
│
└── myproject/
    └── refs/namespaces/libs/
        └── refs/namespaces/nested/
            └── refs/heads/master → 6aa6ebc (nested submodule)
```

## Object Flow During Clone

### Without Namespaces (Traditional)

```
User wants submodule1 content
                ↓
        Clone entire repo
                ↓
    Get objects: 1,2,3,4,5,6,...,18
                ↓
        Use only: 1,2,3
        Waste:    4,5,6,...,18 ❌
```

### With Namespaces (ext:: protocol)

```
User wants submodule1 content
                ↓
    Clone with namespace=ns1
                ↓
        Git fetch analyzes:
        - What refs exist in ns1?
        - What objects are reachable?
                ↓
    Get objects: 1,2,3 only
                ↓
        Use:     1,2,3
        Waste:   none ✅
```

## Security Model

```
ext:: Protocol Chain
┌──────────────────────────────────────────────────┐
│                                                    │
│  git clone "ext::git --namespace=ns1 %s REPO"    │
│                                                    │
│  ┌─────────────┐                                  │
│  │ git (user)  │                                  │
│  └─────┬───────┘                                  │
│        │ executes                                 │
│        ↓                                          │
│  ┌─────────────────────────────┐                 │
│  │ git --namespace=ns1 REPO    │                 │
│  │ (as subprocess)             │                 │
│  └─────────────────────────────┘                 │
│        │                                          │
│        │ Potential security risk if REPO is      │
│        │ untrusted or contains malicious code    │
│        ↓                                          │
│  Must enable with:                                │
│  -c protocol.ext.allow=always                    │
│                                                    │
└──────────────────────────────────────────────────┘
```

## Summary Comparison Table

| Aspect | Traditional | Namespaces |
|--------|-------------|------------|
| Repositories | Multiple (3+) | Single |
| Object Duplication | Possible | Minimized |
| Clone Isolation | N/A | ✅ With ext:: |
| Setup Complexity | Simple | Moderate |
| Tool Support | Universal | Limited |
| GitHub Support | Native | Via namespaces |
| Security | Standard | ext:: risks |
| Best For | Public OSS | Internal monorepos |
