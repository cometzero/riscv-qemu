# Makefile for RISC-V QEMU Boot Chain Project

.PHONY: all clean help qemu-run qemu-build uboot-build opensbi-build linux-build buildroot-build

all: build-all

help:
	@echo "RISC-V QEMU Boot Chain - Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all             Build all components (QEMU, OpenSBI, U-Boot, Linux, Buildroot)"
	@echo "  clean           Clean all build artifacts"
	@echo "  qemu-run        Run the full boot chain in QEMU"
	@echo ""
	@echo "Component Builds:"
	@echo "  qemu-build      Build QEMU"
	@echo "  uboot-build     Build U-Boot"
	@echo "  opensbi-build   Build OpenSBI"
	@echo "  linux-build     Build Linux Kernel"
	@echo "  buildroot-build Build Buildroot Rootfs"
	@echo ""
	@echo "Component Rebuilds (Incremental):"
	@echo "  uboot-rebuild     Rebuild U-Boot"
	@echo "  opensbi-rebuild   Rebuild OpenSBI"
	@echo "  linux-rebuild     Rebuild Linux Kernel"
	@echo "  buildroot-rebuild Rebuild Buildroot"
	@echo ""
	@echo "Configuration:"
	@echo "  uboot-config      Run U-Boot menuconfig"
	@echo "  linux-config      Run Linux menuconfig"
	@echo "  buildroot-config  Run Buildroot menuconfig"
	@echo ""

build-all:
	./scripts/build-all.sh

clean:
	./scripts/clean.sh

qemu-run:
	./scripts/run-qemu.sh

qemu-build:
	./scripts/build-qemu.sh

uboot-build:
	./scripts/build-uboot.sh

opensbi-build:
	./scripts/build-opensbi.sh

linux-build:
	./scripts/build-linux.sh

buildroot-build:
	./scripts/build-buildroot.sh

uboot-rebuild:
	./scripts/rebuild-uboot.sh

opensbi-rebuild:
	./scripts/rebuild-opensbi.sh

linux-rebuild:
	./scripts/rebuild-linux.sh

buildroot-rebuild:
	./scripts/rebuild-buildroot.sh

uboot-config:
	./scripts/menuconfig-uboot.sh

linux-config:
	./scripts/menuconfig-linux.sh

buildroot-config:
	./scripts/menuconfig-buildroot.sh
