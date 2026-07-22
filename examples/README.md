# Examples

## basic

Compare two in-memory `.mbti` snapshots with the public library API:

```bash
moon run examples/basic
```

Expected output includes a breaking return-type change (`parse`) and a
compatible addition (`format`), so `semver` is `major` and
`release_blocked` is `true`.

## CLI fixture check

Use the repository fixtures through the CLI:

```bash
moon run cmd/main -- check fixtures/old_api.mbti fixtures/new_api.mbti
moon run cmd/main -- check fixtures/old_api.mbti fixtures/new_api.mbti --format json
moon run cmd/main -- check fixtures/old_api.mbti fixtures/new_api.mbti --format markdown
```
