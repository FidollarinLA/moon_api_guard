# moon_api_guard 0.3.0 Design — Semantic Rules

**Goal:** Deeper function-signature semantics + configurable severity, without changing the 0.2.0 product workflow.

## Defaults (`default_compat_policy`)

| Detail | Default category | Rationale |
| --- | --- | --- |
| `optional-parameter-added` | compatible | Labeled `name? : T` additions are additive for callers |
| `enum-variant-added` | breaking | Exhaustive match breakage (unchanged) |
| `raise-added` / `raise-type-changed` | breaking | Call sites must handle new errors |
| `raise-removed` | compatible | Callers that did not rely on failure still compile |
| `type-bound-changed` | breaking | Generic constraint tightening/loosening can break |

## API

- `CompatPolicy` + `default_compat_policy()` / `strict_compat_policy()`
- `policy_allow(policy, detail)` → treat detail as compatible
- `policy_ignore(policy, detail)` → drop from report
- `compare_api_with_policy` / `compare_mbti_content_with_policy`
- Existing `compare_api` uses `default_compat_policy()`

## CLI

```text
--allow <detail>[,detail...]   # remap to compatible
--ignore <detail>[,detail...]  # drop from report
--strict                       # use strict_compat_policy()
```

## Out of scope

- Full async surface (rare in current `.mbti` corpus)
- External JSON policy files (can follow later)
