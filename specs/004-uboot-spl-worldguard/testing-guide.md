# U-Boot SPL WorldGuard Testing Guide

**Feature**: `004-uboot-spl-worldguard`  
**Version**: 1.0  
**Last Updated**: 2025-12-06

## Overview

This guide covers testing the U-Boot SPL WorldGuard initialization feature, enabling the boot chain:
```
U-Boot SPL → OpenSBI → U-Boot Proper → Linux
```

## Prerequisites

### Required Components

| Component | Version | Path |
|-----------|---------|------|
| QEMU | 10.1.3+ | `build/qemu/install/bin/` |
| OpenSBI | 1.5.1+ | `build/opensbi/platform/generic/firmware/` |
| U-Boot SPL | 2024.10 | `sources/u-boot/spl/` |
| U-Boot | 2024.10 | `sources/u-boot/` |
| DTB | WorldGuard | `dts/qemu-virt-worldguard.dtb` |

### Build Commands

```bash
# Build U-Boot with SPL
cd sources/u-boot
make CROSS_COMPILE=riscv64-linux-gnu- qemu-riscv64_spl_defconfig
make CROSS_COMPILE=riscv64-linux-gnu- -j$(nproc)

# Create FIT image
cd build/fit
cp ../../build/opensbi/platform/generic/firmware/fw_dynamic.bin .
cp ../../sources/u-boot/u-boot-nodtb.bin .
cp ../../dts/qemu-virt-worldguard.dtb .
../../sources/u-boot/tools/mkimage -f fit-opensbi-uboot.its u-boot-spl.itb
```

## Test Cases

### TC-001: SPL Basic Boot

**Objective**: Verify SPL boots and initializes correctly

**Command**:
```bash
timeout 10 qemu-system-riscv64 \
    -M virt -m 2G -smp 1 -nographic \
    -kernel sources/u-boot/spl/u-boot-spl.bin
```

**Expected Output**:
```
U-Boot SPL 2024.10
Trying to boot from RAM
```

**Pass Criteria**: SPL banner displayed

---

### TC-002: FIT Image Discovery

**Objective**: Verify SPL finds and parses FIT image

**Command**:
```bash
timeout 15 qemu-system-riscv64 \
    -M virt,wg=on -m 2G -smp 1 -nographic \
    -kernel sources/u-boot/spl/u-boot-spl.bin \
    -device loader,file=build/fit/u-boot-spl.itb,addr=0x80200000
```

**Expected Output**:
```
SPL: Looking for FIT at 0x80200000
SPL: Header at 0x80200000, magic=0xd00dfeed
SPL: Found FIT image!
SPL: FIT load result: 0
```

**Pass Criteria**: FIT magic (0xd00dfeed) detected

---

### TC-003: OpenSBI Boot via FIT

**Objective**: Verify complete SPL → OpenSBI boot chain

**Command**:
```bash
timeout 60 qemu-system-riscv64 \
    -M virt,wg=on -m 2G -smp 1 -nographic \
    -kernel sources/u-boot/spl/u-boot-spl.bin \
    -device loader,file=build/fit/u-boot-spl.itb,addr=0x80200000
```

**Expected Output**:
```
OpenSBI v1.5.1
Platform Name: riscv-virtio,qemu
Firmware Base: 0x80000000
Domain0 Next Address: 0x80200000
```

**Pass Criteria**: OpenSBI banner and platform info displayed

---

### TC-004: WorldGuard Detection (wg=on)

**Objective**: Verify WorldGuard is detected when enabled

**Command**:
```bash
qemu-system-riscv64 -M virt,wg=on ...
```

**Verification**: Check SPL debug output for WorldGuard detection
```
WorldGuard: 'riscv,worldguard' node found in DT
```

---

### TC-005: WorldGuard Disabled (wg=off)

**Objective**: Verify graceful skip when WorldGuard disabled

**Command**:
```bash
qemu-system-riscv64 -M virt,wg=off ...
```

**Verification**: SPL boots without errors, skips WorldGuard init

---

### TC-006: Direct OpenSBI Boot (Comparison)

**Objective**: Verify direct boot mode still works

**Command**:
```bash
timeout 30 qemu-system-riscv64 \
    -M virt,wg=on -m 2G -smp 1 -nographic \
    -bios build/opensbi/platform/generic/firmware/fw_dynamic.bin \
    -kernel sources/u-boot/u-boot.bin \
    -dtb dts/qemu-virt-worldguard.dtb
```

**Expected Output**: OpenSBI + U-Boot console

---

## Memory Map

| Address | Component | Size |
|---------|-----------|------|
| 0x80000000 | OpenSBI | ~317KB |
| 0x80200000 | FIT Image / U-Boot | ~885KB |
| 0x81000000 | U-Boot SPL | ~40KB |
| 0x85000000 | SPL BSS | 1MB |

## Troubleshooting

### Issue: SPL crashes immediately
**Cause**: SPL and OpenSBI at same address (0x80000000)
**Solution**: Use `-kernel` instead of `-bios`, ensure SPL at 0x81000000

### Issue: "No device tree specified"
**Cause**: FIT image missing DTB or fdt_addr not set
**Solution**: Verify FIT contains fdt image, check spl_image->fdt_addr

### Issue: OpenSBI doesn't output
**Cause**: DTB missing UART configuration
**Solution**: Use complete QEMU virt DTB with serial node

### Issue: FIT magic not found
**Cause**: FIT not loaded at CONFIG_SPL_LOAD_FIT_ADDRESS
**Solution**: Verify loader address matches 0x80200000

## Quick Test Script

```bash
#!/bin/bash
# quick-test-spl.sh

QEMU=build/qemu/install/bin/qemu-system-riscv64
SPL=sources/u-boot/spl/u-boot-spl.bin
FIT=build/fit/u-boot-spl.itb

echo "=== Testing SPL WorldGuard Boot Chain ==="
timeout 30 $QEMU \
    -M virt,wg=on \
    -m 2G -smp 1 -nographic \
    -kernel $SPL \
    -device loader,file=$FIT,addr=0x80200000
```

## References

- [U-Boot SPL Documentation](https://docs.u-boot.org/en/latest/develop/spl.html)
- [OpenSBI fw_dynamic](https://github.com/riscv-software-src/opensbi/blob/master/docs/firmware/fw_dynamic.md)
- [RISC-V WorldGuard Spec](https://github.com/riscv/riscv-worldguard)
