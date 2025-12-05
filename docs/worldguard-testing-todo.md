# WorldGuard Testing TODO

This document outlines the remaining tasks for comprehensive WorldGuard testing.

## Completed

### QEMU Default wgChecker Configuration ✅

DRAM wgChecker is configured with default slots when `wg-hwbypass=off`:

| Slot | Address Range | Access |
|------|--------------|--------|
| 1 | 0x80000000 - 0x9FFFFFFF (512MB) | All worlds RW (shared) |
| 2 | 0xA0000000 - 0xAFFFFFFF (256MB) | W0+W3 (boot+trusted) |
| 3 | 0xB0000000 - 0xBFFFFFFF (256MB) | W0+W2+W3 |
| 4 | 0xC0000000 - 0xCFFFFFFF (256MB) | W0+W1+W3 |
| 5 | 0xD0000000 - 0xFFFFFFFF (remainder) | W0+W3 |

**Test Command:**
```bash
./build/qemu/qemu-system-riscv64 \
    -M virt,wg=on,wg-nworlds=4,wg-trustedwid=3,wg-hwbypass=off \
    -m 2G -smp 4 -nographic \
    -bios ./build/opensbi/platform/generic/firmware/fw_dynamic.bin \
    -kernel ./build/u-boot/u-boot.bin \
    -drive file=./build/buildroot/images/sdcard.img,format=raw,id=hd0,if=none \
    -device virtio-blk-device,drive=hd0 \
    -netdev user,id=net0 \
    -device virtio-net-device,netdev=net0
```

### Bare-metal Test Framework ✅

Created `tests/worldguard/` with the following components:

| File | Description |
|------|-------------|
| `worldguard.h` | WorldGuard CSR definitions (mlwid, slwid, mwiddeleg) |
| `wgchecker.h` | wgChecker MMIO register definitions and access functions |
| `boot.S` | Entry point with trap handler for access fault testing |
| `main.c` | Test cases for memory access, CSR, and wgChecker |
| `linker.ld` | Linker script for QEMU virt machine |
| `Makefile` | Build and run targets with WorldGuard options |

**Build and Run:**
```bash
cd tests/worldguard
make              # Build test.elf
make run          # Run with hwbypass=off
make run-bypass   # Run with hwbypass=on
make run-trace    # Run with wgChecker trace
```

**Current Test Status:**
- ✅ T1: Basic DRAM read/write
- ⏭️ T2: WorldGuard CSR tests (requires CPU model patches)
- ⏭️ T3-4: wgChecker MMIO tests (requires system initialization)

**Note:** WorldGuard CSR (mlwid, slwid) and wgChecker MMIO access are not
available in bare-metal context. These require either:
1. Additional QEMU CPU model patches for CSR support
2. Full boot chain (OpenSBI/U-Boot/Linux) for MMIO initialization

---

### Expected WID Assignments
| Mode | WID | Description |
|------|-----|-------------|
| M-mode (OpenSBI) | 3 | Trusted, full access |
| S-mode (U-Boot/Linux) | 2 | Kernel access |
| U-mode (Applications) | 1 | Limited access |
| Reserved | 0 | Boot WID (should transition) |

### Testing
1. Boot OpenSBI with WorldGuard patch
2. Verify CSR values from S-mode (Linux)
3. Test memory access patterns across worlds

---

## TODO: Bare-metal WorldGuard Test Program

### Goal
Create a standalone M-mode test program to verify WorldGuard functionality.

### Implementation Steps

1. **Create Test Directory**
   ```
   tests/worldguard/
   ├── Makefile
   ├── boot.S          # Entry point, set up SP
   ├── main.c          # Test logic
   ├── wgchecker.h     # wgChecker register definitions
   ├── worldguard.h    # CSR definitions
   └── linker.ld       # Linker script for QEMU
   ```

2. **wgchecker.h - Register Definitions**
   ```c
   #define WGC_SLOT_ADDR(n)  (WGC_BASE + 0x100 + (n) * 0x20)
   #define WGC_SLOT_PERM(n)  (WGC_BASE + 0x100 + (n) * 0x20 + 0x08)
   #define WGC_SLOT_CFG(n)   (WGC_BASE + 0x100 + (n) * 0x20 + 0x10)
   
   #define WGC_CFG_A_OFF     0
   #define WGC_CFG_A_TOR     1
   #define WGC_CFG_A_NAPOT   3
   ```

3. **Test Cases**
   - **T1: WID Change**
     - Write to mlwid CSR
     - Verify change took effect
   
   - **T2: Access Allowed Region**
     - Set WID to world with access
     - Read/Write to allowed region
     - Verify no error
   
   - **T3: Access Denied Region**
     - Set WID to world without access
     - Try to access denied region
     - Catch exception, verify wgChecker error registers
   
   - **T4: wgChecker Slot Programming**
     - Read default slot configuration
     - Modify slot permissions
     - Verify access patterns change

4. **Expected Test Output**
   ```
   === WorldGuard Bare-metal Test ===
   [PASS] T1: WID change mlwid=0 -> mlwid=3
   [PASS] T2: Read/Write to 0x80000000 with WID=3
   [PASS] T3: Access denied to 0xC0000000 with WID=1
   [PASS] T4: wgChecker slot programming
   === All tests passed ===
   ```

### Running the Test
```bash
# Build bare-metal test
make -C tests/worldguard

# Run with QEMU
./build/qemu/qemu-system-riscv64 \
    -M virt,wg=on,wg-hwbypass=off \
    -m 256M -smp 1 -nographic \
    -bios tests/worldguard/test.elf
```

---

## References

- [RISC-V WorldGuard Spec](https://github.com/riscv/riscv-worldguard)
- [OpenSBI Documentation](https://github.com/riscv-software-src/opensbi)
- QEMU WorldGuard implementation: `sources/qemu/hw/misc/riscv_wgchecker.c`
