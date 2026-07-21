# Copyright (C) 2020-2026 3wlh <https://github.com/3wlh>
#
# MDDNS DNS 服务商脚本包 (每个服务商一个独立包)
# 安装到 /usr/lib/mddns/ 目录, 供 mddns 主程序自动扫描发现
#
# 可选包:
#   mddns-aliyun-script     - 阿里云 DNS
#   mddns-cloudflare-script - Cloudflare
#   mddns-dnshe-script      - DNSHE
#   mddns-dnspod-script     - DNSPod (腾讯云)
#   mddns-spaceship-script  - Spaceship

include $(TOPDIR)/rules.mk

PKG_NAME:=mddns-scripts
PKG_VERSION:=$(shell date +%y.%m.%d)
PKG_RELEASE:=$(shell date +%H%M%S)
PKG_MAINTAINER:=3wlh <3wlh.lh@gmail.com>
PKG_BUILD_DIR:=$(BUILD_DIR)/PKG_BUILD_$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

# ============================================================
# 包定义 (每个服务商一个独立包)
# ============================================================

define Package/mddns-aliyun-script
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=MDDNS script for Aliyun DNS
	URL:=https://github.com/3wlh
	PKGARCH:=all
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
	PKGARCH:=all
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
	PKGARCH:=all
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
	PKGARCH:=all
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
	PKGARCH:=all
endef
define Package/mddns-spaceship-script/description
	DNS provider script for MDDNS - Spaceship
endef

# ============================================================
# 构建 (仅复制脚本文件, 无编译)
# ============================================================

define Build/Prepare
	mkdir -pm 775 $(PKG_BUILD_DIR)
	$(CP) -fr files $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

# ============================================================
# 安装模板 (每个包安装对应的 .sh 脚本到 /usr/lib/mddns/)
# ============================================================

define Package/mddns-aliyun-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/mddns/mddns-aliyun.sh $(1)/usr/lib/mddns/
endef

define Package/mddns-cloudflare-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/mddns/mddns-cloudflare.sh $(1)/usr/lib/mddns/
endef

define Package/mddns-dnshe-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/mddns/mddns-dnshe.sh $(1)/usr/lib/mddns/
endef

define Package/mddns-dnspod-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/mddns/mddns-dnspod.sh $(1)/usr/lib/mddns/
endef

define Package/mddns-spaceship-script/install
	$(INSTALL_DIR) $(1)/usr/lib/mddns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/mddns/mddns-spaceship.sh $(1)/usr/lib/mddns/
endef

# ============================================================
# 注册包
# ============================================================

$(eval $(call BuildPackage,mddns-aliyun-script))
$(eval $(call BuildPackage,mddns-cloudflare-script))
$(eval $(call BuildPackage,mddns-dnshe-script))
$(eval $(call BuildPackage,mddns-dnspod-script))
$(eval $(call BuildPackage,mddns-spaceship-script))
