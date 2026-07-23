# moon_api_guard

`moon_api_guard` is a public API compatibility guard for [MoonBit](https://www.moonbitlang.com) packages.

## Repository

- **GitHub**: https://github.com/FidollarinLA/moon_api_guard
- **GitLink**: https://gitlink.org.cn/FidollarinLA/moon_api_guard

Both remotes stay in sync for OSC 2026 submission. Default branch: `main`.

## OSC 2026 项目申报

本项目参加 [MoonBit 国产开源生态大赛 OSC 2026](https://www.gitlink.org.cn/competitions/track1_2026MoonBit)。

完整申报说明见同目录 **[OSC2026_项目申报书.md](OSC2026_项目申报书.md)**（与 README 同级，便于审核查阅），内容包括项目简介、方向与适用场景、已实现核心功能、后续计划、原创/参考说明及双仓库链接。

| 项 | 内容 |
| --- | --- |
| 参赛者 | 翟继康 |
| 项目方向 | MoonBit 工程基础设施 / API 兼容性与发布守卫 |
| 开源许可证 | Apache-2.0 |
| 测试 | 覆盖白盒 + 黑盒 + CLI；CI 覆盖 check / test / build / example / fmt / info |

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
moon run cmd/main -- check-dir fixtures/dir_old fixtures/dir_new --breaking-only --format json
moon run cmd/main -- check fixtures/regression/fs_old.mbti fixtures/regression/fs_new.mbti
./scripts/demo.sh
moon run examples/basic
```

The CLI exits with code `1` when breaking changes are detected, and `0` when the public API is compatible.

Runnable example:

```bash
moon run examples/basic
```

## CLI

Compare two `.mbti` snapshots from the command line:

```bash
moon run cmd/main -- check path/to/old.mbti path/to/new.mbti
moon run cmd/main -- check path/to/old.mbti path/to/new.mbti --format json --breaking-only
moon run cmd/main -- check path/to/old.mbti path/to/new.mbti --allow variant-added --strict
moon run cmd/main -- check path/to/old.mbti path/to/new.mbti --policy fixtures/policies/default-plus-variant.json
moon run cmd/main -- check-dir path/to/old_dir path/to/new_dir --format markdown
moon run cmd/main -- baseline update pkg.generated.mbti baseline/pkg.generated.mbti
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
let report = @lib.compare_mbti_content(old_mbti_text, new_mbti_text)
println(report.breaking_count())
println(report.compatible_count())
println(report.semver_suggestion())
println(report.release_blocked())
```

Or parse first, then compare:

```mbt nocheck
///|
let old_api = @lib.parse_mbti_content(old_mbti_text)

///|
let new_api = @lib.parse_mbti_content(new_mbti_text)

///|
let report = @lib.compare_api(old_api, new_api)
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
- `compare_mbti_content(old, new)` — parse + compare in one call.
- `compare_mbti_content_with_policy(old, new, policy)` — compare with severity overrides.
- `default_compat_policy()` / `strict_compat_policy()` / `policy_allow` / `policy_ignore` / `policy_from_json_text`
- `ApiReport::breaking_only()` — keep only breaking findings.
- `ApiReport::scoped(scope)` — prefix findings with a file/path scope.
- `merge_api_reports(reports)` — combine multi-file reports.
- `ApiReport::semver_suggestion()` — `major` / `minor` / `patch` recommendation.
- `ApiReport::release_blocked()` — `true` when breaking changes exist, for CI gating.

Compatibility rules are documented in [docs/rules.md](docs/rules.md).

Breaking change details include:

- `return-type-changed`, `parameter-removed`, `parameter-added`, `parameter-changed`
- `visibility-tightened` (`pub(all)` → `pub`)
- `field-removed`, `field-added`, `field-type-changed`
- `method-removed`, `method-changed`, `method-added`
- `variant-removed`, `variant-added`, `removed`
- `deprecated` (compatible attribute-only change)

## Publishing

Module name: **`FidollarinLA/moon_api_guard`** (matches the GitHub / mooncakes.io account).

```bash
moon login          # once, creates ~/.moon/credentials.json
moon publish --dry-run
moon publish        # uploads to https://mooncakes.io
```

Published package: [FidollarinLA/moon_api_guard](https://mooncakes.io/docs/FidollarinLA/moon_api_guard) (current version `0.3.1`).

Consumers add the library with:

```bash
moon add FidollarinLA/moon_api_guard
```

Step-by-step guide: [docs/publishing.md](docs/publishing.md) (login, dry-run, dual-remote sync for GitHub + GitLink).

## Roadmap

- More `.mbti` edge cases: generic bounds, deeply nested signatures.

## Development

```bash
moon fmt    # format code
moon check  # type check
moon test   # run tests
moon build  # build all targets
moon info   # regenerate .mbti interface files
moon coverage analyze  # inspect uncovered lines
```

CI runs all of the above and verifies that formatting and generated interfaces are up to date.

## License

Apache-2.0. See [LICENSE](LICENSE).

## References

This project is original MoonBit work. The design is informed by (not ported from) these API compatibility tools:

| Project | Link | License | Scope of reference |
| --- | --- | --- | --- |
| cargo-semver-checks | https://github.com/obi1kenobi/cargo-semver-checks | Apache-2.0 / MIT | SemVer and breaking-change classification |
| japicmp | https://github.com/siom79/japicmp | Apache-2.0 | API diff reports for library releases |
| revapi | https://github.com/revapi/revapi | Apache-2.0 | CI integration and version bump guidance |
