SHELL   := /usr/bin/env bash
VERSION := 0.3.0

TARGETS := aarch64-apple-ios \
           x86_64-apple-ios

# pkg-config is invoked by libsodium-sys
# cf. https://github.com/alexcrichton/pkg-config-rs/blob/master/src/lib.rs#L12
export PKG_CONFIG_ALLOW_CROSS=1

all: dist

distclean:
	rm -rf build
	rm -rf dist

dist-libs: cryptobox
	mkdir -p dist/lib
	mkdir -p dist/include
	cp build/lib/libsodium.a dist/lib/
	cp -r build/include/* dist/include/
	lipo -create $(foreach tgt,$(TARGETS),"build/lib/libcryptobox-$(tgt).a") \
		-output "dist/lib/libcryptobox.a"

dist/cryptobox-ios-$(VERSION).tar.gz: dist-libs
	tar -C dist \
		-czf dist/cryptobox-ios-$(VERSION).tar.gz \
		lib include

dist-tar: dist/cryptobox-ios-$(VERSION).tar.gz

dist: dist-tar

#############################################################################
# cryptobox

include mk/cryptobox-src.mk

build/lib/libcryptobox.a: libsodium $(CRYPTOBOX_SRC)
	cd $(CRYPTOBOX_SRC) && \
	sed -i.bak s/crate\-type.*/crate\-type\ =\ \[\"staticlib\"\]/g Cargo.toml && \
	$(foreach tgt,$(TARGETS),cargo rustc --lib --release --target=$(tgt);)
	mkdir -p build/lib
	$(foreach tgt,$(TARGETS),cp $(CRYPTOBOX_SRC)/target/$(tgt)/release/libcryptobox.a build/lib/libcryptobox-$(tgt).a;)

build/include/cbox.h: $(CRYPTOBOX_SRC)
	mkdir -p build/include
	cp $(CRYPTOBOX_SRC)/cbox.h build/include/

cryptobox: build/lib/libcryptobox.a build/include/cbox.h

# Build against an existing release.
cryptobox-%:
	mkdir -p build
	cd build
	cp -rf Carthage/Checkouts/cryptobox-ios/mk/cryptobox-src.mk ./mk
	cp -rf Carthage/Checkouts/cryptobox-ios/mk/libsodium-src.mk ./mk
	if [ ! -f build/cryptobox-ios-$*.tar.gz ]; then \
	curl -L -o build/cryptobox-ios-$*.tar.gz https://github.com/wireapp/cryptobox-ios/releases/download/v$*/cryptobox-ios-$*.tar.gz; \
	fi
	cd build && tar -xzf cryptobox-ios-$*.tar.gz

#############################################################################
# libsodium

include mk/libsodium-src.mk

build/lib/libsodium.a: $(LIBSODIUM_SRC)
	cp mk/ios-full.sh $(LIBSODIUM_SRC)/dist-build && \
		chmod +x $(LIBSODIUM_SRC)/dist-build/ios-full.sh && \
		cd $(LIBSODIUM_SRC) && \
		dist-build/ios-full.sh
	mkdir -p build/lib
	cp $(LIBSODIUM_SRC)/libsodium-ios/libsodium.a build/lib/libsodium.a

build/include/sodium.h: build/lib/libsodium.a
	mkdir -p build/include
	cp $(LIBSODIUM_SRC)/libsodium-ios/include/sodium.h build/include/sodium.h
	cp -r $(LIBSODIUM_SRC)/libsodium-ios/include/sodium build/include/sodium

libsodium: build/lib/libsodium.a build/include/sodium.h
