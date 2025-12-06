# U-Boot SPL WorldGuard Initialization

**Feature**: `004-uboot-spl-worldguard`  
**Created**: 2025-12-06  
**Status**: Draft

## Overview

Move WorldGuard initialization from OpenSBI to U-Boot SPL to support the new boot sequence where U-Boot SPL loads and initializes OpenSBI.

## Background

**Current Boot Sequence** (003-opensbi-worldguard):
```
QEMU (wg=on) → OpenSBI → U-Boot → Linux → rootfs
```
- WorldGuard initialized in OpenSBI M-mode
- mlwid, mwiddeleg CSRs set by OpenSBI
- wgChecker slots programmed from Device Tree

**New Boot Sequence** (this feature):
```
QEMU (wg=on) → U-Boot SPL → OpenSBI → U-Boot Proper → Linux → rootfs
```
- U-Boot SPL runs first in M-mode
- SPL loads OpenSBI as a payload
- WorldGuard must be initialized before OpenSBI

## Problem Statement

Users need U-Boot SPL to initialize WorldGuard CSRs and wgChecker slots before loading OpenSBI, enabling proper M-mode to S-mode boot flow control with WorldGuard protection from the earliest boot stage.

## User Scenarios & Testing

### Scenario 1: Boot with WorldGuard Disabled (wg=off)
**As a** firmware developer  
**I want to** boot the system with WorldGuard disabled  
**So that** I can verify the boot sequence works without WorldGuard

**Acceptance Criteria**:
- U-Boot SPL → OpenSBI → U-Boot Proper boot chain completes
- No WorldGuard initialization messages
- OpenSBI loads successfully from SPL
- System boots to U-Boot prompt

### Scenario 2: Boot with WorldGuard Enabled (wg=on)
**As a** firmware developer  
**I want to** initialize WorldGuard in U-Boot SPL  
**So that** memory protection is active from the earliest boot stage

**Acceptance Criteria**:
- U-Boot SPL detects WorldGuard hardware
- SPL sets mlwid=3 (trusted M-mode WID)
- SPL sets mwiddeleg=0x6 (delegate WID 1,2 to S-mode)
- SPL programs wgChecker slots from Device Tree
- OpenSBI boots normally after SPL
- WorldGuard log messages appear from SPL

### Scenario 3: wgChecker Slot Programming
**As a** system architect  
**I want to** configure memory protection slots in U-Boot SPL  
**So that** different boot stages have proper memory access control

**Acceptance Criteria**:
- SPL parses wgChecker slots from Device Tree
- SPL programs MMIO registers for each slot
- Slot addresses and permissions match DT configuration
- OpenSBI and U-Boot Proper respect memory boundaries

## Functional Requirements

### FR1: U-Boot SPL Boot Flow
- U-Boot SPL shall be the first-stage bootloader loaded by QEMU
- SPL shall run in RISC-V M-mode (Machine mode)
- SPL shall load OpenSBI as a second-stage payload
- SPL shall preserve boot arguments and DTB for OpenSBI

### FR2: WorldGuard Detection in SPL
- SPL shall detect WorldGuard hardware by reading mlwid CSR
- SPL shall check Device Tree for `riscv,worldguard` compatible node
- If WorldGuard DT node absent, SPL shall skip WorldGuard init (silent)
- Detection shall not cause boot failure on non-WorldGuard systems

### FR3: WorldGuard CSR Initialization
- SPL shall initialize mlwid CSR to trustedwid value from DT (default: 3)
- SPL shall initialize mwiddeleg CSR to delegation mask from DT (default: 0x6)
- CSR values shall be configurable via Device Tree properties
- CSR initialization shall occur before loading OpenSBI

### FR4: wgChecker Slot Programming
- SPL shall parse `slots` property from `riscv,wgchecker` DT node
- SPL shall program wgChecker MMIO registers for each slot
- Slot format: `<addr_hi addr_lo size_hi size_lo perm cfg>`
- SPL shall set lock bit after programming all slots
- MMIO base address: 0x6000000 (from DT reg property)

### FR5: OpenSBI Compatibility
- OpenSBI WorldGuard init code shall be disabled/removed
- OpenSBI shall not reprogram WorldGuard CSRs
- OpenSBI shall inherit WorldGuard configuration from SPL
- Boot chain shall work with existing OpenSBI v1.7

### FR6: Logging and Debug
- SPL shall log WorldGuard detection status
- SPL shall log each programmed wgChecker slot (address, perm, cfg)
- SPL shall log mlwid and mwiddeleg values
- All logs shall use SPL console output

## Success Criteria

1. **Boot Sequence Verification**
   - System boots: U-Boot SPL → OpenSBI → U-Boot Proper → Linux
   - Boot time increase < 100ms compared to current sequence
   - All stages complete without errors

2. **WorldGuard Initialization**
   - mlwid CSR = 3 (or DT-configured value)
   - mwiddeleg CSR = 0x6 (or DT-configured value)
   - wgChecker slots programmed correctly (verified via log output)

3. **Backward Compatibility**
   - wg=off boot works without WorldGuard messages
   - Non-WorldGuard QEMU boots normally
   - Existing U-Boot functionality preserved

4. **Testing Coverage**
   - Boot test with wg=off completes successfully
   - Boot test with wg=on shows SPL WorldGuard messages
   - wgChecker slot verification shows correct addresses/permissions
   - Full boot chain reaches Linux prompt

## Non-Functional Requirements

### Performance
- SPL boot time overhead: < 50ms for WorldGuard init
- wgChecker slot programming: < 10ms for 10 slots

### Reliability
- Silent failure mode when WorldGuard unavailable
- No boot interruption on CSR access errors
- Graceful handling of malformed DT nodes

### Maintainability
- Reuse existing OpenSBI WorldGuard parsing code where possible
- Clear separation between SPL and OpenSBI WorldGuard code
- Comprehensive inline documentation

## Assumptions

1. **U-Boot SPL Support**: U-Boot v2024.10 supports SPL for RISC-V virt machine
2. **QEMU Boot Order**: QEMU can load U-Boot SPL as `-bios` and SPL can chain-load OpenSBI
3. **M-Mode Access**: U-Boot SPL runs in M-mode with full CSR access
4. **DT Availability**: Device Tree is available to SPL at boot time
5. **OpenSBI Payload**: OpenSBI can be loaded as a binary payload by SPL

## Dependencies

- **002-qemu-worldguard**: QEMU with WorldGuard patches
- **003-opensbi-worldguard**: OpenSBI WorldGuard implementation (for reference)
- U-Boot v2024.10 source code
- Device Tree Compiler (dtc)

## Out of Scope

- Linux kernel WorldGuard support
- S-mode World ID (slwid) configuration
- Dynamic WID switching at runtime
- WorldGuard fault handling in SPL
- Secure boot integration

## Key Entities

### WorldGuardConfig
- nworlds: u32 (number of World IDs, default 4)
- trustedwid: u32 (M-mode World ID, default 3)
- mwiddeleg: u32 (delegation bitmask, default 0x6)

### WgCheckerSlot
- addr_start: u64 (region start address)
- size: u64 (region size in bytes)
- perm: u32 (2-bit permissions per WID)
- cfg: u32 (mode: TOR/NAPOT, lock bit)

### SPLBootInfo
- dtb_addr: void* (Device Tree address)
- opensbi_entry: void* (OpenSBI entry point)
- next_mode: mode (S-mode for OpenSBI)

## Technical Constraints

1. **Code Size**: SPL has limited size (~64KB typical)
2. **No malloc**: SPL may have restricted heap
3. **Early Boot**: Limited library functions available
4. **Binary Size**: Keep WorldGuard code compact (<4KB)

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| SPL can't access WorldGuard CSRs | High | Add trap handler for illegal instruction |
| OpenSBI conflicts with SPL WG init | High | Remove/disable OpenSBI WG code |
| DT not available in SPL | High | Fallback to hardcoded defaults |
| QEMU boot order issues | Medium | Test with different `-bios`/`-kernel` configs |

## References

- [U-Boot SPL Documentation](https://docs.u-boot.org/en/latest/develop/spl.html)
- [RISC-V WorldGuard Spec v0.4](https://github.com/riscv/riscv-worldguard)
- [specs/003-opensbi-worldguard/spec.md](../003-opensbi-worldguard/spec.md)
