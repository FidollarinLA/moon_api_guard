# Compatibility Rules

This document describes the compatibility rules currently implemented by
`moon_api_guard`. Defaults follow MoonBit public-package practice on
[mooncakes.io](https://mooncakes.io). Severity can be remapped with
`CompatPolicy` / CLI `--allow` / `--ignore` / `--strict`.

## Summary

| Change | Default category | SemVer | Detail |
| --- | --- | --- | --- |
| Public item removed | breaking | major | `removed` |
| Value return type changed | breaking | major | `return-type-changed` |
| Raise clause added / type changed | breaking | major | `raise-added`, `raise-type-changed` |
| Raise clause removed | compatible | minor | `raise-removed` |
| Required / positional parameter removed or added | breaking | major | `parameter-removed`, `parameter-added` |
| Parameter type/text changed | breaking | major | `parameter-changed` |
| Labeled optional parameter added (`name? : T`) | compatible | minor | `optional-parameter-added` |
| Generic type bounds changed (`fn[T : Bound]`) | breaking | major | `type-bound-changed` |
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

## Why enum variant addition is breaking by default

MoonBit downstream code often uses exhaustive `match` on public enums.
Adding a variant causes previously complete matches to stop compiling.
Teams that intentionally treat additive variants as minor can remap:

```bash
moon run cmd/main -- check old.mbti new.mbti --allow variant-added
```

## Optional parameters

Labeled optional parameters such as `encoding? : String` are common in
MoonBit `.mbti` files. Adding them does not require call-site changes, so
`default_compat_policy()` classifies `optional-parameter-added` as
compatible. Use `--strict` to treat them as breaking.

## Raise clauses

`-> T raise E` is split from the value return type:

- adding / changing `E` is breaking
- removing `raise` is compatible by default (callers still compile)

## Identity rules that prevent false positives

- Associated functions are identified as `Type::method`, not bare `method`.
- Generic receivers keep type arguments, e.g. `Map[K, V]::get`.
- Generic functions `pub fn[T : Bound] name` are parsed and compared.
- `impl` items are identified as `Trait for Type`.

## Policy API / CLI

```bash
# default MoonBit-oriented policy
moon run cmd/main -- check old.mbti new.mbti

# treat almost everything as breaking
moon run cmd/main -- check old.mbti new.mbti --strict

# remap or drop specific details
moon run cmd/main -- check old.mbti new.mbti --allow variant-added,raise-removed
moon run cmd/main -- check old.mbti new.mbti --ignore deprecated

# load a JSON policy file (CLI --allow/--ignore still stack on top)
moon run cmd/main -- check old.mbti new.mbti --policy fixtures/policies/default-plus-variant.json
```

Library:

```mbt nocheck
let policy = match @moon_api_guard.policy_from_json_text(
  "{\"strict\":false,\"allow\":[\"variant-added\"],\"ignore\":[]}",
) {
  Some(p) => p
  None => @moon_api_guard.default_compat_policy()
}
let report = @moon_api_guard.compare_mbti_content_with_policy(old, new, policy)
```
