# Copyright (C) 2020-2026 3wlh <https://github.com/3wlh>
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mddns-script
BIN_NAME:=mddns-script
PKG_VERSION:=$(shell date +%y.%m.%d)
PKG_RELEASE:=$(shell date +%H%M%S)
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>
LUCI_TITLE:=LuCI app for mddns-script
LUCI_LANG:=zh-cn

ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=amd64
endif

BIN_FILE:=$(BIN_NAME)
BIN_URL:=https://github.com/3wlh/Actions-Source/releases/download/GitHub-Actions_mddns-script/mddns-script-$(PKG_ARCH)
PKG_BUILD_DIR:=$(BUILD_DIR)/PKG_BUILD_$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=Applications
	TITLE:=$(PKG_NAME)
	URL:=https://github.com/3wlh
	DEPENDS:=@(aarch64||x86_64)
endef

define Package/$(PKG_NAME)/description
	A lightweight multi-DDNS automatic update utility for OpenWrt.
endef

define Download/Files
	echo -e "\033[1;32m Download：$(BIN_URL)\033[0m"
	if [ ! -f $(PKG_BUILD_DIR)/$(BIN_FILE) ] ; then \
		wget -q $(BIN_URL) -O $(PKG_BUILD_DIR)/$(BIN_FILE); \
	fi
endef

define Build/Po2lmo
	if ! command -v po2lmo >/dev/null 2>&1; then \
		git clone https://github.com/openwrt-dev/po2lmo.git && cd po2lmo; \
		make clean && make && make install PREFIX=/tmp/ && cd - ;\
	fi
	$(foreach po,$(wildcard ./po/zh-cn/*.po), \
		/tmp/po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Prepare
	echo -e "\033[31m Prepare：$(PKG_ARCH)\033[0m"
	mkdir -pm 775 $(PKG_BUILD_DIR)
	$(call Download/Files)
	$(call Build/Po2lmo)
	$(CP) -fr root $(PKG_BUILD_DIR)
	$(CP) -fr luasrc $(PKG_BUILD_DIR)
	$(CP) -fr scripts $(PKG_BUILD_DIR)
	chmod -R 755 $(PKG_BUILD_DIR)
	ls $(PKG_BUILD_DIR)
endef

define Package/$(PKG_NAME)/postinst
[ -n "$${IPKG_INSTROOT}" ] || { rm -f /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache/
	/etc/init.d/rpcd reload 2>/dev/null
	/etc/init.d/ucitrack reload 2>/dev/null
	exit 0
}
endef

define Build/Compile
	touch $(BUILD_DIR)/$(PKG_NAME).built
endef

define Package/$(PKG_NAME)/conffiles
/etc/mddns-script/
/etc/config/mddns-script
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/lib/mddns-script
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(BIN_FILE) $(1)/usr/sbin/
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/*.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/mddns-script.init $(1)/etc/init.d/mddns-script
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/mddns-script.config $(1)/etc/config/mddns-script
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/mddns-script.uci-default $(1)/etc/uci-defaults/99-$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/mddns-script
endef


# ============================================================
# DNS 服务商脚本子包 (每个服务商一个独立包, PKGARCH:=all 不受主包架构限制)
# 安装到 /usr/lib/mddns-script/, 供 mddns 主程序启动时自动扫描发现
# ============================================================

define Package/mddns-aliyun-script
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=MDDNS script for Aliyun DNS
	URL:=https://github.com/3wlh
	DEPENDS:=+luci-app-mddns-script
	PKGARCH:=all
	PKG_VERSION:=1
	PKG_RELEASE:=1
endef
define Package/mddns-aliyun-script/description
	DNS provider script for MDDNS - 阿里云 DNS (Aliyun)
endef

define Package/mddns-cloudflare-script
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=MDDNS script for Cloudflare
	URL:=https://github.com/3wlh
	DEPENDS:=+luci-app-mddns-script
	PKGARCH:=all
	PKG_VERSION:=1
	PKG_RELEASE:=1
endef
define Package/mddns-cloudflare-script/description
	DNS provider script for MDDNS - Cloudflare
endef

define Package/mddns-dnshe-script
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=MDDNS script for DNSHE
	URL:=https://github.com/3wlh
	DEPENDS:=+luci-app-mddns-script
	PKGARCH:=all
	PKG_VERSION:=1
	PKG_RELEASE:=1
endef
define Package/mddns-dnshe-script/description
	DNS provider script for MDDNS - DNSHE
endef

define Package/mddns-dnspod-script
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=MDDNS script for DNSPod (Tencent Cloud)
	URL:=https://github.com/3wlh
	DEPENDS:=+luci-app-mddns-script
	PKGARCH:=all
	PKG_VERSION:=1
	PKG_RELEASE:=1
endef
define Package/mddns-dnspod-script/description
	DNS provider script for MDDNS - DNSPod (腾讯云)
endef

define Package/mddns-spaceship-script
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=MDDNS script for Spaceship
	URL:=https://github.com/3wlh
	DEPENDS:=+luci-app-mddns-script
	PKGARCH:=all
	PKG_VERSION:=1
	PKG_RELEASE:=1
endef
define Package/mddns-spaceship-script/description
	DNS provider script for MDDNS - Spaceship
endef

define Package/mddns-aliyun-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns-script
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/scripts/mddns-aliyun.sh $(1)/usr/lib/mddns-script/
endef

define Package/mddns-cloudflare-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns-script
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/scripts/mddns-cloudflare.sh $(1)/usr/lib/mddns-script/
endef

define Package/mddns-dnshe-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns-script
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/scripts/mddns-dnshe.sh $(1)/usr/lib/mddns-script/
endef

define Package/mddns-dnspod-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns-script
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/scripts/mddns-dnspod.sh $(1)/usr/lib/mddns-script/
endef

define Package/mddns-spaceship-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns-script
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/scripts/mddns-spaceship.sh $(1)/usr/lib/mddns-script/
endef

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,mddns-aliyun-script))
$(eval $(call BuildPackage,mddns-cloudflare-script))
$(eval $(call BuildPackage,mddns-dnshe-script))
$(eval $(call BuildPackage,mddns-dnspod-script))
$(eval $(call BuildPackage,mddns-spaceship-script))