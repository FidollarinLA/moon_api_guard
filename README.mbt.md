# moon_api_guard

`moon_api_guard` is a MoonBit public API compatibility guard planned for OSC 2026.

The project helps MoonBit package authors compare old and new public interfaces, identify breaking API changes, and decide whether a release should be major, minor, or patch. It is designed to complement `moon info`: MoonBit already generates `.mbti` interface files, while this project compares those interface snapshots and turns differences into release and CI signals.

## Planned Scope

- Public API item modeling for functions, types, structs, enums, traits, implementations, and aliases.
- Lightweight `.mbti` parsing and API normalization.
- Breaking change detection for deleted items and changed signatures.
- Compatible change detection for newly added public API.
- SemVer recommendation for major, minor, and patch releases.
- Human-readable Markdown and machine-readable JSON reports.
- CLI and CI examples for preventing accidental public API breakage.

## Current Status

This repository has been initialized as a MoonBit module:

```bash
moon check
moon test
moon run cmd/main
```

Currently implemented:

- `ApiItem`, a normalized public API item.
- `ApiChange`, a compatibility finding.
- `ApiReport`, a summary of API compatibility changes.
- Basic comparison for removed API, changed signatures, and added API.
- Basic SemVer suggestion.
- Lightweight parsing for simple `.mbti` public lines.
- Markdown and JSON report summaries.
- Release blocking signal for CI usage.
- `cmd/main`, a minimal runnable example.
- MoonBit CI for check, test, formatting, and public interface verification.

Example:

```mbt nocheck
let old_api = [@lib.api_item("fn", "parse", "pub fn parse(String) -> Int")]
let new_api = [@lib.api_item("fn", "parse", "pub fn parse(String) -> String")]
let report = @lib.compare_api(old_api, new_api)
println(report.semver_suggestion()) // major
```

The project is still at the proposal and early implementation stage. More `.mbti` parsing coverage, compatibility rules, report formats, and CI helpers will be added in focused commits.

Repository submission links are still pending. Before OSC 2026 submission, create the public GitHub repository, import it into GitLink, and fill both links in the proposal materials.

## License

Apache-2.0
