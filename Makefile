all: build

.PHONY: build clean

build: robots.dylan
	dylan-compiler -build robots.lid

clean:
	rm -rf _build/
