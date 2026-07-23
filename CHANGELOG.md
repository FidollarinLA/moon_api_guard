# Changelog

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
