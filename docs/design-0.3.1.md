# Design notes — 0.3.1

Engineering polish on top of the 0.3.0 policy surface.

## Goals

1. Commit package-surface style `.mbti` regressions under `fixtures/regression/`.
2. Load `CompatPolicy` from a JSON file (`policy_from_json_text` + CLI `--policy`).
3. Ship a one-command demo script for答辩 / local smoke runs.
4. Fix nested function-typed parameter parsing so optional labeled params
   after `(T) -> U` classify as `optional-parameter-added`.

## Policy file

```json
{
  "strict": false,
  "allow": ["variant-added"],
  "ignore": ["deprecated"]
}
```

CLI:

```bash
moon run cmd/main -- check old.mbti new.mbti --policy path/to/policy.json
```

When `--policy` is set, the file chooses the base policy (`strict` + its
`allow`/`ignore`). Additional CLI `--allow` / `--ignore` still stack on top.
`--strict` alone (without `--policy`) keeps the previous behavior.

## Non-goals

- No web / frontend UI in this release.
- No full semantic analysis of MoonBit source (still `.mbti` text based).
