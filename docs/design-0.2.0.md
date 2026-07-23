# moon_api_guard 0.2.0 Design — Engineering Product

**Goal:** Turn moon_api_guard into a daily-usable release guard (check / check-dir / baseline update / CI).

**Status:** Approved for implementation (Approach A). Deeper semantic rules deferred.

## CLI

```text
check <old.mbti> <new.mbti> [--format text|markdown|json] [--breaking-only]
check-dir <old_dir> <new_dir> [--format ...] [--breaking-only]
baseline update <current.mbti> <baseline.mbti>
help
```

Exit codes: `0` no breaking, `1` breaking, `2` usage/IO error.

## Library (pure)

- `ApiReport::breaking_only()` — filter to breaking changes only
- `ApiReport::scoped(scope)` — prefix change names with `scope::`
- `merge_api_reports(reports)` — concatenate changes into one report

Directory walking and file IO stay in the CLI package.

## check-dir rules

- Recursively collect `*.mbti` under both roots
- Match by relative path
- Both sides: `compare_mbti_content`, then `scoped(rel_path)`
- Only old: breaking `file-removed`
- Only new: compatible `file-added`

## Docs / CI / release

- `docs/rules.md`, `CHANGELOG.md`, `examples/ci-guard`
- CI matrix: ubuntu-latest + macos-latest
- Publish `0.2.0` to mooncakes.io; sync GitHub + GitLink
