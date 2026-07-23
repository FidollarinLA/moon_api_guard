# CI Guard Example

This example shows the intended release-guard loop:

```bash
# 1. regenerate current interface
moon info

# 2. fail CI on breaking public API changes
moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti \
  --breaking-only --format json

# 3. when the change is intentional, refresh the baseline in the same PR
moon run cmd/main -- baseline update pkg.generated.mbti baseline/pkg.generated.mbti
```

Directory-wide check (multiple packages / snapshots):

```bash
moon run cmd/main -- check-dir fixtures/dir_old fixtures/dir_new --format markdown
```

Rule rationale: see [docs/rules.md](../docs/rules.md).
