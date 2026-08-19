#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT_DIR/out"
ROOTFS="$OUT/rootfs"

rm -rf "$OUT"
mkdir -p "$ROOTFS"/bin "$ROOTFS"/sbin "$ROOTFS"/usr/bin "$ROOTFS"/usr/sbin
mkdir -p "$ROOTFS"/etc "$ROOTFS"/dev "$ROOTFS"/proc "$ROOTFS"/sys "$ROOTFS"/tmp "$ROOTFS"/var "$ROOTFS"/home

cat > "$ROOTFS/etc/os-release" <<'EOF'
NAME="Uni-OS"
ID=uni-os
PRETTY_NAME="Uni-OS Linux"
VERSION="0.1-bootstrap"
VERSION_ID="0.1"
HOME_URL="https://github.com/carjam120443-netizen/uni-os"
EOF

cat > "$ROOTFS/etc/motd" <<'EOF'
Welcome to Uni-OS Linux!
This is an experimental bootstrap system.
EOF

cat > "$ROOTFS/init" <<'EOF'
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
printf '\nWelcome to Uni-OS Linux!\n'
printf 'Bootstrap userspace is alive.\n\n'
exec /bin/sh
EOF
chmod +x "$ROOTFS/init"

cat > "$ROOTFS/bin/pkg" <<'EOF'
#!/bin/sh
case "${1:-}" in
  --version|-v)
    echo "pkg (Uni-OS bootstrap) 0.1"
    ;;
  update)
    echo "pkg: repository support is being bootstrapped"
    ;;
  install)
    shift
    echo "pkg: package installation is not implemented yet: $*"
    ;;
  *)
    echo "Usage: pkg {update|install PACKAGE...|--version}"
    ;;
esac
EOF
chmod +x "$ROOTFS/bin/pkg"

cat > "$ROOTFS/etc/profile" <<'EOF'
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
export PS1='[uni-os]\\$ '
EOF

cat > "$OUT/BUILD_INFO" <<EOF
Uni-OS bootstrap
Version: 0.1-bootstrap
Architecture: x86_64 target
Package manager interface: pkg
Build timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "Uni-OS bootstrap rootfs created at: $ROOTFS"
echo "Next milestone: build Linux kernel + BusyBox and create a bootable image."
