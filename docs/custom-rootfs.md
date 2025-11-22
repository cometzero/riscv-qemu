# Custom Rootfs Integration Guide

This document explains how to customize the Buildroot root filesystem, add custom packages, and generate bootable disk images.

## Directory Structure

The project uses Buildroot's `BR2_EXTERNAL` mechanism to keep custom configurations separate from the Buildroot source tree.

```
configs/buildroot/
├── board/
│   ├── genimage.cfg        # Partition layout for sdcard.img
│   └── post-image.sh       # Script to run genimage after build
├── external/
│   ├── Config.in           # Top-level Config.in for external tree
│   ├── external.desc       # Description of the external tree
│   ├── external.mk         # Top-level Makefile for external tree
│   └── package/
│       └── hello_riscv/    # Custom package example
│           ├── Config.in
│           ├── hello_riscv.c
│           ├── hello_riscv.mk
│           └── LICENSE
└── riscv64_virt_defconfig  # Custom Buildroot configuration
```

## Adding a Custom Package

To add a new package (e.g., `my_package`):

1.  **Create Package Directory**:
    ```bash
    mkdir -p configs/buildroot/external/package/my_package
    ```

2.  **Create Config.in**:
    `configs/buildroot/external/package/my_package/Config.in`:
    ```kconfig
    config BR2_PACKAGE_MY_PACKAGE
        bool "my_package"
        help
          Description of my package.
    ```

3.  **Create Makefile**:
    `configs/buildroot/external/package/my_package/my_package.mk`:
    ```makefile
    MY_PACKAGE_VERSION = 1.0
    MY_PACKAGE_SITE = $(BR2_EXTERNAL_RISCV_BOOT_VERIFY_PATH)/package/my_package
    MY_PACKAGE_SITE_METHOD = local
    MY_PACKAGE_LICENSE = MIT
    MY_PACKAGE_LICENSE_FILES = LICENSE

    define MY_PACKAGE_BUILD_CMDS
        $(TARGET_CC) $(TARGET_CFLAGS) -o $(@D)/my_app $(@D)/my_source.c
    endef

    define MY_PACKAGE_INSTALL_TARGET_CMDS
        $(INSTALL) -D -m 0755 $(@D)/my_app $(TARGET_DIR)/usr/bin/my_app
    endef

    $(eval $(generic-package))
    ```

4.  **Update Top-level Config.in**:
    Add `source "$BR2_EXTERNAL_RISCV_BOOT_VERIFY_PATH/package/my_package/Config.in"` to `configs/buildroot/external/Config.in`.

5.  **Enable Package**:
    Run `make buildroot-menuconfig` (or `./scripts/menuconfig-buildroot.sh`) and select your package under "External options".

## Disk Image Generation

The project uses `genimage` to create a partitioned `sdcard.img` containing:
1.  **Boot Partition (vfat)**: Contains `Image` (kernel) and `extlinux.conf`.
2.  **Rootfs Partition (ext2)**: Contains the root filesystem.

### Configuration
- **Layout**: Defined in `configs/buildroot/board/genimage.cfg`.
- **Post-processing**: Handled by `configs/buildroot/board/post-image.sh`.

### Rebuilding
To apply changes to the image generation logic or custom packages:
```bash
./scripts/build-buildroot.sh
```
Or for incremental rebuilds:
```bash
./scripts/rebuild-buildroot.sh
```
