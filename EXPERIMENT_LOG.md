# Git Namespaces Experiment Log

## Current Setup

We have a bare repository at `bare-remote` with two namespaces:
- ns1: Contains submodule1 content (commit 4e44a56)
- ns2: Contains submodule2 content (commit e854341)

## Observations

### 1. Namespace Behavior
When using `--namespace=ns1`, git operations see:
