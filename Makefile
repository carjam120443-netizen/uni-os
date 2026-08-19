.PHONY: all build clean

all: build

build:
	./scripts/build.sh

clean:
	rm -rf out/
