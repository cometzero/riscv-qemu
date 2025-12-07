# Implementation Plan: RISC-V QEMU Boot Flow

**Branch**: `001-riscv-qemu-bootflow` | **Date**: 2025-12-07 | **Spec**: [spec.md](file:///home/ubuntu/work/qemu/riscv_qemu/specs/001-riscv-qemu-bootflow/spec.md)  
**Input**: Feature specification from `/specs/001-riscv-qemu-bootflow/spec.md`

## Summary

Implement a complete, reproducible RISC-V boot flow on QEMU using the `virt` machine with 64-bit RISC-V (RV64). The boot sequence follows: **QEMU BootROM → U-Boot SPL → OpenSBI (M-mode) → U-Boot proper (S-mode) → Linux Kernel → Buildroot rootfs**. The implementation uses U-Boot's SPL with FIT image support, bundling OpenSBI `fw_dynamic.bin` and U-Boot proper into `u-boot.itb`, which SPL loads and hands off to OpenSBI.

## Technical Context

**Host Platform**: Ubuntu 24.04 LTS on x86_64  
**Target Architecture**: RISC-V 64-bit (RV64GC)  
**Emulator**: QEMU `virt` machine  
**Build System**: Bash scripts with GNU Make  
**Cross Toolchain**: `riscv64-linux-gnu-` (from Ubuntu packages)  
**Test Framework**: Python 3 with standard library (subprocess, re)  
**Storage**: File-based artifacts in `./build/`  
**Performance Goals**: Full boot to login prompt in <60 seconds on typical hardware  
**Constraints**: 3-minute test timeout, offline operation after initial clone

## Constitution Check

*GATE: All principles verified before Phase 0. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Clarity and Reproducibility | ✅ | All builds scripted, no ad-hoc steps |
| II. Traceable Boot Flow | ✅ | Each stage documented with log patterns |
| III. Document Decisions | ✅ | Architecture choices in this plan and ./docs |
| IV. Follow Upstream Guidelines | ✅ | Using upstream defconfigs, no source patches |
| V. Configuration Before Code | ✅ | All customization via configs/ directory |
| XIII. Directory Structure | ✅ | Using ./docs, ./sources, ./build, ./test, ./configs |
| XVIII. Script-Driven Builds | ✅ | Bash scripts for all build operations |
| XXII-XXVI. Testing Discipline | ✅ | Python test harness with milestone detection |

---

## Overall Architecture

### Boot Flow Sequence

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           QEMU RISC-V virt Machine                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────┐    ┌───────────┐    ┌───────────┐    ┌───────────────────┐  │
│  │  BootROM  │───►│ U-Boot    │───►│  OpenSBI  │───►│ U-Boot proper     │  │
│  │  (QEMU)   │    │   SPL     │    │ fw_dynamic │    │ (S-mode)          │  │
│  │           │    │ (M-mode)  │    │ (M-mode)  │    │                   │  │
│  └───────────┘    └───────────┘    └───────────┘    └───────────────────┘  │
│       │                │                │                    │              │
│       │   -bios        │  FIT image     │   SBI ecall        │              │
│       └────────────────┘  u-boot.itb    └────────────────────┘              │
│                                                                             │
│                         ┌───────────────────┐    ┌───────────────────────┐  │
│                         │   Linux Kernel    │───►│  Buildroot rootfs     │  │
│                         │   (S-mode)        │    │  (init → login)       │  │
│                         └───────────────────┘    └───────────────────────┘  │
│                                │                          │                 │
│                           Device Tree                  initramfs            │
│                           + cmdline                    (cpio)               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Boot Stage Details

| Stage | Component | Mode | Load Address | Entry Point | Handoff |
|-------|-----------|------|--------------|-------------|---------|
| 0 | QEMU BootROM | - | - | `0x1000` (ROM) | Jump to `-bios` |
| 1 | U-Boot SPL | M-mode | `0x80000000` | `0x80000000` | Load FIT, jump to OpenSBI |
| 2 | OpenSBI | M-mode | `0x80000000` | `0x80000000` | Relocate, trap setup, jump to U-Boot |
| 3 | U-Boot proper | S-mode | `0x80200000` | `0x80200000` | Load kernel+DTB, bootm |
| 4 | Linux Kernel | S-mode | `0x80400000` | `0x80400000` | Start init |
| 5 | Buildroot init | S-mode | - | `/sbin/init` | Login prompt |

### Key Artifacts

| Artifact | Source | Location in ./build |
|----------|--------|---------------------|
| `qemu-system-riscv64` | QEMU | `./build/qemu/build/qemu-system-riscv64` |
| `u-boot-spl.bin` | U-Boot | `./build/u-boot/spl/u-boot-spl.bin` |
| `u-boot.itb` | U-Boot + OpenSBI | `./build/u-boot/u-boot.itb` |
| `fw_dynamic.bin` | OpenSBI | `./build/opensbi/platform/generic/firmware/fw_dynamic.bin` |
| `Image` | Linux | `./build/linux/arch/riscv/boot/Image` |
| `rootfs.cpio` | Buildroot | `./build/rootfs/images/rootfs.cpio` |

### QEMU Command Line

```bash
./build/qemu/build/qemu-system-riscv64 \
    -M virt \
    -m 256M \
    -nographic \
    -bios ./build/u-boot/spl/u-boot-spl.bin \
    -device loader,file=./build/u-boot/u-boot.itb,addr=0x80200000
```

> **Note**: U-Boot proper handles kernel loading internally via its environment. The kernel and rootfs are embedded or loaded by U-Boot commands.

---

## Component Selection and Versions

### Version Strategy

Per spec clarification: Track **main/master branch head** for latest features. Submodules pin to specific commits at setup time for reproducibility.

| Component | Repository | Branch | Notes |
|-----------|------------|--------|-------|
| QEMU | `https://gitlab.com/qemu-project/qemu.git` | `master` | RISC-V virt support |
| U-Boot | `https://source.denx.de/u-boot/u-boot.git` | `master` | `qemu-riscv64_spl_defconfig` |
| OpenSBI | `https://github.com/riscv-software-src/opensbi.git` | `master` | Generic platform |
| Linux | `https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git` | `master` | `defconfig` for riscv |
| Buildroot | `https://git.buildroot.net/buildroot` | `master` | Minimal rootfs only |

### Rationale

- **QEMU master**: Ensures latest RISC-V fixes and features
- **U-Boot master**: Best QEMU virt board support, SPL with FIT image
- **OpenSBI generic platform**: Works with any RISC-V board, used via `PLATFORM=generic`
- **Linux master**: Latest RISC-V support; alternative: use latest LTS (6.6.x)
- **Buildroot master**: Minimal config, rootfs-only (no kernel build)

---

## Repository and Submodule Layout

### Directory Structure

```
riscv-qemu-bootflow/
├── .git/
├── .specify/                   # Speckit workflow files
├── docs/                       # Documentation
│   ├── boot-flow.md           # Boot sequence diagram and explanation
│   ├── build-howto.md         # Step-by-step build instructions
│   ├── testing.md             # Test execution guide
│   └── configuration.md       # Configuration modification guide
├── sources/                    # Git submodules (upstream code)
│   ├── qemu/                  # QEMU emulator
│   ├── u-boot/                # U-Boot bootloader
│   ├── opensbi/               # OpenSBI firmware
│   ├── linux/                 # Linux kernel
│   └── buildroot/             # Buildroot (rootfs generator)
├── build/                      # Build outputs (git-ignored)
│   ├── qemu/                  # QEMU build output
│   ├── u-boot/                # U-Boot build output
│   ├── opensbi/               # OpenSBI build output
│   ├── linux/                 # Linux build output
│   ├── rootfs/                # Buildroot output
│   ├── logs/                  # Per-component build logs
│   └── test-logs/             # Test execution logs
├── test/                       # Test scripts and fixtures
│   ├── run_boot_test.py       # Main boot test harness
│   ├── milestones.py          # Milestone pattern definitions
│   └── fixtures/              # Reference log snippets
├── configs/                    # Configuration files
│   ├── qemu/                  # QEMU run configuration
│   │   └── run_qemu.conf      # QEMU command-line options
│   ├── u-boot/                # U-Boot configuration
│   │   └── qemu_riscv64.defconfig  # Custom defconfig (if needed)
│   ├── opensbi/               # OpenSBI platform config
│   ├── linux/                 # Kernel configuration
│   │   ├── riscv64_virt.defconfig  # Base defconfig
│   │   └── bootargs.fragment  # Kernel cmdline fragment
│   └── buildroot/             # Buildroot configuration
│       └── qemu_riscv64_minimal.defconfig
├── scripts/                    # Build and run scripts
│   ├── env.sh                 # Environment setup (CROSS_COMPILE, paths)
│   ├── check_prereqs.sh       # Prerequisite verification
│   ├── build_qemu.sh          # QEMU build script
│   ├── build_opensbi.sh       # OpenSBI build script
│   ├── build_uboot.sh         # U-Boot build script (SPL + proper + FIT)
│   ├── build_linux.sh         # Linux kernel build script
│   ├── build_buildroot.sh     # Buildroot build script
│   ├── build_all.sh           # Full build orchestration
│   ├── run_qemu.sh            # QEMU launch script
│   └── clean.sh               # Clean build artifacts
├── specs/                      # Speckit specifications
├── README.md                   # Project overview and quick start
└── .gitignore                  # Ignore ./build/
```

### Submodule Initialization

```bash
# Initial setup
git submodule update --init --recursive

# Update to latest (when needed)
git submodule update --remote --recursive
```

---

## Build System Design

### Environment Setup (`scripts/env.sh`)

```bash
#!/bin/bash
# Source this file: source scripts/env.sh

export ARCH=riscv
export CROSS_COMPILE=riscv64-linux-gnu-
export RISCV_QEMU_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export BUILD_DIR="${RISCV_QEMU_ROOT}/build"
export SOURCES_DIR="${RISCV_QEMU_ROOT}/sources"
export CONFIGS_DIR="${RISCV_QEMU_ROOT}/configs"

# Parallel jobs
export NPROC=$(nproc)
```

### Prerequisites Check (`scripts/check_prereqs.sh`)

Verifies required packages:
- `build-essential`, `git`, `python3`, `python3-pip`
- `gcc-riscv64-linux-gnu`, `g++-riscv64-linux-gnu`
- `libglib2.0-dev`, `libpixman-1-dev`, `ninja-build`, `meson` (for QEMU)
- `flex`, `bison`, `libssl-dev`, `bc` (for Linux kernel)
- `libncurses-dev`, `cpio` (for menuconfig and initramfs)

### Build Script Pattern

Each build script follows this pattern:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

COMPONENT="component_name"
SRC_DIR="${SOURCES_DIR}/${COMPONENT}"
OUT_DIR="${BUILD_DIR}/${COMPONENT}"
LOG_FILE="${BUILD_DIR}/logs/${COMPONENT}-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "${OUT_DIR}" "${BUILD_DIR}/logs"

log_info() { echo "[INFO] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

# Build logic here, redirecting detailed output to $LOG_FILE
# Only warnings/errors to console

if ! make -C "$SRC_DIR" ... >> "$LOG_FILE" 2>&1; then
    log_error "Build failed. See $LOG_FILE for details."
    exit 1
fi

log_info "Build complete. Artifacts in $OUT_DIR"
```

### Build Order

1. **OpenSBI** (no dependencies on other components)
2. **U-Boot** (requires OpenSBI `fw_dynamic.bin`)
3. **QEMU** (independent, can build in parallel with 1-2)
4. **Linux Kernel** (independent, can build in parallel)
5. **Buildroot** (independent, can build in parallel)

### `build_all.sh` Orchestration

```bash
#!/bin/bash
set -e
source "$(dirname "$0")/env.sh"

echo "=== Building RISC-V QEMU Boot Flow ==="

echo "[1/5] Building QEMU..."
"$(dirname "$0")/build_qemu.sh"

echo "[2/5] Building OpenSBI..."
"$(dirname "$0")/build_opensbi.sh"

echo "[3/5] Building U-Boot (SPL + proper)..."
"$(dirname "$0")/build_uboot.sh"

echo "[4/5] Building Linux Kernel..."
"$(dirname "$0")/build_linux.sh"

echo "[5/5] Building Buildroot rootfs..."
"$(dirname "$0")/build_buildroot.sh"

echo "=== Build Complete ==="
echo "Run: ./scripts/run_qemu.sh"
```

---

## Logging and Artifact Handling

### Log Structure

```
./build/logs/
├── qemu-20251207-120000.log
├── opensbi-20251207-120100.log
├── u-boot-20251207-120200.log
├── linux-20251207-120300.log
├── buildroot-20251207-120400.log
└── build-all-20251207-120000.log

./build/test-logs/
├── boot-test-20251207-130000.log      # Full QEMU console output
└── boot-test-20251207-130000.result   # Pass/fail summary
```

### Console Output Policy

- **Progress messages**: `[INFO] Building component X...`
- **Warnings**: Full text to console
- **Errors**: Full text to console + exit with non-zero
- **Detailed output**: Redirected to timestamped log file

### Cleanup Strategy

| Command | Action |
|---------|--------|
| `./scripts/clean.sh` | Remove `./build/*` except `./build/logs/` |
| `./scripts/clean.sh --logs` | Also remove logs |
| `./scripts/clean.sh --distclean` | Remove entire `./build/` directory |

---

## Testing Architecture

### Test Harness Structure

```
./test/
├── run_boot_test.py           # Main entry point
├── milestones.py              # Pattern definitions
├── qemu_runner.py             # QEMU process management
├── log_parser.py              # Boot log analysis
└── fixtures/
    └── expected_milestones.txt  # Reference patterns
```

### Milestone Definitions (`milestones.py`)

```python
MILESTONES = [
    {
        "name": "SPL_STARTED",
        "pattern": r"U-Boot SPL",
        "description": "U-Boot SPL has started"
    },
    {
        "name": "OPENSBI_BANNER",
        "pattern": r"OpenSBI v\d+\.\d+",
        "description": "OpenSBI initialized with version"
    },
    {
        "name": "UBOOT_RUNNING",
        "pattern": r"U-Boot \d+\.\d+",
        "description": "U-Boot proper is running"
    },
    {
        "name": "LINUX_BOOTING",
        "pattern": r"Linux version \d+\.\d+",
        "description": "Linux kernel is booting"
    },
    {
        "name": "BUILDROOT_LOGIN",
        "pattern": r"buildroot login:",
        "description": "Buildroot init complete, login prompt"
    }
]

ERROR_PATTERNS = [
    r"Kernel panic",
    r"Unable to mount root fs",
    r"not syncing",
]
```

### Test Execution Flow

```python
# run_boot_test.py (simplified)
def main():
    timeout = 180  # 3 minutes
    
    # Start QEMU
    process = start_qemu()
    log_file = capture_console(process, timeout)
    
    # Parse log
    results = check_milestones(log_file, MILESTONES)
    errors = check_errors(log_file, ERROR_PATTERNS)
    
    # Determine result
    if errors:
        print_failure(errors)
        return 1
    
    if all(m["found"] for m in results):
        print_success(results)
        return 0
    else:
        print_failure(results)
        return 1
```

### Test Invocation

```bash
# Run boot test
python3 ./test/run_boot_test.py

# Exit codes:
#   0 = All milestones found, no errors
#   1 = Missing milestones or errors detected
#   2 = Timeout
#   3 = QEMU failed to start
```

---

## Configuration Management

### Configuration Files

| Component | Config File | Location |
|-----------|-------------|----------|
| QEMU | `run_qemu.conf` | `./configs/qemu/` |
| U-Boot | `qemu_riscv64.env` | `./configs/u-boot/` |
| OpenSBI | (uses defaults) | - |
| Linux | `riscv64_virt.defconfig` | `./configs/linux/` |
| Buildroot | `qemu_riscv64_minimal.defconfig` | `./configs/buildroot/` |

### Configuration-First Workflow

1. **Want to change kernel cmdline?**
   - Edit `./configs/linux/bootargs.fragment`
   - Rebuild: `./scripts/build_linux.sh`

2. **Want to change U-Boot boot delay?**
   - Edit `./configs/u-boot/qemu_riscv64.env`
   - Rebuild: `./scripts/build_uboot.sh`

3. **Want to add a Buildroot package?**
   - Edit `./configs/buildroot/qemu_riscv64_minimal.defconfig`
   - Rebuild: `./scripts/build_buildroot.sh`

---

## Phase Breakdown / Milestones

### Phase 0: Repository Skeleton

**Goal**: Create project structure and initial documentation

**Tasks**:
- [ ] Create top-level directory structure (`./docs`, `./sources`, `./build`, `./test`, `./configs`, `./scripts`)
- [ ] Create `README.md` with project overview and goals
- [ ] Create `.gitignore` (ignore `./build/`)
- [ ] Add placeholder files for all scripts

**Deliverables**:
- Repository skeleton committed
- README describes project purpose

---

### Phase 1: Submodules and Minimal Build

**Goal**: Add all submodules and achieve first successful build

**Tasks**:
- [ ] Add QEMU as submodule: `./sources/qemu`
- [ ] Add U-Boot as submodule: `./sources/u-boot`
- [ ] Add OpenSBI as submodule: `./sources/opensbi`
- [ ] Add Linux as submodule: `./sources/linux`
- [ ] Add Buildroot as submodule: `./sources/buildroot`
- [ ] Implement `scripts/env.sh`
- [ ] Implement `scripts/check_prereqs.sh`
- [ ] Implement `scripts/build_qemu.sh`
- [ ] Implement `scripts/build_opensbi.sh`
- [ ] Implement `scripts/build_uboot.sh`
- [ ] Implement `scripts/build_linux.sh`
- [ ] Implement `scripts/build_all.sh` (partial, without Buildroot rootfs)
- [ ] Create minimal configs for each component
- [ ] Verify: Boot to U-Boot prompt (without rootfs)

**Deliverables**:
- All submodules initialized
- Build scripts functional
- Boot reaches U-Boot prompt

---

### Phase 2: Buildroot Integration

**Goal**: Complete boot flow to Buildroot login prompt

**Tasks**:
- [ ] Create Buildroot minimal defconfig (rootfs only, no kernel)
- [ ] Implement `scripts/build_buildroot.sh`
- [ ] Configure U-Boot to load kernel and initramfs
- [ ] Integrate rootfs with boot flow (initramfs or disk image)
- [ ] Update `scripts/build_all.sh` with Buildroot
- [ ] Implement `scripts/run_qemu.sh`
- [ ] Verify: Full boot to `buildroot login:` prompt

**Deliverables**:
- Complete boot flow working
- QEMU run script functional
- Boot log shows all 5 milestones

---

### Phase 3: Testing Automation

**Goal**: Automated boot test with pass/fail detection

**Tasks**:
- [ ] Implement `test/milestones.py`
- [ ] Implement `test/qemu_runner.py`
- [ ] Implement `test/log_parser.py`
- [ ] Implement `test/run_boot_test.py`
- [ ] Add error pattern detection (kernel panic, boot loop)
- [ ] Add timeout handling (3 minutes)
- [ ] Verify: Test returns 0 on successful boot

**Deliverables**:
- Automated test harness
- Pass/fail based on milestone detection
- Test logs saved to `./build/test-logs/`

---

### Phase 4: Documentation and Polish

**Goal**: Complete documentation and CI-readiness

**Tasks**:
- [ ] Write `docs/boot-flow.md` with diagrams
- [ ] Write `docs/build-howto.md` with step-by-step instructions
- [ ] Write `docs/testing.md` with test execution guide
- [ ] Write `docs/configuration.md` with config modification guide
- [ ] Implement `scripts/clean.sh`
- [ ] Add prerequisite package list to README
- [ ] Review and refine all commit messages
- [ ] Verify: SC-001 (60 minute fresh clone to boot)
- [ ] Verify: SC-007 (100% documented prerequisites)

**Deliverables**:
- Complete documentation
- All success criteria verified
- Project ready for use

---

## Verification Plan

### Automated Tests

| Test | Command | Success Criteria |
|------|---------|------------------|
| Prerequisite Check | `./scripts/check_prereqs.sh` | Exit code 0, lists all packages |
| Full Build | `./scripts/build_all.sh` | Exit code 0, all artifacts exist |
| Boot Test | `python3 ./test/run_boot_test.py` | Exit code 0, all milestones found |

### Manual Verification

| Check | Procedure |
|-------|-----------|
| Fresh Clone Test | On clean Ubuntu 24.04 VM: clone, `./scripts/check_prereqs.sh`, install deps, `./scripts/build_all.sh`, `./scripts/run_qemu.sh` |
| Configuration Change | Modify `./configs/linux/bootargs.fragment`, rebuild, verify in boot log |
| Milestone Detection | Intentionally break boot (remove kernel), verify test detects failure |

---

## Project Structure

### Documentation (this feature)

```text
specs/001-riscv-qemu-bootflow/
├── plan.md              # This file
├── spec.md              # Feature specification
├── checklists/          # Quality checklists
│   └── requirements.md
└── tasks.md             # Implementation tasks (created by /speckit.tasks)
```

### Source Code (repository root)

```text
./
├── docs/                # User-facing documentation
├── sources/             # Git submodules (upstream code)
├── build/               # Build outputs (git-ignored)
├── test/                # Test harness (Python)
├── configs/             # Configuration files
├── scripts/             # Build and run scripts (Bash)
└── README.md            # Quick start guide
```

**Structure Decision**: Embedded systems project with submodules for upstream components, Bash scripts for builds, Python for testing. No traditional src/lib structure as this is infrastructure/orchestration focused.
