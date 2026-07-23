#!/usr/bin/env bash
# Local demo for moon_api_guard (答辩 / 日常回归演示)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== moon_api_guard demo =="
echo "cwd: $ROOT"
echo

run_step() {
  local title="$1"
  shift
  echo "-- $title"
  echo "+ $*"
  set +e
  "$@"
  local code=$?
  set -e
  echo "exit: $code"
  echo
}

run_step "basic fixture (expect breaking)" \
  moon run cmd/main -- check fixtures/old_api.mbti fixtures/new_api.mbti --format markdown

run_step "directory snapshot (expect breaking)" \
  moon run cmd/main -- check-dir fixtures/dir_old fixtures/dir_new --breaking-only --format json

run_step "regression: fs optional params (expect compatible / exit 0)" \
  moon run cmd/main -- check fixtures/regression/fs_old.mbti fixtures/regression/fs_new.mbti --format json

run_step "regression: base64 optional params (expect compatible / exit 0)" \
  moon run cmd/main -- check fixtures/regression/base64_old.mbti fixtures/regression/base64_new.mbti --format json

run_step "regression: raise-type-changed (expect breaking)" \
  moon run cmd/main -- check fixtures/regression/raise_old.mbti fixtures/regression/raise_new.mbti --format markdown

run_step "JSON policy allow variant-added" \
  moon run cmd/main -- check \
  fixtures/old_api.mbti fixtures/new_api.mbti \
  --policy fixtures/policies/default-plus-variant.json \
  --format text

run_step "library example" \
  moon run examples/basic

echo "== demo finished =="
echo "Tip: scripts/demo.sh is safe to re-run; non-zero exits above are expected for breaking cases."
