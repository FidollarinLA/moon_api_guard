# Publishing to mooncakes.io

This guide walks through publishing `FidollarinLA/moon_api_guard` to [mooncakes.io](https://mooncakes.io) for OSC 2026 final acceptance.

## Prerequisites

- MoonBit toolchain installed (`moon version --all`)
- A mooncakes.io account whose username matches the module prefix (`FidollarinLA`)
- This repository passes local CI:

```bash
moon check
moon test
moon fmt && git diff --exit-code
moon info && git diff --exit-code
```

## Module metadata

The module name in `moon.mod` must match your mooncakes.io username:

```toml
name = "FidollarinLA/moon_api_guard"
version = "0.1.0"
license = "Apache-2.0"
repository = "https://github.com/FidollarinLA/moon_api_guard"
description = "Public API compatibility checks for MoonBit packages."
```

Only library packages under the module root are published; the CLI in `cmd/main` stays in the repository for local/CI use.

## Register and log in

If you do not have a mooncakes.io account yet:

```bash
moon register
```

If you already have an account:

```bash
moon login
```

Successful login creates `~/.moon/credentials.json`.

## Dry run

Verify metadata and packaging without uploading:

```bash
moon publish --dry-run
```

Fix any reported errors before the real publish.

## Publish

From the repository root:

```bash
moon publish
```

Follow Semantic Versioning: each release must bump `version` in `moon.mod` (for example `0.1.0` → `0.1.1` for patches).

After publishing, consumers can add the library with:

```bash
moon add FidollarinLA/moon_api_guard
```

Example usage in another module:

```mbt nocheck
let old_api = @moon_api_guard.parse_mbti_content(old_text)
let new_api = @moon_api_guard.parse_mbti_content(new_text)
let report = @moon_api_guard.compare_api(old_api, new_api)
```

The CLI remains runnable from this repository:

```bash
moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti
```

## Dual remote sync (GitHub + GitLink)

OSC 2026 requires both remotes to stay in sync on the default branch (`main`):

| Remote | URL |
| --- | --- |
| GitHub | https://github.com/FidollarinLA/moon_api_guard |
| GitLink | https://gitlink.org.cn/FidollarinLA/moon_api_guard |

Push to both after each meaningful commit:

```bash
git push gitlink main
git push github main
```

If GitHub rejects `.github/workflows/` files, refresh the GitHub CLI token with the `workflow` scope:

```bash
gh auth refresh -h github.com -s workflow
```

Then push again so CI workflows appear on GitHub as well as GitLink.
