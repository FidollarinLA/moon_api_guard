# moon_api_guard

`moon_api_guard` is a public API compatibility guard for [MoonBit](https://www.moonbitlang.com) packages.

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

Check, test, and run the bundled example:

```bash
moon check
moon test
moon run cmd/main
```

## Usage

Compare two API snapshots and inspect the report:

```mbt nocheck
let old_api = @lib.parse_mbti_items([
  "pub fn parse(String) -> Int",
])
let new_api = @lib.parse_mbti_items([
  "pub fn parse(String) -> String",
  "pub fn format(Int) -> String",
])
let report = @lib.compare_api(old_api, new_api)
println(report.breaking_count()) // 1  (parse changed signature)
println(report.compatible_count()) // 1  (format was added)
println(report.semver_suggestion()) // major
println(report.release_blocked()) // true
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
// {"breaking":1,"compatible":1,"semver":"major","release_blocked":true}
```

## Core Concepts

| Type | Meaning |
| --- | --- |
| `ApiItem` | One normalized public API item (function, struct, enum, type, alias, trait, impl). |
| `ApiChange` | A single compatibility finding: `breaking` or `compatible`, with a human-readable message. |
| `ApiReport` | The full comparison result, with counts, SemVer suggestion, release blocking signal, and Markdown/JSON summaries. |

Key functions:

- `parse_mbti_items(lines)` — parse public declarations from `.mbti` interface lines.
- `compare_api(old_items, new_items)` — diff two API snapshots into an `ApiReport`.
- `ApiReport::semver_suggestion()` — `major` / `minor` / `patch` recommendation.
- `ApiReport::release_blocked()` — `true` when breaking changes exist, for CI gating.

## Roadmap

- Richer `.mbti` parsing: multi-line declarations, struct fields, enum variants, trait methods.
- Finer-grained change classification (visibility tightening, parameter renames, default changes).
- A `check old.mbti new.mbti` CLI that exits non-zero on breaking changes.
- GitHub Actions / GitLink CI templates for drop-in API guarding.
- Publishing to mooncakes.io.

## Development

```bash
moon fmt    # format code
moon check  # type check
moon test   # run tests
moon info   # regenerate .mbti interface files
```

CI runs all of the above and verifies that formatting and generated interfaces are up to date.

## License

Apache-2.0
