#!/bin/sh
set -eu

ROOT="${ROOT:-rootfs}"
mkdir -p "$ROOT"/{bin,sbin,etc,dev,proc,sys,run,tmp,usr/bin,usr/sbin,var,home,root,boot}
mkdir -p "$ROOT"/usr/share/uni-os

cat > "$ROOT/etc/os-release" <<'EOF'
NAME="Uni-OS"
PRETTY_NAME="Uni-OS Linux"
ID=uni-os
ID_LIKE=linux
VERSION="0.1-bootstrap"
VERSION_ID="0.1"
HOME_URL="https://github.com/carjam120443-netizen/uni-os"
EOF

cat > "$ROOT/etc/hostname" <<'EOF'
uni-os
EOF

cat > "$ROOT/etc/motd" <<'EOF'
Welcome to Uni-OS Linux!
Minimal Linux base with pkg package management.
EOF

# Minimal command set expected in the initial root filesystem.
for cmd in sh mount umount mkdir cp mv rm ls cat echo printf sleep reboot poweroff; do
    if command -v "$cmd" >/dev/null 2>&1; then
        cp "$(command -v "$cmd")" "$ROOT/bin/" 2>/dev/null || true
    fi
done

# Install the Uni-OS command wrappers. Real implementations will replace these
# bootstrap versions as the userspace is built.
for cmd in pkg sudo; do
    if [ -f "cmd/$cmd" ]; then
        install -m 0755 "cmd/$cmd" "$ROOT/usr/bin/$cmd"
    fi
done

printf '%s\n' 'Uni-OS base filesystem prepared in rootfs/'
