#!/bin/sh
# Build David Fifield's exepack (https://www.bamsoftware.com/software/exepack/)
# into tools/bin. The build unpacks the original STARTREK.EXE with it.
set -e
VERSION=v1.5.0
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=${EXEPACK_SRC:-$HERE/src}
if [ ! -d "$SRC" ]; then
    git clone --branch "$VERSION" https://www.bamsoftware.com/git/exepack.git "$SRC"
fi
cargo build --release --manifest-path "$SRC/Cargo.toml"
mkdir -p "$HERE/../bin"
cp "$SRC/target/release/exepack" "$HERE/../bin/"
echo "installed exepack into tools/bin"
