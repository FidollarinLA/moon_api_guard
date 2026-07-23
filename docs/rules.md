# Compatibility Rules

This document describes the compatibility rules currently implemented by
`moon_api_guard`. Rules are intentionally conservative for public package
releases on [mooncakes.io](https://mooncakes.io).

## Summary

| Change | Category | SemVer impact | Detail |
| --- | --- | --- | --- |
| Public item removed | breaking | major | `removed` |
| Return type changed | breaking | major | `return-type-changed` |
| Parameter removed / added / changed | breaking | major | `parameter-*` |
| Visibility tightened (`pub(all)` → `pub`) | breaking | major | `visibility-tightened` |
| Struct / suberror field removed or type-changed | breaking | major | `field-*` |
| Trait method removed / changed / added | breaking | major | `method-*` |
| Enum variant removed | breaking | major | `variant-removed` |
| Enum variant added | breaking | major | `variant-added` |
| `.mbti` file removed from a directory snapshot | breaking | major | `file-removed` |
| Public item added | compatible | minor | `added` |
| `#deprecated` attribute added (body unchanged) | compatible | minor | `deprecated` |
| Attribute-only change (non-body) | compatible | minor | `attribute-changed` |
| `.mbti` file added to a directory snapshot | compatible | minor | `file-added` |
| No changes | — | patch | — |

## Why enum variant addition is breaking

MoonBit downstream code often uses exhaustive `match` on public enums.
Adding a variant causes previously complete matches to stop compiling,
even though old variants still exist. Treating this as compatible would
miss a class of release breakages that package authors care about.

If a future rule set needs “additive enum variants are minor”, it should
be an explicit opt-in policy, not the default for public packages.

## Identity rules that prevent false positives

- Associated functions are identified as `Type::method`, not bare `method`.
- Generic receivers keep type arguments, e.g. `Map[K, V]::get`.
- `impl` items are identified as `Trait for Type`.

## CI usage

```bash
moon info
moon run cmd/main -- check baseline/pkg.generated.mbti pkg.generated.mbti --breaking-only --format json
# intentional API change:
moon run cmd/main -- baseline update pkg.generated.mbti baseline/pkg.generated.mbti
```
