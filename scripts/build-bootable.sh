#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT_DIR/out"
ROOTFS="$OUT/rootfs"
WORK="$OUT/work"
BUSYBOX_VERSION="1.37.0"
KERNEL_VERSION="6.12.41"

rm -rf "$OUT"
# /bin/sh on Ubuntu runners is dash, which does not perform Bash-style brace
# expansion. Create every rootfs directory explicitly so later redirections
# such as /etc/os-release always have a parent directory.
mkdir -p \
    "$ROOTFS/bin" \
    "$ROOTFS/sbin" \
    "$ROOTFS/usr/bin" \
    "$ROOTFS/usr/sbin" \
    "$ROOTFS/etc" \
    "$ROOTFS/dev" \
    "$ROOTFS/proc" \
    "$ROOTFS/sys" \
    "$ROOTFS/run" \
    "$ROOTFS/tmp" \
    "$ROOTFS/var/lib/pkg" \
    "$ROOTFS/home" \
    "$ROOTFS/root" \
    "$ROOTFS/boot"
mkdir -p "$WORK"

fetch() {
    url="$1"; dest="$2"
    curl -fL --retry 3 --retry-delay 2 "$url" -o "$dest"
}

echo "==> Downloading BusyBox $BUSYBOX_VERSION"
fetch "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" "$WORK/busybox.tar.bz2"
tar -xf "$WORK/busybox.tar.bz2" -C "$WORK"
cd "$WORK/busybox-${BUSYBOX_VERSION}"
make distclean
# BusyBox 1.37.0 may ask about newly introduced options during defconfig.
# Empty answers select defaults. BusyBox does not provide Linux-kbuild's
# olddefconfig target, so do not invoke it here.
yes '' | make defconfig

# Ubuntu 24.04's newer kernel headers can expose APIs that BusyBox's optional
# traffic-control applet does not build against cleanly. The TC applet is not
# needed for the Uni-OS bootstrap, so keep it disabled in the CI build.
sed -i \
    -e 's/^CONFIG_TC=y/# CONFIG_TC is not set/' \
    -e 's/^CONFIG_SHA1_HWACCEL=y/# CONFIG_SHA1_HWACCEL is not set/' \
    -e 's/^CONFIG_SHA256_HWACCEL=y/# CONFIG_SHA256_HWACCEL is not set/' \
    .config

if grep -q '^# CONFIG_STATIC is not set' .config 2>/dev/null; then
    sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
elif ! grep -q '^CONFIG_STATIC=' .config 2>/dev/null; then
    printf '%s\n' 'CONFIG_STATIC=y' >> .config
fi

make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)" V=1
make CONFIG_PREFIX="$ROOTFS" install

cd "$ROOT_DIR"
cat > "$ROOTFS/etc/os-release" <<'EOF'
NAME="Uni-OS"
ID=uni-os
ID_LIKE="linux"
PRETTY_NAME="Uni-OS Linux"
VERSION="0.1-bootstrap"
VERSION_ID="0.1"
HOME_URL="https://github.com/carjam120443-netizen/uni-os"
EOF
cat > "$ROOTFS/etc/hostname" <<'EOF'
uni-os
EOF
cat > "$ROOTFS/etc/motd" <<'EOF'
Welcome to Uni-OS Linux!
BusyBox userspace + pkg bootstrap
EOF
cat > "$ROOTFS/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/sh
EOF
cat > "$ROOTFS/etc/group" <<'EOF'
root:x:0:
wheel:x:10:root
EOF
cat > "$ROOTFS/etc/profile" <<'EOF'
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
export PS1='[uni-os]\$ '
EOF
cat > "$ROOTFS/init" <<'EOF'
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true
hostname uni-os 2>/dev/null || true
echo
cat /etc/motd
echo
echo "Type 'pkg info' or 'pkg update' to test the package manager."
exec /bin/sh
EOF
chmod +x "$ROOTFS/init"
install -m 0755 "$ROOT_DIR/cmd/pkg" "$ROOTFS/usr/bin/pkg"
install -m 0755 "$ROOT_DIR/cmd/sudo" "$ROOTFS/usr/bin/sudo"

echo "==> Downloading Linux $KERNEL_VERSION"
cd "$WORK"
fetch "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" "linux-${KERNEL_VERSION}.tar.xz"
tar -xf "linux-${KERNEL_VERSION}.tar.xz"
cd "linux-${KERNEL_VERSION}"
make defconfig
# Build the kernel's host-side helper scripts before invoking scripts/config.
make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)" scripts
scripts/config --enable CONFIG_DEVTMPFS
scripts/config --enable CONFIG_DEVTMPFS_MOUNT
scripts/config --enable CONFIG_BLK_DEV_INITRD
scripts/config --enable CONFIG_ISO9660_FS
scripts/config --enable CONFIG_EXT4_FS
scripts/config --enable CONFIG_VIRTIO_PCI
scripts/config --enable CONFIG_VIRTIO_BLK
scripts/config --enable CONFIG_SCSI_LOWLEVEL
scripts/config --enable CONFIG_ATA
scripts/config --enable CONFIG_ATA_PIIX
scripts/config --enable CONFIG_E1000
scripts/config --enable CONFIG_E1000E
make olddefconfig
make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)" bzImage
cp arch/x86/boot/bzImage "$ROOTFS/boot/vmlinuz"

cd "$ROOTFS"
find . -print0 | cpio --null -o -H newc 2>/dev/null | gzip -9 > "$OUT/initramfs.img"
mkdir -p "$OUT/iso/boot/grub"
cp "$ROOTFS/boot/vmlinuz" "$OUT/iso/boot/vmlinuz"
cp "$OUT/initramfs.img" "$OUT/iso/boot/initramfs.img"
cat > "$OUT/iso/boot/grub/grub.cfg" <<'EOF'
set timeout=3
set default=0
menuentry "Uni-OS Linux" {
    linux /boot/vmlinuz console=tty0
    initrd /boot/initramfs.img
}
EOF
grub-mkrescue -o "$OUT/uni-os-vbox.iso" "$OUT/iso"
echo "==> Built: $OUT/uni-os-vbox.iso"
