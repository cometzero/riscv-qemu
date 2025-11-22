################################################################################
#
# hello_riscv
#
################################################################################

HELLO_RISCV_VERSION = 1.0
HELLO_RISCV_SITE = $(BR2_EXTERNAL_RISCV_BOOT_VERIFY_PATH)/package/hello_riscv
HELLO_RISCV_SITE_METHOD = local

define HELLO_RISCV_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) -o $(@D)/hello_riscv $(@D)/hello_riscv.c
endef

define HELLO_RISCV_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/hello_riscv $(TARGET_DIR)/usr/bin/hello_riscv
endef

$(eval $(generic-package))
