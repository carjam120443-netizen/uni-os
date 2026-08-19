#!/bin/sh
set -eu

ROOT="${ROOT:-rootfs}"
OUT="${OUT:-build/initramfs.cpio.gz}"

command -v cpio >/dev/null 2>&1 || { echo "Missing host tool: cpio" >&2; exit 1; }
command -v gzip >/dev/null 2>&1 || { echo "Missing host tool: gzip" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"
(cd "$ROOT" && find . -print | cpio -o -H newc 2>/dev/null | gzip -9) > "$OUT"
echo "Created $OUT"
