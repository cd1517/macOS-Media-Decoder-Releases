#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

test -f "$ROOT/scripts/build-libmpv.sh"
test -f "$ROOT/scripts/package-component.sh"
test -f "$ROOT/.github/workflows/build.yml"

grep -q 'MPV_TAG="v0.41.0"' "$ROOT/scripts/build-libmpv.sh"
grep -q 'MPV_COMMIT="41f6a645068483470267271e1d09966ca3b9f413"' "$ROOT/scripts/build-libmpv.sh"
grep -q -- '-Dlibmpv=true' "$ROOT/scripts/build-libmpv.sh"
grep -q -- '-Dcplayer=false' "$ROOT/scripts/build-libmpv.sh"
grep -q 'BUILD_ROOT=$(CDPATH= cd -- "$BUILD_ROOT" && pwd)' "$ROOT/scripts/build-libmpv.sh"
grep -q 'component.json' "$ROOT/scripts/package-component.sh"
grep -q 'shasum -a 256' "$ROOT/scripts/package-component.sh"
grep -q 'macos-15' "$ROOT/.github/workflows/build.yml"
grep -q 'macos-15-intel' "$ROOT/.github/workflows/build.yml"

printf '%s\n' 'Decoder repository layout validation passed'
