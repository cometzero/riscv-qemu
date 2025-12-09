# Feature Specification: OP-TEE Boot Flow Support

**Feature Branch**: `002-optee-bootflow`  
**Created**: 2025-12-09  
**Status**: Draft  
**Input**: User description: "Add OP-TEE support to RISC-V QEMU boot flow based on RISE project implementation"

## Overview

OP-TEE (Open Portable Trusted Execution Environment) is an open-source TEE designed for secure software execution, implemented according to the GlobalPlatform TEE Client API and TEE Internal Core API. This feature adds OP-TEE support to the existing RISC-V QEMU boot flow, enabling a Trusted Execution Environment alongside the normal Linux environment (REE - Rich Execution Environment).

**Reference**: [RISE Project OP-TEE Implementation](https://lf-rise.atlassian.net/wiki/spaces/HOME/pages/8587868/OPTEE_00_01+-+OP-TEE+support)

## Clarifications

### Session 2025-12-09

- Q: Which RISE repository branch strategy to use? → A: Use `dev-optee-mpxy-v5` patches rebased on latest upstream subproject revisions (not RISE forks directly)
- Q: What xtest pass rate target is appropriate? → A: 80% (realistic for initial RISC-V port)
- Q: OP-TEE OS source strategy? → A: Apply RISE patches on upstream OP-TEE (same rebase strategy as other components)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run OP-TEE with QEMU (Priority: P1) 🎯 MVP

As a developer, I want to boot the RISC-V QEMU system with OP-TEE enabled so that I can experiment with Trusted Execution Environment on RISC-V.

**Why this priority**: This is the foundational capability - without successful boot, no other TEE features can be tested. It enables the basic TEE/REE separation on RISC-V.

**Independent Test**: Boot QEMU and verify that:
1. OpenSBI shows OP-TEE SPD (Secure Payload Dispatcher) loading
2. Linux kernel shows OP-TEE driver initialization
3. System reaches login prompt with both normal world and secure world operational

**Acceptance Scenarios**:

1. **Given** all OP-TEE components are built, **When** `run_qemu.sh` is executed, **Then** console output shows "OP-TEE" messages from OpenSBI and Linux kernel driver
2. **Given** QEMU is running with OP-TEE, **When** user observes boot log, **Then** the boot sequence shows: U-Boot SPL → OpenSBI (with OP-TEE) → U-Boot proper → Linux → login prompt
3. **Given** OP-TEE is loaded, **When** Linux boots, **Then** `/dev/tee0` and `/dev/teepriv0` devices are present

---

### User Story 2 - Execute OP-TEE Test Suite (Priority: P2)

As a developer, I want to run the `xtest` test suite to verify that OP-TEE functionality works correctly on RISC-V.

**Why this priority**: Test suite execution validates that OP-TEE is not just booting but actually functioning correctly. This is the primary measure of success for the implementation.

**Independent Test**: Login to the system and run `xtest` command, verify majority of tests pass.

**Acceptance Scenarios**:

1. **Given** QEMU is booted with OP-TEE, **When** user runs `xtest` in the normal world console, **Then** OP-TEE tests execute and report results
2. **Given** `xtest` is running, **When** tests complete, **Then** core tests (basic TA invocation, shared memory, cryptographic operations) pass
3. **Given** OP-TEE is operational, **When** user runs `optee_example_*` binaries, **Then** example Trusted Applications execute successfully

---

### User Story 3 - Build OP-TEE Components Separately (Priority: P3)

As a developer, I want to build individual OP-TEE components (OP-TEE OS, patched OpenSBI, patched Linux) so that I can modify and debug specific parts of the TEE stack.

**Why this priority**: Development workflows require building individual components rather than always running the full build. This enables efficient iteration during development.

**Independent Test**: Run individual build scripts and verify component binaries are produced.

**Acceptance Scenarios**:

1. **Given** source submodules are initialized, **When** user runs `build_optee.sh`, **Then** OP-TEE OS binary is produced
2. **Given** OP-TEE OS is built, **When** user runs `build_opensbi.sh` with OP-TEE option, **Then** OpenSBI with OP-TEE SPD is produced
3. **Given** all components are built, **When** user runs `build_all.sh --optee`, **Then** complete OP-TEE-enabled boot images are produced

---

### User Story 4 - Dual Configuration Support (Priority: P4)

As a developer, I want to choose between booting with or without OP-TEE so that I can compare behavior and debug issues.

**Why this priority**: Having both configurations available helps with debugging and understanding TEE-specific behavior vs normal boot.

**Independent Test**: Run with different configurations and verify correct boot behavior for each.

**Acceptance Scenarios**:

1. **Given** both configurations are available, **When** user runs `run_qemu.sh`, **Then** system boots without OP-TEE (default, existing behavior)
2. **Given** OP-TEE is enabled, **When** user runs `run_qemu.sh --optee`, **Then** system boots with OP-TEE enabled

---

### Edge Cases

- What happens when OP-TEE fails to initialize? The system should continue booting to normal world with error logged.
- How does system handle PMP configuration failures? Boot should fail with clear error message.
- What happens when TA (Trusted Application) panics? Secure world should handle gracefully without crashing normal world.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support building OP-TEE OS for RISC-V QEMU virt platform
- **FR-002**: System MUST support building OpenSBI with OP-TEE SPD (Secure Payload Dispatcher)
- **FR-003**: System MUST support building Linux kernel with OP-TEE driver enabled
- **FR-004**: System MUST use PMP (Physical Memory Protection) for TEE/REE isolation
- **FR-005**: System MUST maintain existing non-OP-TEE boot flow as default
- **FR-006**: System MUST provide command-line option to enable OP-TEE boot
- **FR-007**: System MUST include `xtest` test suite in the rootfs for validation
- **FR-008**: System MUST include OP-TEE example applications in the rootfs
- **FR-009**: Boot flow MUST follow: U-Boot SPL → OpenSBI (with OP-TEE) → U-Boot proper → Linux
- **FR-010**: OP-TEE patches MUST be extracted from RISE project `dev-optee-mpxy-v5` branch and rebased on latest upstream subproject revisions
- **FR-011**: System MUST support static shared memory region between TEE and REE
- **FR-012**: System MUST expose TEE devices (`/dev/tee0`, `/dev/teepriv0`) in Linux

### Memory Layout Requirements

Based on RISE project specification:

| Address Range | Size | Usage |
|---------------|------|-------|
| 0x0_F200_0000 - 0x0_F21F_FFFF | 2 MiB | Static shared memory |
| 0x0_F100_0000 - 0x0_F1FF_FFFF | 16 MiB | OP-TEE OS core & TA |
| 0x0_8010_0000 - 0x0_8015_FFFF | OpenSBI | text + data |
| 0x0_8000_0000 - 0x0_8000_A000 | U-Boot SPL |

### Key Entities

- **OP-TEE OS**: Secure world operating system running Trusted Applications
- **OpenSBI SPD**: Secure Payload Dispatcher extension in OpenSBI for OP-TEE
- **TEE Driver**: Linux kernel driver for communicating with secure world
- **Trusted Application (TA)**: Secure programs running inside OP-TEE
- **PMP**: RISC-V Physical Memory Protection for hardware isolation

### Dependencies

- MPXY/RPMI Specification (for message proxy between domains)
- Domain Context Switch Support (SBI extension)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: QEMU boots to login prompt with OP-TEE enabled within 60 seconds
- **SC-002**: Linux kernel shows OP-TEE driver loaded (`/dev/tee0` device present)
- **SC-003**: `xtest` core tests (categories 1-6) pass with 80% or higher success rate
- **SC-004**: Example OP-TEE applications (`optee_example_hello_world`) execute successfully
- **SC-005**: PMP isolation is verified (secure memory not accessible from normal world)
- **SC-006**: Existing non-OP-TEE boot flow continues to work unchanged
- **SC-007**: Build time for OP-TEE components completes within 30 minutes on 8-core host

## Non-Goals

- Hardware-backed security features (IOPMP, AIA/APLIC/IMSIC) - these are future work
- FF-A (Firmware Framework for Arm) like ABI - not yet standardized for RISC-V
- Porting to real RISC-V hardware - this feature is QEMU-only
- Performance optimization - focus is on functional correctness
- Upstream contribution - using RISE project forks, upstreaming is separate effort

## Assumptions

- **A-001**: RISE project repositories are accessible and stable
- **A-002**: Host system has at least 32GB disk space for additional components
- **A-003**: Host toolchain can build all RISE project components
- **A-004**: QEMU virt platform has sufficient PMP regions for isolation
- **A-005**: Network access available for cloning RISE project repositories
