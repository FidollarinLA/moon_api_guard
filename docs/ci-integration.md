# CI Integration

This document shows how to guard public API changes in GitHub Actions and GitLink CI by keeping a committed baseline `.mbti` snapshot and comparing every pull request against it.

## Workflow

1. Commit a baseline interface snapshot, for example `baseline/pkg.generated.mbti`.
2. On each pull request, run `moon info` to regenerate the current `pkg.generated.mbti`.
3. Run `moon_api_guard check baseline/pkg.generated.mbti pkg.generated.mbti`.
4. Fail the pipeline when breaking changes are detected.

This repository already includes:

- Baseline snapshot: `baseline/pkg.generated.mbti`
- Example workflow: `.github/workflows/api-guard.yml`
- Runnable checker: `moon run cmd/main -- check ...`

## GitHub Actions

Copy this workflow or reuse the included file:

```yaml
name: API Guard

on:
  pull_request:

jobs:
  api-guard:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - name: Set up MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
          echo "$HOME/.moon/bin" >> "$GITHUB_PATH"

      - name: Regenerate current interface snapshot
        run: moon info

      - name: Compare API against baseline
        run: moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti
```

When you intentionally change the public API, update the baseline in the same pull request:

```bash
moon info
cp pkg.generated.mbti baseline/pkg.generated.mbti
git add baseline/pkg.generated.mbti pkg.generated.mbti
```

## GitLink CI

GitLink CI uses the same commands. A typical pipeline stage looks like:

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
export PATH="$HOME/.moon/bin:$PATH"

moon version --all
moon info
moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti
```

Recommended stage order in an existing pipeline:

1. `moon check`
2. `moon test`
3. `moon build`
4. `moon info`
5. `moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti`

Exit codes from the checker:

| Code | Meaning |
| --- | --- |
| `0` | No breaking API changes |
| `1` | Breaking API changes detected |
| `2` | Invalid usage or unreadable input file |

## Local pre-push check

```bash
moon info
moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti
```

To inspect human-readable output and machine-readable JSON at the same time:

```bash
moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti | tee api-guard.log
```

The JSON summary includes a `changes` array with `category`, `detail`, `kind`, `name`, and `message` for each finding.
