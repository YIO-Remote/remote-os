################################################################################
#
# swupdate
#
################################################################################

SWUPDATE_VERSION = 2020.11
SWUPDATE_SITE = $(call github,sbabic,swupdate,$(SWUPDATE_VERSION))
SWUPDATE_LICENSE = GPL-2.0+ with OpenSSL exception, LGPL-2.1+, MIT
SWUPDATE_LICENSE_FILES = Licenses/Exceptions Licenses/gpl-2.0.txt \
	Licenses/lgpl-2.1.txt Licenses/mit.txt

# swupdate uses $CROSS-cc instead of $CROSS-gcc, which is not
# available in all external toolchains, and use CC for linking. Ensure
# TARGET_CC is used for both.
SWUPDATE_MAKE_ENV = CC="$(TARGET_CC)" LD="$(TARGET_CC)"

# swupdate bundles its own version of mongoose (version 6.16)

ifeq ($(BR2_PACKAGE_EFIBOOTMGR),y)
SWUPDATE_DEPENDENCIES += efibootmgr
SWUPDATE_MAKE_ENV += HAVE_LIBEBGENV=y
else
SWUPDATE_MAKE_ENV += HAVE_LIBEBGENV=n
endif

ifeq ($(BR2_PACKAGE_JSON_C),y)
SWUPDATE_DEPENDENCIES += json-c
SWUPDATE_MAKE_ENV += HAVE_JSON_C=y
else
SWUPDATE_MAKE_ENV += HAVE_JSON_C=n
endif

ifeq ($(BR2_PACKAGE_LIBARCHIVE),y)
SWUPDATE_DEPENDENCIES += libarchive
SWUPDATE_MAKE_ENV += HAVE_LIBARCHIVE=y
else
SWUPDATE_MAKE_ENV += HAVE_LIBARCHIVE=n
endif

ifeq ($(BR2_PACKAGE_LIBCONFIG),y)
SWUPDATE_DEPENDENCIES += libconfig
SWUPDATE_MAKE_ENV += HAVE_LIBCONFIG=y
else
SWUPDATE_MAKE_ENV += HAVE_LIBCONFIG=n
endif

ifeq ($(BR2_PACKAGE_LIBCURL),y)
SWUPDATE_DEPENDENCIES += libcurl
SWUPDATE_MAKE_ENV += HAVE_LIBCURL=y
else
SWUPDATE_MAKE_ENV += HAVE_LIBCURL=n
endif

ifeq ($(BR2_PACKAGE_LIBGPIOD),y)
SWUPDATE_DEPENDENCIES += libgpiod
SWUPDATE_MAKE_ENV += HAVE_LIBGPIOD=y
else
SWUPDATE_MAKE_ENV += HAVE_LIBGPIOD=n
endif

ifeq ($(BR2_PACKAGE_LIBURIPARSER),y)
SWUPDATE_DEPENDENCIES += liburiparser
SWUPDATE_MAKE_ENV += HAVE_URIPARSER=y
else
SWUPDATE_MAKE_ENV += HAVE_URIPARSER=n
endif

ifeq ($(BR2_PACKAGE_LIBWEBSOCKETS),y)
SWUPDATE_DEPENDENCIES += libwebsockets
SWUPDATE_MAKE_ENV += HAVE_LIBWEBSOCKETS=y
else
SWUPDATE_MAKE_ENV += HAVE_LIBWEBSOCKETS=n
endif

ifeq ($(BR2_PACKAGE_HAS_LUAINTERPRETER):$(BR2_STATIC_LIBS),y:)
SWUPDATE_DEPENDENCIES += luainterpreter host-pkgconf
# defines the base name for the pkg-config file ("lua" or "luajit")
define SWUPDATE_SET_LUA_VERSION
	$(call KCONFIG_SET_OPT,CONFIG_LUAPKG,$(BR2_PACKAGE_PROVIDES_LUAINTERPRETER))
endef
SWUPDATE_MAKE_ENV += HAVE_LUA=y
else
SWUPDATE_MAKE_ENV += HAVE_LUA=n
endif

ifeq ($(BR2_PACKAGE_MTD),y)
SWUPDATE_DEPENDENCIES += mtd
SWUPDATE_MAKE_ENV += HAVE_LIBMTD=y
SWUPDATE_MAKE_ENV += HAVE_LIBUBI=y
else
SWUPDATE_MAKE_ENV += HAVE_LIBMTD=n
SWUPDATE_MAKE_ENV += HAVE_LIBUBI=n
endif

# OpenSSL or mbedTLS
ifeq ($(BR2_PACKAGE_OPENSSL),y)
SWUPDATE_DEPENDENCIES += openssl
SWUPDATE_MAKE_ENV += HAVE_LIBSSL=y
SWUPDATE_MAKE_ENV += HAVE_LIBCRYPTO=y
SWUPDATE_MAKE_ENV += HAVE_MBEDTLS=n
else
SWUPDATE_MAKE_ENV += HAVE_LIBSSL=n
SWUPDATE_MAKE_ENV += HAVE_LIBCRYPTO=n
ifeq ($(BR2_PACKAGE_MBEDTLS),y)
SWUPDATE_DEPENDENCIES += mbedtls
SWUPDATE_MAKE_ENV += HAVE_MBEDTLS=y
else
SWUPDATE_MAKE_ENV += HAVE_MBEDTLS=n
endif
endif

ifeq ($(BR2_PACKAGE_SYSTEMD),y)
SWUPDATE_DEPENDENCIES += systemd
endif

ifeq ($(BR2_PACKAGE_LIBUBOOTENV),y)
SWUPDATE_DEPENDENCIES += libubootenv
SWUPDATE_MAKE_ENV += HAVE_LIBUBOOTENV=y
else
SWUPDATE_MAKE_ENV += HAVE_LIBUBOOTENV=n
endif

ifeq ($(BR2_PACKAGE_ZEROMQ),y)
SWUPDATE_DEPENDENCIES += zeromq
SWUPDATE_MAKE_ENV += HAVE_LIBZEROMQ=y
else
SWUPDATE_MAKE_ENV += HAVE_LIBZEROMQ=n
endif

ifeq ($(BR2_PACKAGE_ZLIB),y)
SWUPDATE_DEPENDENCIES += zlib
SWUPDATE_MAKE_ENV += HAVE_ZLIB=y
else
SWUPDATE_MAKE_ENV += HAVE_ZLIB=n
endif

ifeq ($(BR2_PACKAGE_ZSTD),y)
SWUPDATE_DEPENDENCIES += zstd
SWUPDATE_MAKE_ENV += HAVE_ZSTD=y
else
SWUPDATE_MAKE_ENV += HAVE_ZSTD=n
endif

ifeq ($(BR2_PACKAGE_LIBRSYNC),y)
SWUPDATE_DEPENDENCIES += librsync
endif

SWUPDATE_BUILD_CONFIG = $(@D)/.config

SWUPDATE_KCONFIG_FILE = $(call qstrip,$(BR2_PACKAGE_SWUPDATE_CONFIG))
SWUPDATE_KCONFIG_EDITORS = menuconfig xconfig gconfig nconfig

ifeq ($(BR2_STATIC_LIBS),y)
define SWUPDATE_PREFER_STATIC
	$(call KCONFIG_ENABLE_OPT,CONFIG_STATIC)
endef
endif

SWUPDATE_MAKE_OPTS = \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	CONFIG_EXTRA_CFLAGS="$(TARGET_CFLAGS)" \
	CONFIG_EXTRA_LDFLAGS="$(TARGET_LDFLAGS)"

define SWUPDATE_KCONFIG_FIXUP_CMDS
	$(SWUPDATE_PREFER_STATIC)
	$(SWUPDATE_SET_LUA_VERSION)
endef

define SWUPDATE_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(SWUPDATE_MAKE_ENV) $(MAKE) $(SWUPDATE_MAKE_OPTS) -C $(@D)
endef

define SWUPDATE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/swupdate $(TARGET_DIR)/usr/bin/swupdate
	$(if $(BR2_PACKAGE_SWUPDATE_INSTALL_CLIENT_LIB), \
		$(INSTALL) -D -m 0644 $(@D)/libswupdate.so.0.1 $(TARGET_DIR)/usr/lib/;
		ln -sf libswupdate.so.0.1 $(TARGET_DIR)/usr/lib/libswupdate.so)
	$(if $(BR2_PACKAGE_SWUPDATE_INSTALL_CLIENT_TOOLS), \
		$(INSTALL) -D -m 0755 $(@D)/tools/swupdate-progress $(TARGET_DIR)/usr/bin/swupdate-progress; \
		$(INSTALL) -D -m 0755 $(@D)/tools/swupdate-client $(TARGET_DIR)/usr/bin/swupdate-client; \
		$(INSTALL) -D -m 0755 $(@D)/tools/swupdate-sysrestart $(TARGET_DIR)/usr/bin/swupdate-sysrestart)
	$(if $(BR2_PACKAGE_SWUPDATE_INSTALL_HAWKBIT_TOOLS), \
		$(INSTALL) -D -m 0755 $(@D)/tools/swupdate-sendtohawkbit $(TARGET_DIR)/usr/bin/swupdate-sendtohawkbit; \
		$(INSTALL) -D -m 0755 $(@D)/tools/swupdate-hawkbitcfg $(TARGET_DIR)/usr/bin/swupdate-hawkbitcfg)
	$(if $(BR2_PACKAGE_SWUPDATE_INSTALL_WEBSITE), \
		mkdir -p $(TARGET_DIR)/var/www/swupdate; \
		cp -dpfr $(@D)/examples/www/v2/* $(TARGET_DIR)/var/www/swupdate)
endef

# Checks to give errors that the user can understand
# Must be before we call to kconfig-package
ifeq ($(BR2_PACKAGE_SWUPDATE)$(BR_BUILDING),yy)
ifeq ($(call qstrip,$(BR2_PACKAGE_SWUPDATE_CONFIG)),)
$(error No Swupdate configuration file specified, check your BR2_PACKAGE_SWUPDATE_CONFIG setting)
endif
endif

ifeq ($(BR2_PACKAGE_SWUPDATE_INSTALL_WEBSITE),y)
define SWUPDATE_INSTALL_COMMON
	mkdir -p $(TARGET_DIR)/etc/swupdate/conf.d \
		$(TARGET_DIR)/usr/lib/swupdate/conf.d
	$(INSTALL) -D -m 755 package/swupdate/swupdate.sh \
		$(TARGET_DIR)/usr/lib/swupdate/swupdate.sh
endef
define SWUPDATE_INSTALL_INIT_SYSTEMD
	$(SWUPDATE_INSTALL_COMMON)
	$(INSTALL) -D -m 644 package/swupdate/swupdate.service \
		$(TARGET_DIR)/usr/lib/systemd/system/swupdate.service
endef
define SWUPDATE_INSTALL_INIT_SYSV
	$(SWUPDATE_INSTALL_COMMON)
	$(INSTALL) -D -m 755 package/swupdate/S80swupdate \
		$(TARGET_DIR)/etc/init.d/S80swupdate
endef
endif

$(eval $(kconfig-package))
