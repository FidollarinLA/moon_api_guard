# Fixtures

Test and demo `.mbti` snapshots used by CLI / library regression tests.

## Layout

| Path | Purpose |
| --- | --- |
| `old_api.mbti` / `new_api.mbti` | Small hand-written API break demo |
| `dir_old/` / `dir_new/` | Multi-file `check-dir` demo |
| `regression/` | Package-surface style regressions |
| `policies/*.json` | Sample `--policy` documents |

## Regression sources

Files under `regression/` are **derived excerpts** inspired by public
interfaces from [`moonbitlang/x`](https://github.com/moonbitlang/x)
(`fs`, `codec/base64`), licensed under Apache-2.0. They are simplified for
stable tests and are **not** verbatim upstream `.mbti` dumps.

## Policy JSON

```json
{
  "strict": false,
  "allow": ["variant-added"],
  "ignore": []
}
```

- `strict`: start from `strict_compat_policy()` instead of defaults
- `allow`: remap detail keys to compatible
- `ignore`: drop matching findings
