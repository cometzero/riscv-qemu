# OpenSBI WorldGuard Testing Guide

**Feature**: `003-opensbi-worldguard`  
**Version**: 1.0  
**Date**: 2025-12-06

## Overview

This guide describes how to test the OpenSBI WorldGuard implementation, including CSR initialization, Device Tree parsing, and wgChecker MMIO programming.

## Prerequisites

- QEMU v10.1.3 with WorldGuard patches (built from `002-qemu-worldguard` branch)
- OpenSBI v1.7 with WorldGuard support (from `003-opensbi-worldguard` branch)
- RISC-V toolchain: `riscv64-linux-gnu-gcc`
- Device Tree Compiler: `dtc`

## Test Environment Setup

### 1. Build OpenSBI with WorldGuard

```bash
cd sources/opensbi
make PLATFORM=generic CROSS_COMPILE=riscv64-linux-gnu- -j8
```

**Expected**: `platform/generic/firmware/fw_dynamic.bin` created

### 2. Build U-Boot

```bash
cd sources/u-boot
cp ../../build/u-boot/.config .
make CROSS_COMPILE=riscv64-linux-gnu- -j8
```

**Expected**: `u-boot.bin` created

---

## Test Cases

### Test 1: Basic WorldGuard Detection

**Purpose**: Verify OpenSBI detects WorldGuard when `wg=on`

**Command**:
```bash
timeout 10 ./build/qemu/install/bin/qemu-system-riscv64 \
    -M virt,wg=on \
    -m 2G -smp 1 -nographic \
    -bios sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
    -kernel ./build/u-boot/u-boot.bin 2>&1 | head -30
```

**Expected Output**:
```
WorldGuard: No FDT node found, using defaults
WorldGuard: detected, current mlwid=3
WorldGuard: enabled, mlwid=3, mwiddeleg=0x6
```

**Pass Criteria**:
- ✓ `WorldGuard: detected` message appears
- ✓ `mlwid=3` (trusted WID)
- ✓ `mwiddeleg=0x6` (delegates WID 1,2 to S-mode)

---

### Test 2: WorldGuard Disabled Boot

**Purpose**: Verify compatibility when WorldGuard is disabled

**Command**:
```bash
timeout 8 ./build/qemu/install/bin/qemu-system-riscv64 \
    -M virt \
    -m 2G -smp 1 -nographic \
    -bios sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
    -kernel ./build/u-boot/u-boot.bin 2>&1 | head -30
```

**Expected Output**:
- No WorldGuard messages
- Normal OpenSBI boot

**Pass Criteria**:
- ✓ No WorldGuard log output
- ✓ OpenSBI boots successfully
- ✓ U-Boot starts normally

---

### Test 3: Device Tree Configuration

**Purpose**: Verify OpenSBI parses WorldGuard DT node

**Prerequisites**:
```bash
# Create custom DTB with WorldGuard nodes
dtc -I dts -O dtb -o dts/qemu-virt-worldguard.dtb dts/qemu-virt-worldguard.dts
```

**Command**:
```bash
timeout 10 ./build/qemu/install/bin/qemu-system-riscv64 \
    -M virt,wg=on \
    -m 2G -smp 1 -nographic \
    -dtb dts/qemu-virt-worldguard.dtb \
    -bios sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
    -kernel ./build/u-boot/u-boot.bin 2>&1 | head -40
```

**Expected Output**:
```
WorldGuard: FDT config - nworlds=4, trustedwid=3
WorldGuard: detected, current mlwid=3
WorldGuard: enabled, mlwid=3, mwiddeleg=0x6
```

**Pass Criteria**:
- ✓ `FDT config` message with correct values
- ✓ nworlds=4, trustedwid=3

---

### Test 4: wgChecker Slot Programming

**Purpose**: Verify OpenSBI programs wgChecker slots from DT

**Prerequisites**: Same as Test 3 (custom DTB)

**Command**:
```bash
timeout 10 ./build/qemu/install/bin/qemu-system-riscv64 \
    -M virt,wg=on \
    -m 2G -smp 1 -nographic \
    -dtb dts/qemu-virt-worldguard.dtb \
    -bios sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
    -kernel ./build/u-boot/u-boot.bin 2>&1 | grep -E "WorldGuard|slot\["
```

**Expected Output**:
```
WorldGuard: FDT config - nworlds=4, trustedwid=3
WorldGuard: detected, current mlwid=3
WorldGuard: Programming 3 wgChecker slots
  slot[1]: addr=0xa0000000 perm=0xff cfg=0x1
  slot[2]: addr=0xb0000000 perm=0xc3 cfg=0x1
  slot[3]: addr=0xc0000000 perm=0xf3 cfg=0x1
WorldGuard: enabled, mlwid=3, mwiddeleg=0x6
```

**Pass Criteria**:
- ✓ `Programming 3 wgChecker slots` message
- ✓ All 3 slots show correct addresses
- ✓ Permissions match DT configuration

**Slot Details**:
| Slot | Address | Size | Permissions |
|------|---------|------|-------------|
| 1 | 0x80000000-0xA0000000 | 512MB | All RW (0xFF) |
| 2 | 0xA0000000-0xB0000000 | 256MB | W0,W3 RW (0xC3) |
| 3 | 0xB0000000-0xC0000000 | 256MB | W0,W2,W3 RW (0xF3) |

---

### Test 5: Full Boot Chain

**Purpose**: Verify complete boot with WorldGuard

**Command**:
```bash
timeout 20 ./scripts/run-qemu-worldguard.sh 2>&1 | head -50
```

**Expected**: OpenSBI → U-Boot → Linux boot sequence

**Pass Criteria**:
- ✓ OpenSBI WorldGuard initialization
- ✓ U-Boot banner appears
- ✓ No WorldGuard-related errors

---

## Troubleshooting

### Issue: "WorldGuard not detected"
**Solution**: Verify QEMU has `-M virt,wg=on` option

### Issue: "No wgChecker slots programmed"
**Solution**: Ensure using custom DTB with `-dtb dts/qemu-virt-worldguard.dtb`

### Issue: U-Boot hangs after OpenSBI
**Possible Causes**:
- slwid CSR access without proper WorldGuard delegation
- Memory region permission issues with wgChecker

**Debug**:
```bash
# Add QEMU debug logging
-d guest_errors,unimp
```

---

## Quick Test Script

```bash
#!/bin/bash
# Quick verification of all test cases

echo "=== Test 1: WorldGuard Detection ==="
timeout 10 ./build/qemu/install/bin/qemu-system-riscv64 \
    -M virt,wg=on -m 2G -smp 1 -nographic \
    -bios sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
    -kernel ./build/u-boot/u-boot.bin 2>&1 | grep "WorldGuard:"

echo -e "\n=== Test 4: wgChecker Slots ==="
timeout 10 ./build/qemu/install/bin/qemu-system-riscv64 \
    -M virt,wg=on -m 2G -smp 1 -nographic \
    -dtb dts/qemu-virt-worldguard.dtb \
    -bios sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
    -kernel ./build/u-boot/u-boot.bin 2>&1 | grep -E "slot\["
```

---

## References

- [OpenSBI WorldGuard Spec](./spec.md)
- [Implementation Plan](./plan.md)
- [WorldGuard QEMU Integration](../../docs/worldguard.md)
