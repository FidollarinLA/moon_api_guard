# moon_api_guard

`moon_api_guard` is a public API compatibility guard for [MoonBit](https://www.moonbitlang.com) packages.

## Repository

- **GitHub**: https://github.com/FidollarinLA/moon_api_guard
- **GitLink**: https://gitlink.org.cn/FidollarinLA/moon_api_guard

Both remotes stay in sync for OSC 2026 submission. Default branch: `main` (18 meaningful commits).

MoonBit already generates a formal interface snapshot for every package (the `.mbti` file produced by `moon info`). This project compares two of those snapshots — the previously released interface and the current one — and turns the differences into actionable signals:

- Which public APIs were **removed** or **changed** (breaking changes)?
- Which public APIs were **added** (compatible changes)?
- Should the next release be a **major**, **minor**, or **patch** version?
- Should CI **block the release** because of accidental breakage?

## Why

When a MoonBit package is published to [mooncakes.io](https://mooncakes.io), downstream users depend on its public interface. A renamed function or a changed signature silently breaks every consumer. `moon_api_guard` makes those changes explicit before they ship:

- **Pre-release check** — compare the released `.mbti` against the current one before publishing.
- **PR review** — surface API-breaking diffs in pull requests.
- **CI guard** — fail the pipeline when a breaking change lands without a major version bump.

## Quick Start

```bash
moon check
moon test
moon run cmd/main -- check fixtures/old_api.mbti fixtures/new_api.mbti
```

The CLI exits with code `1` when breaking changes are detected, and `0` when the public API is compatible.

## CLI

Compare two `.mbti` snapshots from the command line:

```bash
moon run cmd/main -- check path/to/old.mbti path/to/new.mbti
```

Exit codes:

| Code | Meaning |
| --- | --- |
| `0` | No breaking changes |
| `1` | Breaking changes detected (`release_blocked`) |
| `2` | Invalid usage or file read error |

Example CI usage:

```bash
moon info
moon run cmd/main -- check pkg.generated.mbti pkg.generated.mbti
# Or compare against a committed baseline:
moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti
```

## Library Usage

Compare two API snapshots and inspect the report:

```mbt nocheck
let old_api = @lib.parse_mbti_content(old_mbti_text)
let new_api = @lib.parse_mbti_content(new_mbti_text)
let report = @lib.compare_api(old_api, new_api)
println(report.breaking_count())
println(report.compatible_count())
println(report.semver_suggestion())
println(report.release_blocked())
```

Reports are also available in Markdown and JSON for humans and CI systems:

```mbt nocheck
println(report.markdown_summary())
// # moon_api_guard report
//
// - breaking: 1
// - compatible: 1
// - semver: major

println(report.json_summary())
// {"breaking":1,"compatible":1,"semver":"major","release_blocked":true,"changes":[...]}
```

Each change in JSON includes `category`, `detail`, `kind`, `name`, and `message`.

## CI Integration

This repository includes:

- Baseline snapshot: `baseline/pkg.generated.mbti`
- Example workflow: `.github/workflows/api-guard.yml`
- Copy-paste guide: [docs/ci-integration.md](docs/ci-integration.md)

Typical PR guard:

```bash
moon info
moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti
```

When you intentionally change the public API, update the baseline in the same pull request:

```bash
cp pkg.generated.mbti baseline/pkg.generated.mbti
```

## Core Concepts

| Type | Meaning |
| --- | --- |
| `ApiItem` | One normalized public API item (function, struct, enum, type, alias, trait, impl). |
| `ApiChange` | A single compatibility finding with `category`, `detail`, `kind`, `name`, and `message`. |
| `ApiReport` | The full comparison result, with counts, SemVer suggestion, release blocking signal, and Markdown/JSON summaries. |

Key functions:

- `parse_mbti_content(content)` — parse a full `.mbti` file into public API items.
- `parse_mbti_items(lines)` — parse public declarations from `.mbti` interface lines.
- `compare_api(old_items, new_items)` — diff two API snapshots into an `ApiReport`.
- `ApiReport::semver_suggestion()` — `major` / `minor` / `patch` recommendation.
- `ApiReport::release_blocked()` — `true` when breaking changes exist, for CI gating.

Breaking change details include:

- `return-type-changed`, `parameter-removed`, `parameter-added`, `parameter-changed`
- `visibility-tightened` (`pub(all)` → `pub`)
- `field-removed`, `field-added`, `field-type-changed`
- `method-removed`, `method-changed`
- `variant-removed`, `removed`

## Roadmap

- Publishing to mooncakes.io.
- More `.mbti` edge cases: generic bounds, deeply nested signatures.

## Development

```bash
moon fmt    # format code
moon check  # type check
moon test   # run tests
moon info   # regenerate .mbti interface files
moon coverage analyze  # inspect uncovered lines
```

CI runs all of the above and verifies that formatting and generated interfaces are up to date.

## License

Apache-2.0
