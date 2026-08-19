.PHONY: all build base initramfs clean

all: build

build:
	./scripts/build.sh

base:
	./scripts/build-base.sh

initramfs: base
	./scripts/make-initramfs.sh

clean:
	rm -rf out/ rootfs/ build/
