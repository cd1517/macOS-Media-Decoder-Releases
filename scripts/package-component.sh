#!/bin/bash
set -euo pipefail

MPV_VERSION="0.41.0"
MPV_COMMIT="41f6a645068483470267271e1d09966ca3b9f413"
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
STAGE_DIR=${1:-"$ROOT/build/stage"}
DIST_DIR=${2:-"$ROOT/dist"}
SOURCE_LIB="$STAGE_DIR/usr/local/lib/libmpv.dylib"
ARCH=$(uname -m)
COMPONENT_DIR="$DIST_DIR/HoverPreviewDecoder-$MPV_VERSION-$ARCH"
LIB_DIR="$COMPONENT_DIR/lib"

test -f "$SOURCE_LIB"
mkdir -p "$LIB_DIR" "$COMPONENT_DIR/licenses"
cp -L "$SOURCE_LIB" "$LIB_DIR/libmpv.dylib"

queue=("$LIB_DIR/libmpv.dylib")
seen="|"
while ((${#queue[@]})); do
    current=${queue[0]}
    queue=("${queue[@]:1}")
    base=$(basename "$current")
    [[ "$seen" == *"|$base|"* ]] && continue
    seen+="$base|"

    while IFS= read -r dependency; do
        case "$dependency" in
            /System/Library/*|/usr/lib/*|@loader_path/*|@rpath/*|@executable_path/*) continue ;;
        esac
        test -f "$dependency" || continue
        dep_base=$(basename "$dependency")
        destination="$LIB_DIR/$dep_base"
        if [ ! -f "$destination" ]; then
            cp -L "$dependency" "$destination"
            chmod u+w "$destination"
            queue+=("$destination")
        fi
        install_name_tool -change "$dependency" "@loader_path/$dep_base" "$current"
    done < <(otool -L "$current" | tail -n +2 | sed -E 's/^[[:space:]]+([^[:space:]]+).*/\1/')

    install_name_tool -id "@loader_path/$base" "$current" 2>/dev/null || true
done

for library in "$LIB_DIR"/*.dylib; do
    codesign --force --sign - "$library"
done

SOURCE_ROOT="$STAGE_DIR/../mpv"
for license in LICENSE.GPL LICENSE.LGPL Copyright; do
    test -f "$SOURCE_ROOT/$license" && cp "$SOURCE_ROOT/$license" "$COMPONENT_DIR/licenses/$license"
done

cat > "$COMPONENT_DIR/component.json" <<EOF
{
  "componentVersion": 1,
  "mpvVersion": "$MPV_VERSION",
  "mpvCommit": "$MPV_COMMIT",
  "architecture": "$ARCH",
  "minimumMacOS": "13.0",
  "library": "lib/libmpv.dylib"
}
EOF

(cd "$COMPONENT_DIR" && find . -type f ! -name checksums.txt -print0 | sort -z | xargs -0 shasum -a 256 > checksums.txt)
ARCHIVE="$DIST_DIR/HoverPreviewDecoder-$MPV_VERSION-$ARCH.zip"
ditto -c -k --sequesterRsrc --keepParent "$COMPONENT_DIR" "$ARCHIVE"
shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256"
printf 'Packaged %s\n' "$ARCHIVE"
