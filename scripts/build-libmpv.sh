#!/bin/sh
set -eu

MPV_TAG="v0.41.0"
MPV_COMMIT="41f6a645068483470267271e1d09966ca3b9f413"

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
BUILD_ROOT=${1:-"$ROOT/build"}
mkdir -p "$BUILD_ROOT"
BUILD_ROOT=$(CDPATH= cd -- "$BUILD_ROOT" && pwd)
SOURCE_DIR="$BUILD_ROOT/mpv"
MESON_DIR="$BUILD_ROOT/meson"
STAGE_DIR="$BUILD_ROOT/stage"

for tool in git meson ninja pkg-config; do
    command -v "$tool" >/dev/null 2>&1 || {
        printf 'Missing build tool: %s\n' "$tool" >&2
        exit 1
    }
done

if [ ! -d "$SOURCE_DIR/.git" ]; then
    git clone --filter=blob:none --no-checkout https://github.com/mpv-player/mpv.git "$SOURCE_DIR"
fi

git -C "$SOURCE_DIR" fetch --depth 1 origin "refs/tags/$MPV_TAG:refs/tags/$MPV_TAG"
git -C "$SOURCE_DIR" checkout --detach "$MPV_TAG"
ACTUAL_COMMIT=$(git -C "$SOURCE_DIR" rev-parse HEAD)
if [ "$ACTUAL_COMMIT" != "$MPV_COMMIT" ]; then
    printf 'Unexpected mpv commit: %s\n' "$ACTUAL_COMMIT" >&2
    exit 1
fi

# mpv 0.41.0 only adds these CoreFoundation string helpers with the full Cocoa
# frontend, although its CoreAudio backend also links them.  This component is
# intentionally libmpv-only, so include the helper source without pulling in
# the Cocoa player and Swift UI targets.
/usr/bin/sed -i.bak "/'osdep\\/utils-mac.c',/d" "$SOURCE_DIR/meson.build"
/usr/bin/sed -i.bak "/^if features\['cocoa'\]/i\\
sources += files('osdep/utils-mac.c')
" "$SOURCE_DIR/meson.build"
rm -f "$SOURCE_DIR/meson.build.bak"

BREW_PREFIX=$(brew --prefix)
export PKG_CONFIG_PATH="$BREW_PREFIX/lib/pkgconfig:$BREW_PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export MACOSX_DEPLOYMENT_TARGET=13.0

meson setup "$MESON_DIR" "$SOURCE_DIR" \
    --wipe \
    --prefix=/usr/local \
    --buildtype=release \
    -Dlibmpv=true \
    -Dcplayer=false \
    -Dtests=false \
    -Dbuild-date=false \
    -Dlua=disabled \
    -Djavascript=disabled \
    -Dvapoursynth=disabled \
    -Dvulkan=disabled \
    -Drubberband=disabled \
    -Ddvdnav=disabled \
    -Dlibbluray=disabled \
    -Dlibarchive=disabled \
    -Duchardet=disabled \
    -Dcocoa=disabled \
    -Dswift-build=disabled \
    -Dmacos-media-player=disabled \
    -Dmacos-touchbar=disabled \
    -Dmacos-cocoa-cb=disabled \
    -Dplain-gl=enabled

meson compile -C "$MESON_DIR"
DESTDIR="$STAGE_DIR" meson install -C "$MESON_DIR"

test -f "$STAGE_DIR/usr/local/lib/libmpv.dylib"
test -f "$STAGE_DIR/usr/local/include/mpv/client.h"
printf 'Built libmpv %s for %s\n' "$MPV_TAG" "$(uname -m)"
