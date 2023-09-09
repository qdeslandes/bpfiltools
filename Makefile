-include $(CURDIR)/.env

ifndef BF_SRC_DIR
$(error BF_SRC_DIR is not set in .env)
endif

ifndef IPT_SRC_DIR
$(error IPT_SRC_DIR is not set in .env)
endif

BUILD_TYPE ?= release
BUILD_DIR ?= $(CURDIR)/build
INSTALL_DIR = $(BUILD_DIR)/root

BF_RUN_FLAGS ?= --transient --verbose
BF_BUILD_DIR = $(BUILD_DIR)/bpfilter.$(BUILD_TYPE)
BF_INSTALL_DIR = $(INSTALL_DIR)/bpfilter.$(BUILD_TYPE)

IPT_BUILD_DIR = $(BUILD_DIR)/iptables.$(BUILD_TYPE)
IPT_INSTALL_DIR = $(INSTALL_DIR)/iptables.$(BUILD_TYPE)

# This target explicitly calls bf.debug and bf.release, as setting those as
# dependencies of bf wouldn't work: once the first one completes, make
# assumes bf.check (which bf.debug and bf.release depends on) is up to date,
# and doesn't run it again.
bf:
	$(MAKE) -C $(CURDIR) bf.debug
	$(MAKE) -C $(CURDIR) bf.release

bf.debug: override BUILD_TYPE = debug
bf.release: override BUILD_TYPE = release
bf.release bf.debug: bf.check

bf.configure:
	cmake \
		-S $(BF_SRC_DIR) \
		-B $(BF_BUILD_DIR) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_INSTALL_PREFIX=$(BF_INSTALL_DIR)/usr

bf.build: bf.configure
	$(MAKE) -C $(BF_BUILD_DIR) -j $(shell nproc)

bf.check: bf.build ipt.install
	$(MAKE) -C $(BF_BUILD_DIR) checkstyle
	$(MAKE) -C $(BF_BUILD_DIR) test
	PATH=$(BF_INSTALL_DIR)/usr/bin:$(IPT_INSTALL_DIR)/sbin:$(PATH) $(MAKE) -C $(BF_BUILD_DIR) e2e

bf.install: bf.build
	$(MAKE) -C $(BF_BUILD_DIR) install

bf.run: bf.build
	sudo $(BF_BUILD_DIR)/src/bpfilter $(BF_RUN_FLAGS)

bf.reset:
	-sudo rm -rf /run/bpfilter.sock
	-sudo rm -rf /run/bpfilter.blob
	-sudo sh -c 'rm /sys/fs/bpf/bpfltr_*'

# Some ipt.* target depends on actual binaries and artefacts. This is required
# to prevent running ./autogen.sh, ./configure, and make install every time,
# as iptables' build system doesn't manage out-of-date artefacts well.
ipt: ipt.install

ipt.fetch: $(IPT_BUILD_DIR)/autogen.sh
$(IPT_BUILD_DIR)/autogen.sh:
	mkdir -p $(IPT_BUILD_DIR)
	rsync -avu $(IPT_SRC_DIR)/ $(IPT_BUILD_DIR)/

ipt.configure: $(IPT_BUILD_DIR)/Makefile
$(IPT_BUILD_DIR)/Makefile: $(IPT_BUILD_DIR)/autogen.sh | bf.install
	cd $(IPT_BUILD_DIR) && ./autogen.sh
	cd $(IPT_BUILD_DIR) && PKG_CONFIG_PATH=$(BF_INSTALL_DIR)/usr/share/pkgconfig ./configure \
		--prefix=$(IPT_INSTALL_DIR) \
		--disable-nftables \
		--enable-libipq \
		--enable-bpfilter

ipt.build: $(IPT_BUILD_DIR)/iptables/xtables-legacy-multi
$(IPT_BUILD_DIR)/iptables/xtables-legacy-multi: $(IPT_BUILD_DIR)/Makefile
	$(MAKE) -C $(IPT_BUILD_DIR)

ipt.install: $(IPT_INSTALL_DIR)/sbin/iptables
$(IPT_INSTALL_DIR)/sbin/iptables: $(IPT_BUILD_DIR)/iptables/xtables-legacy-multi
	$(MAKE) -C $(IPT_BUILD_DIR) install

mrproper:
	-rm -rf $(BUILD_DIR)
