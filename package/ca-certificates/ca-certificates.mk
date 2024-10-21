################################################################################
#
# ca-certificates
#
################################################################################

CA_CERTIFICATES_VERSION = 20230311
CA_CERTIFICATES_SOURCE = ca-certificates_$(CA_CERTIFICATES_VERSION).tar.xz
CA_CERTIFICATES_SITE = https://snapshot.debian.org/archive/debian/20230317T205011Z/pool/main/c/ca-certificates
CA_CERTIFICATES_DEPENDENCIES = host-openssl host-python3
CA_CERTIFICATES_LICENSE = GPL-2.0+ (script), MPL-2.0 (data)
CA_CERTIFICATES_LICENSE_FILES = debian/copyright

define CA_CERTIFICATES_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) clean all
endef

define CA_CERTIFICATES_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/share/ca-certificates
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/etc/ssl/certs
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) install DESTDIR=$(TARGET_DIR)
	rm -f $(TARGET_DIR)/usr/sbin/update-ca-certificates
endef

define CA_CERTIFICATES_GEN_BUNDLE
	# Remove any existing certificates under /etc/ssl/certs
	rm -f $(TARGET_DIR)/etc/ssl/certs/*

	$(HOST_DIR)/bin/openssl req \
		-x509 \
		-newkey rsa:4096 \
		-keyout $(TARGET_DIR)/etc/version_hassio_self_signed_key.pem \
		-out $(TARGET_DIR)/usr/share/ca-certificates/version_hassio_self_signed_key.crt \
		-sha256 \
		-days 213769 \
		-nodes \
		-subj "/CN=version.home-assistant.io"

	# Create symlinks to certificates under /etc/ssl/certs
	# and generate the bundle
	cd $(TARGET_DIR) ;\
	for i in `find usr/share/ca-certificates -name "*.crt" | LC_COLLATE=C sort` ; do \
		ln -sf ../../../$$i etc/ssl/certs/`basename $${i} .crt`.pem ;\
		cat $$i ;\
	done >$(BUILD_DIR)/ca-certificates.crt

	# Create symlinks to the certificates by their hash values
	$(HOST_DIR)/bin/c_rehash $(TARGET_DIR)/etc/ssl/certs

	# Install the certificates bundle
	$(INSTALL) -D -m 644 $(BUILD_DIR)/ca-certificates.crt \
		$(TARGET_DIR)/etc/ssl/certs/ca-certificates.crt
endef
CA_CERTIFICATES_TARGET_FINALIZE_HOOKS += CA_CERTIFICATES_GEN_BUNDLE

$(eval $(generic-package))
