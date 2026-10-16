#!/bin/sh
# Build objdiff with 16-bit x86 support (x86-16bit.patch) into tools/bin.
set -e
VERSION=v3.8.2
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=${OBJDIFF_SRC:-$HERE/src}
if [ ! -d "$SRC" ]; then
    git clone --depth 1 --branch "$VERSION" https://github.com/encounter/objdiff.git "$SRC"
    git -C "$SRC" apply "$HERE/x86-16bit.patch"
fi
cargo build --release --manifest-path "$SRC/Cargo.toml" -p objdiff-cli -p objdiff-gui
mkdir -p "$HERE/../bin"
cp "$SRC/target/release/objdiff" "$SRC/target/release/objdiff-cli" "$HERE/../bin/"
echo "installed objdiff and objdiff-cli into tools/bin"
