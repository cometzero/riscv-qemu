# Implementation Plan: OP-TEE Boot Flow Support

**Branch**: `002-optee-bootflow` | **Date**: 2025-12-09 | **Spec**: [spec.md](file:///home/ubuntu/work/qemu/riscv_qemu/specs/002-optee-bootflow/spec.md)  
**Input**: Feature specification from `/specs/002-optee-bootflow/spec.md`

## Summary

Add OP-TEE (Trusted Execution Environment) support to the existing RISC-V QEMU boot flow. The implementation extracts patches from RISE project's `dev-optee-mpxy-v5` branch and rebases them on upstream latest versions of each component. This enables secure world execution alongside the normal Linux environment.

**Boot Flow (with OP-TEE)**:
```
U-Boot SPL → OpenSBI (with OP-TEE SPD) → U-Boot proper → Linux (with TEE driver) → Buildroot
```

## Technical Context

**Language/Version**: C (kernel/firmware), Bash (build scripts)  
**Primary Dependencies**: OP-TEE OS, OpenSBI with SPD, Linux TEE driver, MPXY/RPMI  
**Storage**: N/A (firmware/boot flow project)  
**Testing**: Boot log verification, xtest suite (OP-TEE test)  
**Target Platform**: RISC-V 64-bit on QEMU virt machine  
**Project Type**: Embedded firmware project with submodules  
**Performance Goals**: Boot to login < 60 seconds with OP-TEE  
**Constraints**: PMP for memory isolation, 16MiB OP-TEE region, 2MiB shared memory  
**Scale/Scope**: Extension to existing boot flow, adds OP-TEE component

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clarity and Reproducibility | ✓ PASS | Scripted builds, deterministic |
| II. Traceable Boot Flow | ✓ PASS | Boot flow documented, observable handoffs |
| V. Configuration Before Code | ✓ PASS | Config-first approach, patches as last resort |
| VIII. Git Submodules Structure | ⚠ DEVIATION | OP-TEE adds new submodule + patch branches |
| XIII. Directory Structure | ✓ PASS | Follows existing structure |
| XVIII. Script-Driven Builds | ✓ PASS | New build scripts for OP-TEE components |
| XXIV. Boot Milestone Verification | ✓ PASS | OP-TEE as new milestone to verify |

**Deviation Justification (VIII)**: OP-TEE requires patches on multiple submodules (OpenSBI, Linux, optionally U-Boot). Strategy is to create local patch branches on upstream latest, not use RISE forks directly. This maintains the submodule structure while adding OP-TEE-specific changes.

## Project Structure

### Documentation (this feature)

```text
specs/002-optee-bootflow/
├── plan.md              # This file
├── research.md          # Phase 0: RISE project research
├── quickstart.md        # Phase 1: OP-TEE quick start guide
└── tasks.md             # Phase 2: Task breakdown
```

### Source Code (repository root)

```text
./
├── sources/
│   ├── qemu/            # Existing - no changes needed
│   ├── u-boot/          # Existing - may need OP-TEE patches
│   ├── opensbi/         # Existing - needs OP-TEE SPD patches
│   ├── linux/           # Existing - needs TEE driver patches  
│   ├── buildroot/       # Existing - needs xtest/optee packages
│   └── optee_os/        # NEW - OP-TEE OS (new submodule)
│
├── configs/
│   ├── optee/           # NEW - OP-TEE OS configuration
│   ├── opensbi/         # UPDATE - SPD configuration
│   ├── linux/           # UPDATE - TEE driver config fragment
│   └── buildroot/       # UPDATE - xtest package selection
│
├── scripts/
│   ├── build_optee.sh   # NEW - Build OP-TEE OS
│   ├── build_opensbi.sh # UPDATE - Add OP-TEE SPD option
│   ├── build_linux.sh   # UPDATE - Add TEE driver option
│   ├── build_buildroot.sh # UPDATE - Add xtest/optee packages
│   ├── build_all.sh     # UPDATE - Add --optee flag
│   └── run_qemu.sh      # UPDATE - Add --optee flag
│
└── patches/             # NEW - OP-TEE patches for submodules
    ├── opensbi/         # OpenSBI SPD patches from RISE
    ├── linux/           # Linux TEE driver patches from RISE
    └── u-boot/          # U-Boot patches if needed
```

**Structure Decision**: Extend existing structure with new `optee_os` submodule and `patches/` directory for extracted RISE patches.

---

## Phase 0: Research

### Research Tasks

1. **RISE Project Patches**: Identify and catalog patches from `dev-optee-mpxy-v5` branch
2. **OP-TEE OS Build**: Research RISC-V QEMU virt build requirements
3. **OpenSBI SPD**: Research Secure Payload Dispatcher integration
4. **Memory Layout**: Verify PMP configuration for TEE/REE isolation
5. **xtest Integration**: Research Buildroot packages for OP-TEE testing

### Key Decisions (from clarifications)

| Decision | Rationale |
|----------|-----------|
| Rebase patches on upstream | Maintains latest security fixes, avoids stale RISE forks |
| 80% xtest pass rate | Realistic for initial RISC-V port, can increase incrementally |
| Unified patch strategy | Apply same approach to all components including OP-TEE OS |

---

## Phase 1: Design

### Component Integration

| Component | Source | Patches Needed | Build Output |
|-----------|--------|----------------|--------------|
| OP-TEE OS | Upstream + RISE patches | RISC-V QEMU virt platform | `tee.bin` |
| OpenSBI | Existing + SPD patches | OP-TEE SPD extension | `fw_dynamic.bin` (with OP-TEE) |
| Linux | Existing + TEE patches | TEE driver, optee driver | `Image` (with TEE) |
| U-Boot | Existing (may need patches) | TBD | SPL + FIT |
| Buildroot | Existing + packages | xtest, optee_examples | rootfs with test tools |

### Memory Layout (from RISE spec)

| Address Range | Size | Component |
|---------------|------|-----------|
| 0xF200_0000 - 0xF21F_FFFF | 2 MiB | Shared memory (TEE↔REE) |
| 0xF100_0000 - 0xF1FF_FFFF | 16 MiB | OP-TEE OS + TAs |
| 0x8010_0000 - 0x8015_FFFF | ~384 KiB | OpenSBI |
| 0x8000_0000 - 0x8000_A000 | 40 KiB | U-Boot SPL |

### Build Flag Design

```bash
# Existing behavior (default)
./scripts/build_all.sh          # No OP-TEE
./scripts/run_qemu.sh           # Boot without OP-TEE

# New OP-TEE mode
./scripts/build_all.sh --optee  # Build with OP-TEE
./scripts/run_qemu.sh --optee   # Boot with OP-TEE
```

---

## Verification Plan

### Automated Tests

1. **Boot Milestone Test** (extend existing):
   ```bash
   ./test/run_boot_test.py --optee
   ```
   - Verify: OpenSBI shows "OP-TEE" or SPD message
   - Verify: Linux shows TEE driver init
   - Verify: `/dev/tee0` device exists

2. **xtest Execution**:
   ```bash
   # Inside QEMU
   xtest
   ```
   - Target: 80% pass rate on core tests (categories 1-6)

### Manual Verification

1. Boot with `./scripts/run_qemu.sh --optee`
2. Login as root
3. Run `ls /dev/tee*` - should show `tee0` and `teepriv0`
4. Run `optee_example_hello_world` - should show "Hello World!" from TA
5. Run `xtest` - verify test results

---

## Complexity Tracking

| Deviation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Multiple patch branches | OP-TEE requires coordinated patches across OpenSBI, Linux, optionally U-Boot | Single patch file insufficient for multi-component integration |
| New submodule (optee_os) | OP-TEE OS is a separate project | Cannot be configuration-only, requires dedicated build |

---

## Next Steps

1. **Phase 0**: Generate `research.md` with RISE patch analysis
2. **Phase 1**: Generate `quickstart.md` for OP-TEE development
3. **Phase 2**: Generate `tasks.md` with implementation checklist → `/speckit.tasks`
