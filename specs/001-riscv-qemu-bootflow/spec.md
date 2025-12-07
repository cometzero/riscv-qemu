# Feature Specification: RISC-V QEMU Boot Flow

**Feature Branch**: `001-riscv-qemu-bootflow`  
**Created**: 2025-12-07  
**Status**: Draft  
**Input**: User description: "Build a reproducible RISC-V boot flow on QEMU using real-world open source components"

## User Scenarios & Testing

### User Story 1 - Study Complete Boot Chain (Priority: P1) 🎯 MVP

As an embedded Linux engineer, I want a reproducible RISC-V boot flow on QEMU so that I can study the interactions between BootROM, SPL, OpenSBI, U-Boot, Linux, and Buildroot without needing physical hardware.

**Why this priority**: This is the core value proposition—enabling developers to learn and experiment with the full RISC-V boot chain in an easily reproducible environment.

**Independent Test**: Clone the repository, build all components, run QEMU, and observe the boot log from BootROM to login prompt.

**Acceptance Scenarios**:

1. **Given** a fresh clone of the repository on Ubuntu 24.04 with documented prerequisites installed, **When** I initialize submodules and run the full build, **Then** all components (QEMU, U-Boot SPL/proper, OpenSBI, Linux kernel, Buildroot rootfs) are built successfully with artifacts in `./build/`.

2. **Given** a successful build, **When** I run the documented QEMU run command, **Then** I see a boot log displaying: U-Boot SPL startup, OpenSBI banner with version, U-Boot proper prompt or auto-boot, Linux kernel boot messages, and Buildroot init reaching a login prompt.

3. **Given** a running QEMU session, **When** I examine the boot log, **Then** I can trace each handoff: BootROM→SPL, SPL→OpenSBI, OpenSBI→U-Boot proper, U-Boot→Linux, Linux→Buildroot init.

---

### User Story 2 - Configuration-Driven Experimentation (Priority: P2)

As a firmware developer, I want to switch configurations via .config files, device trees, and defconfigs so that I can experiment with boot behavior without constantly patching source code.

**Why this priority**: After understanding the boot flow, developers need to modify it; configuration changes are the safest and most common modification path.

**Independent Test**: Modify a configuration file (e.g., kernel command line, U-Boot environment, device tree property), rebuild, and verify the change takes effect in the boot log.

**Acceptance Scenarios**:

1. **Given** a working boot flow, **When** I modify the kernel command line in the configuration, rebuild, and boot, **Then** the boot log shows the updated command line.

2. **Given** a working boot flow, **When** I change the U-Boot boot delay or environment variable, rebuild, and boot, **Then** U-Boot reflects the configuration change.

3. **Given** all configurations stored in `./configs/`, **When** I commit changes to configuration files, **Then** the full boot behavior is reproducible from that commit.

---

### User Story 3 - Automated Regression Testing (Priority: P3)

As a CI engineer, I want a single command that builds and tests the full boot flow, producing logs and a clear pass/fail result, so that I can detect regressions automatically in a CI pipeline.

**Why this priority**: Automation enables sustainable development; once P1 and P2 work, automated testing ensures they continue to work.

**Independent Test**: Run the test command and verify it returns exit code 0 on successful boot and non-zero on failure, along with captured logs.

**Acceptance Scenarios**:

1. **Given** a full build has completed, **When** I run the test command, **Then** QEMU boots, the test captures the serial console log, parses it for milestones, and returns exit code 0 if all milestones are present.

2. **Given** a broken build or boot configuration, **When** I run the test command, **Then** the test returns a non-zero exit code and the log shows which milestone failed or what error occurred.

3. **Given** test outputs, **When** I examine `./build/test-logs/`, **Then** I find the full boot log and a pass/fail summary listing each milestone's status.

---

### User Story 4 - Learning with Documentation (Priority: P4)

As a learner, I want well-documented scripts and boot flow diagrams so that I can step through each stage of boot and understand what is happening at each layer.

**Why this priority**: Documentation transforms a working system into an educational resource; valuable but depends on P1 being solid first.

**Independent Test**: Follow the documentation to understand the boot flow without needing to read source code.

**Acceptance Scenarios**:

1. **Given** the documentation in `./docs/`, **When** I read the boot flow overview, **Then** I understand the sequence: BootROM→SPL→OpenSBI→U-Boot→Linux→Buildroot.

2. **Given** the build documentation, **When** I follow the step-by-step instructions, **Then** I can successfully build all components without guessing commands.

3. **Given** the documentation, **When** I want to modify a specific component, **Then** I find guidance on which configuration files to edit and how to rebuild.

---

### Edge Cases

- What happens if a submodule fails to initialize? Build script reports clear error with the submodule name.
- What happens if a component build fails? Build stops, logs the error, and exits with non-zero status.
- What happens if QEMU boot loops? Test script detects repeated boot messages and fails with "boot loop detected."
- What happens if kernel panics? Test script detects "Kernel panic" in log and fails with appropriate message.
- What happens if the system hangs without reaching a milestone? Test script times out after 3 minutes and reports which milestone was last seen.

## Requirements

### Functional Requirements

- **FR-001**: Repository MUST use Git submodules to manage upstream components (QEMU, U-Boot, OpenSBI, Linux kernel, Buildroot).
- **FR-002**: Repository MUST maintain the directory structure defined in the constitution: `./docs/`, `./sources/`, `./build/`, `./test/`, `./configs/`.
- **FR-003**: Build system MUST produce all boot chain artifacts in `./build/` without polluting `./sources/`.
- **FR-004**: Build system MUST support full-chain builds via a single entry point command.
- **FR-005**: Build system MUST support per-component builds for faster iteration (e.g., only rebuild Linux kernel).
- **FR-006**: Build system MUST log detailed output to files in `./build/logs/` while showing only warnings/errors on console.
- **FR-007**: Build scripts MUST return non-zero exit codes on failure.
- **FR-008**: Test system MUST launch QEMU and capture serial console output to a log file.
- **FR-009**: Test system MUST parse boot logs to verify key milestones using specific log pattern matching (e.g., `"U-Boot SPL"`, `"OpenSBI v"`, `"Linux version"`, `"buildroot login:"`). Exact patterns for each milestone MUST be documented.
- **FR-010**: Test system MUST return clear pass/fail status based on milestone presence and absence of error patterns.
- **FR-011**: All configuration files (defconfigs, device trees, QEMU scripts) MUST be stored in `./configs/` and version-controlled.
- **FR-012**: Linux kernel MUST be built independently from Buildroot (Buildroot provides only the rootfs).
- **FR-013**: Documentation MUST describe the complete boot flow sequence with handoff points.
- **FR-014**: Documentation MUST include step-by-step build and run instructions.
- **FR-015**: Documentation MUST specify exact `apt` packages required as prerequisites, and a verification script MUST be provided to check and report missing prerequisites.

### Key Entities

- **Boot Component**: An upstream open source project (QEMU, U-Boot, OpenSBI, Linux, Buildroot) managed as a Git submodule and built to produce artifacts for the boot chain.
- **Boot Stage**: A logical phase in the boot sequence (BootROM, SPL, M-mode firmware, S-mode bootloader, Kernel, Userspace) with defined entry/exit conditions.
- **Boot Artifact**: A binary or image file produced by building a component (e.g., u-boot-spl.bin, fw_dynamic.bin, Image, rootfs.cpio).
- **Configuration File**: A file controlling component behavior without source changes (defconfig, .config, DTS, QEMU run script, environment file).
- **Boot Log**: Serial console output captured from QEMU during a boot session, used for verification and debugging.
- **Milestone**: A specific log pattern indicating successful completion of a boot stage (e.g., "OpenSBI v" banner, "Booting Linux" message).

## Success Criteria

### Measurable Outcomes

- **SC-001**: A developer with documented prerequisites can go from fresh clone to booting system in under 60 minutes on a typical development machine.
- **SC-002**: The automated test suite achieves 100% detection rate for explicitly defined failure modes (kernel panic, boot loop, missing handoff).
- **SC-003**: Full build produces all required artifacts with zero manual intervention after initial submodule setup.
- **SC-004**: Boot log clearly shows all 5 milestones (SPL started, OpenSBI initialized, U-Boot running, Linux booting, Buildroot login prompt `"buildroot login:"`displayed) in sequential order.
- **SC-005**: Configuration changes (kernel cmdline, U-Boot env, DT properties) take effect in the next boot without requiring source patches.
- **SC-006**: All tests pass on a clean Ubuntu 24.04 system without requiring internet access during test execution (only during initial build).
- **SC-007**: Documentation covers 100% of first-time setup steps with no undocumented prerequisites.

## Non-Goals (Explicit Scope Boundaries)

- No support for real RISC-V hardware boards; QEMU is the only supported platform.
- No support for multiple QEMU machine types simultaneously; a single reference machine is sufficient.
- No complex userspace (desktop, containers, networking services); minimal Buildroot environment only.
- No secure boot, cryptographic signing, or production-grade security features.
- No requirement to upstream local patches; code style should be upstream-compatible but submission is not in scope.
- No Windows or macOS host support; Ubuntu 24.04 LTS on x86_64 is the only supported host.

## Assumptions

- **A-001**: Ubuntu 24.04 LTS is the host operating system. An explicit list of required `apt` packages and a prerequisite verification script will be provided.
- **A-002**: The host has at least 16GB RAM and 50GB free disk space to build all components.
- **A-003**: Internet connectivity is available for initial clone and submodule fetch, but not required for builds or tests after that.
- **A-004**: The target RISC-V architecture (32-bit vs 64-bit) and specific QEMU machine will be determined in the implementation plan.
- **A-005**: All upstream components are available via public Git repositories. Submodules track main/master branch head for latest features (reproducibility via pinned commits at build time).

## Clarifications

### Session 2025-12-07

- Q: How should tests detect boot milestones? → A: Specific log patterns - spec defines exact strings to match for each milestone (e.g., `"U-Boot SPL"`, `"OpenSBI v"`, `"Linux version"`).
- Q: What timeout threshold for boot tests? → A: 3 minutes - moderate timeout suitable for embedded tests.
- Q: What indicates stable userland state? → A: Login prompt - detect `"buildroot login:"` string indicating getty is ready.
- Q: How to select upstream component versions? → A: Main branch - track main/master branch head for latest features.
- Q: What scope for host prerequisites documentation? → A: Explicit package list plus verification script.
