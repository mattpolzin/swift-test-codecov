prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

build:
	swift build -c release --disable-sandbox

install: build
	install -d "$(bindir)" "$(libdir)"
	install ".build/release/swift-test-codecov" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/swift-test-codecov"

clean:
	rm -rf .build

.PHONY: build install uninstall clean