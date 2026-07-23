# Changelog

## 0.3.1 — 2026-07-23

### Added

- `policy_from_json_text` for loading `CompatPolicy` from JSON
- CLI `--policy <file.json>` (stacks with `--allow` / `--ignore`)
- Package-surface regression fixtures under `fixtures/regression/`
- Sample policy files under `fixtures/policies/`
- `scripts/demo.sh` one-command local / 答辩 demo
- `docs/design-0.3.1.md`

### Fixed

- Nested function-typed parameters such as `(Byte) -> Unit` no longer
  confuse return-arrow / parameter parsing (optional labeled params after
  them are classified correctly)

### Docs

- Fixture attribution notes in `fixtures/README.md`
- README / rules updated for `--policy`

## 0.3.0 — 2026-07-23

### Added

- Finer function classification: `raise-*`, `optional-parameter-added`,
  `type-bound-changed`
- `CompatPolicy` with `default_compat_policy` / `strict_compat_policy`
- `policy_allow` / `policy_ignore` / `compare_*_with_policy`
- CLI `--strict`, `--allow`, `--ignore`
- Parse support for `pub fn[T : Bound] name(...)`

### Changed

- Default policy treats labeled optional parameter additions as compatible
- Default policy treats raise-clause removal as compatible
- Documentation updated in `docs/rules.md`

## 0.2.0 — 2026-07-23

### Added

- `check-dir` CLI for recursive multi-file `.mbti` comparison
- `baseline update` CLI to refresh committed baselines
- `--breaking-only` flag for CI-focused output
- Library helpers: `breaking_only`, `scoped`, `merge_api_reports`,
  `file_removed_report`, `file_added_report`
- `docs/rules.md` compatibility rule table
- `examples/ci-guard` workflow example
- Multi-platform CI (`ubuntu-latest`, `macos-latest`)

### Changed

- Version bump to `0.2.0` for user-visible CLI/API surface expansion

## 0.1.2 — 2026-07-22

### Added

- `compare_mbti_content` convenience API
- CLI `--format text|markdown|json`
- Deprecation attribute treated as compatible when body is unchanged
- Generic associated-function identity (`Map[K, V]::get`)
- `examples/basic` runnable sample

### Fixed

- Associated methods no longer collide across different types
- Enum variant addition classified as breaking

## 0.1.1 — 2026-07-22

### Added

- Initial mooncakes.io publication
- GitHub Actions CI with check / test / build / fmt / info
