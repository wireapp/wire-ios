LIBSODIUM_VERSION := 1.0.3
LIBSODIUM         := libsodium-$(LIBSODIUM_VERSION)
LIBSODIUM_URL     := http://download.libsodium.org/libsodium/releases/$(LIBSODIUM).tar.gz
LIBSODIUM_SRC     := build/src/$(LIBSODIUM)

$(LIBSODIUM_SRC):
	mkdir -p build/src
	cd build/src && \
	wget -O $(LIBSODIUM).tar.gz $(LIBSODIUM_URL) && \
	tar -xzf $(LIBSODIUM).tar.gz && \
	rm $(LIBSODIUM).tar.gz
