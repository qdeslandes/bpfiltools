IPT_SRC_DIR=
IPT_INSTALL_DIR=

BF_SRC_DIR=
BF_BUILD_DIR=$(BF_SRC_DIR)/build
BF_INSTALL_DIR=

ipt_build:
	cd $(IPT_SRC_DIR) && ./autogen.sh
	cd $(IPT_SRC_DIR) && PKG_CONFIG_PATH=$(BF_INSTALL_DIR)/usr/share/pkgconfig ./configure \
		--prefix=$(IPT_INSTALL_DIR) \
		--disable-nftables \
		--enable-libipq \
		--enable-bpfilter
	cd $(IPT_SRC_DIR) && make -j

ipt_install:
	$(MAKE) -C $(IPT_SRC_DIR) install

bf_build:
	cmake -B $(BF_BUILD_DIR) -S $(BF_SRC_DIR) -DCMAKE_BUILD_TYPE=release
	$(MAKE) -C $(BF_BUILD_DIR) -j

bf_install: export INSTALL_DIR=$(BF_INSTALL_DIR)
bf_install: bf_build
	install -D $(BF_BUILD_DIR)/lib/libbpfilter.so $(BF_INSTALL_DIR)/usr/lib64/libbpfilter.so
	install -D $(BF_BUILD_DIR)/lib/libbpfilter.a $(BF_INSTALL_DIR)/usr/lib64/libbpfilter.a
	install -D $(BF_BUILD_DIR)/src/bpfilter $(BF_INSTALL_DIR)/usr/bin/bpfilter

	rsync -a $(BF_SRC_DIR)/lib/include/ $(BF_INSTALL_DIR)/usr/include/
	rsync -a $(BF_SRC_DIR)/shared/include/ $(BF_INSTALL_DIR)/usr/include/

	install -D $(CURDIR)/bpfilter.pc.template $(BF_INSTALL_DIR)/usr/share/pkgconfig/bpfilter.pc
	echo $(BF_INSTALL_DIR)
	envsubst '$${INSTALL_DIR}' < $(CURDIR)/bpfilter.pc.template > $(BF_INSTALL_DIR)/usr/share/pkgconfig/bpfilter.pc

	tree $(BF_INSTALL_DIR)

bf_run:
	sudo $(BF_INSTALL_DIR)/usr/bin/bpfilter

bf_clean:
	sudo rm -rf /run/bpfilter.sock
	sudo rm -rf /run/bpfilter.blob
