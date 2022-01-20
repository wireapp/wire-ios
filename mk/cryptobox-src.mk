CRYPTOBOX_VERSION := v1.1.3
CRYPTOBOX         := cryptobox-$(CRYPTOBOX_VERSION)
CRYPTOBOX_GIT_URL := https://github.com/wireapp/cryptobox-c
CRYPTOBOX_SRC     := build/src/$(CRYPTOBOX)

$(CRYPTOBOX_SRC):
	mkdir -p build/src
	cd build/src && \
	git clone $(CRYPTOBOX_GIT_URL) $(CRYPTOBOX) && \
	cd $(CRYPTOBOX) && \
	git checkout $(CRYPTOBOX_VERSION)
