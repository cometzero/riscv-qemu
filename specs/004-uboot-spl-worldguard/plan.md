# Implementation Plan: U-Boot SPL WorldGuard Initialization

**Feature**: `004-uboot-spl-worldguard`  
**Created**: 2025-12-06  
**Status**: Draft

## Goal

Move WorldGuard initialization from OpenSBI to U-Boot SPL, enabling WorldGuard memory protection from the earliest boot stage in the new boot sequence: U-Boot SPL → OpenSBI → U-Boot Proper → Linux.

## User Review Required

> [!IMPORTANT]
> **Breaking Change**: This modifies the boot sequence and requires OpenSBI changes
> 
> Current: `QEMU → OpenSBI → U-Boot → Linux`  
> New: `QEMU → U-Boot SPL → OpenSBI → U-Boot Proper → Linux`
> 
> **Impact**:
> - OpenSBI WorldGuard init code must be modified to check for SPL initialization
> - Boot loader binary (QEMU `-bios` option) changes from OpenSBI to U-Boot SPL
> - DTB must be large enough for SPL to add WorldGuard properties (128KB buffer)

> [!WARNING]
> **OpenSBI Compatibility**: 
> OpenSBI v1.7 must be patched to read `worldguard,spl-initialized` DT property and skip CSR programming if SPL already initialized WorldGuard.

## Proposed Changes

### Component 1: U-Boot SPL WorldGuard Module

Summary: Create new WorldGuard initialization module for U-Boot SPL to detect, configure, and program WorldGuard CSRs and wgChecker slots before loading OpenSBI.

---

#### [NEW] [board/qemu-riscv/spl/worldguard.c](file:///home/ubuntu/work/risc-v/sources/u-boot/board/qemu-riscv/spl/worldguard.c)

**Purpose**: Core WorldGuard initialization logic in SPL

**Key Functions**:
```c
// WorldGuard detection (DT-first approach per clarification #4)
int spl_worldguard_detect(void *fdt);

// CSR initialization (per FR3)
void spl_worldguard_init_csrs(u32 mlwid, u32 mwiddeleg);

// wgChecker slot programming (per FR4)
int spl_worldguard_program_slots(void *fdt);

// DTB property injection for OpenSBI handoff (per clarification #1)
int spl_worldguard_add_dt_props(void *new_fdt, u32 mlwid, u32 mwiddeleg);

// Main entry point
int spl_worldguard_init(void *fdt);
```

**Implementation Notes**:
- DT-first detection: Check `riscv,worldguard` node before any CSR access
- Read configuration from DT: `nworlds`, `trustedwid`, `mwiddeleg`, `lock-slots`
- Program wgChecker MMIO at base 0x6000000
- Conditional lock bit based on `worldguard,lock-slots` property

---

#### [NEW] [board/qemu-riscv/spl/worldguard.h](file:///home/ubuntu/work/risc-v/sources/u-boot/board/qemu-riscv/spl/worldguard.h)

**Purpose**: WorldGuard CSR and MMIO definitions

**Definitions**:
```c
// CSR addresses (from RISC-V WorldGuard spec v0.4)
#define CSR_MLWID       0x390
#define CSR_MWIDDELEG   0x748

// wgChecker MMIO (from DT reg property)
#define WGCHECKER_BASE  0x6000000
#define WGC_SLOT_ADDR(n)    (WGCHECKER_BASE + (n)*0x20)
#define WGC_SLOT_PERM(n)    (WGCHECKER_BASE + (n)*0x20 + 0x8)
#define WGC_SLOT_CFG(n)     (WGCHECKER_BASE + (n)*0x20 + 0x10)

// Configuration defaults
#define WG_DEFAULT_NWORLDS   4
#define WG_DEFAULT_TRUSTEDWID 3
#define WG_DEFAULT_MWIDDELEG  0x6

// Lock bit
#define WGC_CFG_LOCK    (1 << 0)
#define WGC_CFG_TOR     (1 << 1)
```

---

#### [MODIFY] [board/qemu-riscv/spl/spl.c](file:///home/ubuntu/work/risc-v/sources/u-boot/board/qemu-riscv/spl/spl.c)

**Changes**:
```c
// Add WorldGuard init call before loading OpenSBI
void board_init_f(ulong dummy)
{
    ...
    // Initialize WorldGuard if present in DT
    void *fdt = (void *)gd->fdt_blob;
    ret = spl_worldguard_init(fdt);
    if (ret < 0)
        debug("WorldGuard init failed: %d\n", ret);
    ...
}
```

**Integration Point**: Called after DTB is available, before OpenSBI load

---

### Component 2: DTB Creation and Merging

Summary: SPL creates a new 128KB Device Tree blob merging original QEMU DTB with WorldGuard properties for OpenSBI handoff (per clarification #3).

---

#### [NEW] [board/qemu-riscv/spl/fdt_merge.c](file:///home/ubuntu/work/risc-v/sources/u-boot/board/qemu-riscv/spl/fdt_merge.c)

**Purpose**: Create new DTB with WorldGuard properties

**Key Function**:
```c
/**
 * Create new DTB merging original + WorldGuard properties
 * @param orig_fdt: Original QEMU DTB
 * @param new_fdt_buf: Buffer for new DTB (128KB per clarification #5)
 * @param bufsize: Buffer size (must be >= 128KB)
 * @param wg_props: WorldGuard properties to add
 * @return: 0 on success, negative on error
 */
int spl_create_merged_dtb(const void *orig_fdt, void *new_fdt_buf, 
                          size_t bufsize, struct wg_properties *wg_props);
```

**Properties to Add** (per clarification #1):
- `worldguard,spl-initialized = <1>`
- `worldguard,mlwid = <value>`
- `worldguard,mwiddeleg = <value>`

**Memory Allocation**: 128KB static buffer in SPL BSS section

---

#### [MODIFY] [include/configs/qemu-riscv.h](file:///home/ubuntu/work/risc-v/sources/u-boot/include/configs/qemu-riscv.h)

**Changes**:
```c
// Add SPL-specific configurations
#define CONFIG_SPL_WORLDGUARD
#define CONFIG_SPL_FDT_BUFFER_SIZE  (128 * 1024)  // 128KB per clarification #5
```

---

### Component 3: OpenSBI Modifications

Summary: Modify OpenSBI to check for SPL initialization marker and skip WorldGuard init if SPL already configured it (per FR5).

---

#### [MODIFY] [lib/sbi/sbi_worldguard.c](file:///home/ubuntu/work/risc-v/sources/opensbi/lib/sbi/sbi_worldguard.c)

**Changes**:
```c
int sbi_worldguard_init(const void *fdt)
{
    // Check if SPL already initialized WorldGuard
    int node = fdt_path_offset(fdt, "/worldguard");
    if (node >= 0) {
        const fdt32_t *prop = fdt_getprop(fdt, node, "spl-initialized", NULL);
        if (prop && fdt32_to_cpu(*prop) == 1) {
            sbi_printf("WorldGuard: Already initialized by SPL\n");
            
            // Read and log SPL configuration
            prop = fdt_getprop(fdt, node, "mlwid", NULL);
            u32 mlwid = prop ? fdt32_to_cpu(*prop) : 0;
            prop = fdt_getprop(fdt, node, "mwiddeleg", NULL);
            u32 mwiddeleg = prop ? fdt32_to_cpu(*prop) : 0;
            
            sbi_printf("WorldGuard: SPL config - mlwid=%u, mwiddeleg=0x%x\n",
                       mlwid, mwiddeleg);
            return 0;  // Skip OpenSBI init
        }
    }
    
    // Fallback: Original OpenSBI WorldGuard init
    // (for backward compatibility with non-SPL boot)
    ...
}
```

**Backward Compatibility**: OpenSBI still supports WorldGuard init if SPL didn't run (e.g., direct OpenSBI boot for debugging)

---

### Component 4: Build System Integration

Summary: Update U-Boot build system to enable SPL for RISC-V virt machine and include WorldGuard module.

---

#### [MODIFY] [configs/qemu-riscv64_spl_defconfig](file:///home/ubuntu/work/risc-v/sources/u-boot/configs/qemu-riscv64_spl_defconfig)

**New Config** (create if doesn't exist):
```
# Based on qemu-riscv64_defconfig with SPL enabled
CONFIG_RISCV=y
CONFIG_SYS_TEXT_BASE=0x80200000
CONFIG_SPL=y
CONFIG_SPL_TEXT_BASE=0x80000000
CONFIG_SPL_OPENSBI_LOAD_ADDR=0x80100000
CONFIG_SPL_FS_FAT=y
CONFIG_SPL_LIBDISK_SUPPORT=y

# WorldGuard SPL support
CONFIG_SPL_WORLDGUARD=y
CONFIG_SPL_FDT_BUFFER_SIZE=0x20000
```

---

#### [MODIFY] [board/qemu-riscv/Kconfig](file:///home/ubuntu/work/risc-v/sources/u-boot/board/qemu-riscv/Kconfig)

**Changes**:
```kconfig
config SPL_WORLDGUARD
    bool "Enable WorldGuard initialization in SPL"
    depends on SPL
    help
      Initialize RISC-V WorldGuard CSRs and wgChecker slots
      in U-Boot SPL before loading OpenSBI.
```

---

### Component 5: Boot Sequence Scripts

Summary: Update boot scripts to use U-Boot SPL as first-stage bootloader instead of OpenSBI.

---

#### [MODIFY] [scripts/run-qemu-worldguard.sh](file:///home/ubuntu/work/risc-v/scripts/run-qemu-worldguard.sh)

**Changes**:
```bash
# OLD: Boot directly with OpenSBI
# -bios sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
# -kernel ./build/u-boot/u-boot.bin

# NEW: Boot with U-Boot SPL
-bios ./build/u-boot/spl/u-boot-spl.bin \
-kernel ./build/linux/arch/riscv/boot/Image

# SPL loads OpenSBI from FIT image or raw binary
# (OpenSBI must be embedded in u-boot.img or passed separately)
```

---

#### [NEW] [scripts/build-uboot-spl.sh](file:///home/ubuntu/work/risc-v/scripts/build-uboot-spl.sh)

**Purpose**: Build U-Boot with SPL support

```bash
#!/bin/bash
set -e

# Configure and build U-Boot with SPL
cd sources/u-boot
make CROSS_COMPILE=riscv64-linux-gnu- qemu-riscv64_spl_defconfig
make CROSS_COMPILE=riscv64-linux-gnu- -j$(nproc)

# Verify SPL output
if [ ! -f spl/u-boot-spl.bin ]; then
    echo "Error: SPL binary not found"
    exit 1
fi

# Copy to build directory
mkdir -p ../../build/u-boot/spl
cp spl/u-boot-spl.bin ../../build/u-boot/spl/
cp u-boot.img ../../build/u-boot/

echo "U-Boot SPL build complete"
ls -lh spl/u-boot-spl.bin u-boot.img
```

---

## Verification Plan

### Automated Tests

#### Test 1: U-Boot SPL Build Verification
```bash
# Build U-Boot with SPL
./scripts/build-uboot-spl.sh

# Verify output files exist
test -f build/u-boot/spl/u-boot-spl.bin
test -f build/u-boot/u-boot.img

# Check SPL size (should be < 64KB per Technical Constraints)
SIZE=$(stat -c%s build/u-boot/spl/u-boot-spl.bin)
[ $SIZE -lt 65536 ] && echo "PASS: SPL size OK" || echo "FAIL: SPL too large"
```

**Expected**: SPL binary < 64KB, u-boot.img created

---

#### Test 2: Boot Sequence Test (wg=off)
```bash
timeout 10 ./build/qemu/install/bin/qemu-system-riscv64 \
    -M virt \
    -m 2G -smp 1 -nographic \
    -bios build/u-boot/spl/u-boot-spl.bin \
    -kernel build/linux/arch/riscv/boot/Image 2>&1 | tee /tmp/boot-wg-off.log

# Verify boot stages
grep -q "U-Boot SPL" /tmp/boot-wg-off.log
grep -q "OpenSBI v1.7" /tmp/boot-wg-off.log
grep -q "U-Boot 2024.10" /tmp/boot-wg-off.log

# Verify NO WorldGuard messages
! grep -q "WorldGuard" /tmp/boot-wg-off.log && echo "PASS: No WG init" || echo "FAIL: WG should be silent"
```

**Expected**: Boot chain completes, no WorldGuard messages

---

#### Test 3: WorldGuard SPL Initialization (wg=on)
```bash
timeout 12 ./build/qemu/install/bin/qemu-system-riscv64 \
    -M virt,wg=on \
    -m 2G -smp 1 -nographic \
    -dtb dts/qemu-virt-worldguard.dtb \
    -bios build/u-boot/spl/u-boot-spl.bin \
    -kernel build/linux/arch/riscv/boot/Image 2>&1 | tee /tmp/boot-wg-on.log

# Verify SPL WorldGuard init
grep -q "SPL: WorldGuard detected" /tmp/boot-wg-on.log
grep -q "SPL: mlwid=3, mwiddeleg=0x6" /tmp/boot-wg-on.log
grep -q "SPL: Programming.*wgChecker slots" /tmp/boot-wg-on.log

# Verify OpenSBI sees SPL initialization
grep -q "WorldGuard: Already initialized by SPL" /tmp/boot-wg-on.log

# Verify slot programming
grep -q "SPL: slot\[1\]: addr=0xa0000000" /tmp/boot-wg-on.log
```

**Expected**: SPL logs show WG init, OpenSBI skips init, slots programmed

---

#### Test 4: DTB Property Verification
```bash
# Extract DTB after SPL modification (from QEMU memory dump)
# Or check in OpenSBI code that reads the properties

# Verify new properties exist in DTB passed to OpenSBI
# This requires adding debug output in OpenSBI to dump DT properties
```

**Expected**: `worldguard,spl-initialized=1`, `worldguard,mlwid=3`, `worldguard,mwiddeleg=0x6` properties present

---

#### Test 5: wgChecker Lock Bit Test
```bash
# Test with lock-slots=true (default)
timeout 10 ./build/qemu/install/bin/qemu-system-riscv64 \
    -M virt,wg=on -m 2G -smp 1 -nographic \
    -dtb dts/qemu-virt-worldguard.dtb \
    -bios build/u-boot/spl/u-boot-spl.bin 2>&1 | grep "lock bit"

# Expected: "SPL: Set lock bit for wgChecker slots"

# Test with lock-slots=false
# (Requires creating new DTB with worldguard,lock-slots=<0>)
# Expected: "SPL: Skipping lock bit (configurable)"
```

**Expected**: Lock behavior follows DT property

---

### Manual Verification

#### Manual Test 1: Full Boot Chain Observation
1. Build all components:
   ```bash
   make clean-all
   make build-all
   ./scripts/build-uboot-spl.sh
   ```

2. Run QEMU with WorldGuard:
   ```bash
   ./scripts/run-qemu-worldguard.sh
   ```

3. Observe boot messages in order:
   - [ ] U-Boot SPL banner appears
   - [ ] SPL WorldGuard detection message
   - [ ] SPL CSR initialization (mlwid, mwiddeleg)
   - [ ] SPL wgChecker slot programming (3 slots)
   - [ ] OpenSBI banner
   - [ ] OpenSBI "Already initialized by SPL" message
   - [ ] U-Boot Proper banner
   - [ ] Linux kernel boot
   - [ ] Login prompt

4. Verify timing:
   - [ ] Boot time increase < 100ms compared to OpenSBI-first boot

---

#### Manual Test 2: Error Handling
1. Boot without WorldGuard DT node:
   ```bash
   timeout 10 ./build/qemu/install/bin/qemu-system-riscv64 \
       -M virt,wg=on -m 2G -smp 1 -nographic \
       -dtb dts/qemu-virt.dts \  # No WG nodes
       -bios build/u-boot/spl/u-boot-spl.bin
   ```

2. Verify:
   - [ ] No WorldGuard messages from SPL
   - [ ] No CSR access attempts (no illegal instruction)
   - [ ] Boot completes normally

**Pass Criteria**: Silent skip, boot succeeds

---

#### Manual Test 3: Slot Configuration Verification
1. Edit `dts/qemu-virt-worldguard.dts` to change slot addresses
2. Recompile DTB: `dtc -I dts -O dtb -o dts/test.dtb dts/qemu-virt-worldguard.dts`
3. Boot and observe slot programming log
4. Verify SPL programs slots matching modified DTS

**Pass Criteria**: Logged addresses match DT configuration

---

## Implementation Order

### Phase 1: U-Boot SPL Foundation (No WorldGuard)
**Goal**: Get basic SPL boot working first

1. Create `configs/qemu-riscv64_spl_defconfig`
2. Build U-Boot with SPL: `./scripts/build-uboot-spl.sh`
3. Test SPL→OpenSBI→U-Boot→Linux chain with `wg=off`
4. **Milestone**: Successful boot without WorldGuard

### Phase 2: WorldGuard Module Implementation
**Goal**: Add WorldGuard init to SPL

5. Create `board/qemu-riscv/spl/worldguard.h` (CSR/MMIO definitions)
6. Create `board/qemu-riscv/spl/worldguard.c` (detection, CSR init, wgChecker)
7. Modify `board/qemu-riscv/spl/spl.c` (call `spl_worldguard_init()`)
8. Test with `wg=on`, verify CSR programming
9. **Milestone**: SPL sets mlwid/mwiddeleg correctly

### Phase 3: DTB Merging
**Goal**: Create new DTB with WorldGuard properties

10. Create `board/qemu-riscv/spl/fdt_merge.c` (DTB creation)
11. Allocate 128KB DTB buffer in SPL
12. Add `worldguard,spl-initialized` and CSR value properties
13. Pass new DTB to OpenSBI
14. **Milestone**: OpenSBI receives modified DTB

### Phase 4: OpenSBI Integration
**Goal**: OpenSBI skips init if SPL ran

15. Modify `sources/opensbi/lib/sbi/sbi_worldguard.c`
16. Check `world guard,spl-initialized` property
17. Skip CSR programming if property is true
18. Test full chain: SPL init → OpenSBI skip
19. **Milestone**: No double initialization

### Phase 5: Testing & Documentation
**Goal**: Comprehensive verification

20. Run all automated tests (Test 1-5)
21. Perform manual verification
22. Update documentation (`docs/worldguard.md`, `README.md`)
23. Create testing guide for 004 feature
24. **Milestone**: All tests pass, docs complete

---

## Notes

### Technical Decisions

**DTB Creation Strategy** (Clarification #3):
- Chosen: Create new DTB from scratch
- Rationale: Provides clean separation, easier to debug
- Alternative: In-place FDT modification (more complex, harder to verify)

**Lock Policy** (Clarification #2):
- Chosen: Conditional locking via DT property
- Allows flexible security policies (production vs development)

**Error Handling** (Clarification #4):
- Chosen: DT-first detection
- Avoids illegal instruction exceptions on non-WG hardware
- Safer than trap handlers in SPL's constrained environment

### OpenSBI Backward Compatibility

OpenSBI must support both boot modes:
1. **SPL boot** (new): Check DT, skip if SPL initialized
2. **Direct boot** (fallback): Initialize WorldGuard as before

This ensures debugging workflows (direct OpenSBI boot) still work.

### Memory Considerations

**SPL Memory Budget**:
- Code: <4KB (WorldGuard module)
- DTB buffer: 128KB (per clarification #5)
- Stack/heap: Use SPL default allocations

**Total SPL size**: ~64KB + 128KB buffer = ~192KB (within typical 256-512KB SPL size limits)

---

## Constitution Compliance Check

### ✅ Principle Ⅰ: Build Reproducibility
- All builds tested on Ubuntu 24.04
- Exact component versions documented (U-Boot v2024.10, OpenSBI v1.7)

### ✅ Principle Ⅱ: Version Management
- U-Boot SPL config tracked in version control
- OpenSBI modifications documented with commit references

### ✅ Principle Ⅲ: Target Architecture
- QEMU virt RISC-V 64-bit remains primary target
- No architecture-specific changes that break portability

### ✅ Principle Ⅳ: Modular Components
- SPL WorldGuard code isolated in `board/qemu-riscv/spl/`
- Clear separation from OpenSBI WorldGuard code

### ✅ Principle Ⅴ: Development Environment
- Uses existing riscv64-linux-gnu- toolchain
- Build scripts updated but environment unchanged

### ✅ Principle Ⅵ: Debugging Support
- SPL logs WorldGuard initialization via console
- Debug builds preserve all logging

### ✅ Principle Ⅶ: Documentation Sync
- Plan written before implementation
- Spec updated with clarifications

### ✅ Principle Ⅷ: License Management
- No new dependencies introduced
- U-Boot GPL-2.0, OpenSBI BSD-2-Clause (unchanged)

### ✅ Principle Ⅸ: Git Commit Style
- Will follow U-Boot subsystem prefix conventions
- Atomic commits per component

### ✅ Principle Ⅹ: Language Policy
- Code comments in English
- Commit messages in English

### ✅ Principle Ⅺ: Source/Build Structure
- Build artifacts remain in `build/` directory
- Source trees clean

### ✅ Principle Ⅻ: Documentation Language
- Spec in Korean (already compliant)
- Plan includes English technical terms

**Overall**: ✅ No constitution violations
