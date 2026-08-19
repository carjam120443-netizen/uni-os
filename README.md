# Uni-OS

A from-scratch Linux/Unix-style operating system project.

> **Status:** Early bootstrap stage — experimental and not production-ready.

## Goals

- Linux kernel based operating system
- Small, Unix-like userspace
- `pkg` as the package-management interface for the first development phase
- Reproducible cross-builds from a normal Linux host
- Bootable x86_64 image for QEMU/VirtualBox
- Gradually replace bootstrap components with Uni-OS-native components

## Architecture

```text
Firmware / VM
    |
    v
Linux kernel
    |
    v
init + minimal userspace
    |
    +--> /bin /sbin /usr /etc /var /home
    |
    v
pkg package manager
    |
    v
Uni-OS package repository
```

## Build

Run the initial builder on a Linux build host:

```sh
./scripts/build.sh
```

Artifacts are placed under `out/`.

## Package manager direction

Uni-OS will initially expose a `pkg` command. The long-term plan is to build or port the real `pkg` implementation and package format for Linux rather than pretending that `apt` or another package manager is `pkg`.

## License

To be decided while the project is being bootstrapped.
