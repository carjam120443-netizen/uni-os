.PHONY: all build base initramfs bootable clean

all: bootable

build:
	./scripts/build.sh

base:
	./scripts/build-base.sh

initramfs: base
	./scripts/make-initramfs.sh

bootable:
	./scripts/build-bootable.sh

clean:
	rm -rf out/ rootfs/ build/
