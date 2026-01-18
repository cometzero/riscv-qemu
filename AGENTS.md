# AGENTS.md - AI Agent Development Guidelines

This document provides operational guidelines for AI coding agents working on the RISC-V QEMU Boot Flow project.

## Project Overview

RISC-V boot flow implementation on QEMU:
```
QEMU BootROM → U-Boot SPL → OpenSBI → U-Boot proper → Linux Kernel → Buildroot
```

**Architecture**: RISC-V 64-bit (`riscv64-linux-gnu-` toolchain)

## Build Commands

### Full Build
```bash
./scripts/build_all.sh          # Build all components (QEMU, OpenSBI, U-Boot, Linux, Buildroot)
```

### Per-Component Builds
```bash
./scripts/build_qemu.sh         # Build QEMU emulator
./scripts/build_opensbi.sh      # Build OpenSBI (M-mode firmware)
./scripts/build_uboot.sh        # Build U-Boot (SPL + proper)
./scripts/build_linux.sh        # Build Linux kernel
./scripts/build_buildroot.sh    # Build Buildroot rootfs
```

### Clean Build
```bash
./scripts/clean.sh              # Remove build artifacts
```

### Run QEMU
```bash
./scripts/run_qemu.sh           # Run boot flow
./scripts/run_qemu.sh --debug   # Run with GDB stub (port 1234)
```

## Testing

### Boot Test (Primary Test Method)
```bash
python3 test/run_boot_test.py
```

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | All milestones passed |
| 1 | Missing milestones or error |
| 2 | Timeout (3 min exceeded) |
| 3 | QEMU failed to start |

**Boot Milestones Verified**:
1. `U-Boot SPL` - SPL started
2. `OpenSBI v` - OpenSBI initialized
3. `U-Boot 20` - U-Boot proper running
4. `Linux version` - Kernel booting
5. `buildroot login:` - Userspace ready

**Test Logs**: `./build/test-logs/boot-test-<timestamp>.{log,result}`

## Debugging

```bash
# Terminal 1: Start QEMU frozen
./scripts/run_qemu.sh --debug

# Terminal 2: Attach GDB
gdb-multiarch -ex "target remote :1234" -x scripts/debug.gdb
```

See `docs/debugging.md` for U-Boot relocation handling and IDE integration.

## Git Conventions (MANDATORY)

### Commit Message Format
```
<type>(<scope>): <subject>       # ≤50 chars, imperative mood

<body>                           # Wrap at 72 columns
- Explain motivation/intention
- Describe technical changes

Signed-off-by: Name <email>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

### Commit Requirements
- **Signed-off-by**: REQUIRED (`git commit -s`)
- **Atomic commits**: One logical change per commit
- **No mixing**: Do NOT combine style fixes with functional changes
- **No debug code**: Temporary debug code MUST NOT be committed

## Configuration-First Policy (MANDATORY)

**Order of preference for changes**:
1. Kconfig / defconfig changes
2. Device Tree Source (DTS) modifications
3. Command-line options (kernel cmdline, QEMU args)
4. Environment variables
5. Source code (LAST RESORT - requires justification)

## Code Style Guidelines

### Follow Upstream Conventions
Each component has its own coding style:
- **Linux kernel**: `Documentation/process/coding-style.rst`
- **U-Boot**: `doc/develop/codingstyle.rst`
- **OpenSBI**: OpenSBI coding conventions
- **QEMU**: QEMU coding style

Patches SHOULD be written in upstreamable style even if not intended for submission.

### Shell Scripts (Bash)
- Use `set -euo pipefail` for strict error handling
- Provide `--help` option documenting usage
- Log detailed output to `./build/logs/<component>-<timestamp>.log`
- Console output: warnings and errors only
- Return proper exit codes (0 success, non-zero failure)

### File Formatting
- **Newline at EOF**: All files MUST end with a newline (`\n`)
- **No trailing whitespace**

## Directory Structure

```
./
├── docs/           # Documentation
├── sources/        # Git submodules (QEMU, U-Boot, OpenSBI, Linux, Buildroot)
├── build/          # Build outputs (git-ignored)
├── test/           # Test scripts
├── configs/        # Configuration files (.config, defconfig, DTS)
├── scripts/        # Build and run scripts
├── patches/        # Submodule patches
└── specs/          # Specification documents (spec-driven development)
```

### Configuration File Locations
| Component | File Type | Location |
|-----------|-----------|----------|
| OpenSBI | DTS | `sources/opensbi/platform/generic/qemu_rv64_craft.dts` |
| U-Boot | DTS | `sources/u-boot/arch/riscv/dts/qemu_rv64_craft.dts` |
| U-Boot | Defconfig | `sources/u-boot/configs/qemu_rv64_craft_defconfig` |
| Linux | DTS | `sources/linux/arch/riscv/boot/dts/qemu/qemu_rv64_craft.dts` |
| Linux | Defconfig | `sources/linux/arch/riscv/configs/qemu_rv64_craft_defconfig` |

## Spec-Driven Development

This project uses `speckit`. Before implementation, read specs:
- `specs/<feature>/spec.md` - WHAT and WHY
- `specs/<feature>/plan.md` - Architecture and phases
- `specs/<feature>/tasks.md` - Actionable checklist
- `specs/<feature>/research.md` - Technical decisions

**Current feature branch**: `001-riscv-qemu-bootflow`

## Environment Setup

Source environment before building:
```bash
source scripts/env.sh
```

**Key Variables**:
- `ARCH=riscv`
- `CROSS_COMPILE=riscv64-linux-gnu-`
- `BUILD_DIR=./build`
- `SOURCES_DIR=./sources`

## Critical Rules for AI Agents

1. **Read specs first** - Before modifying any component, read relevant spec documents
2. **No source pollution** - All build outputs go to `./build/`
3. **Configuration over code** - Exhaust config options before patching source
4. **Minimal patches** - If source changes needed, make smallest possible change
5. **Document decisions** - Non-obvious choices require documentation in `./docs/`
6. **Test before commit** - Run `python3 test/run_boot_test.py` to verify boot
7. **DCO compliance** - All commits require `Signed-off-by` line
8. **Atomic changes** - One logical change per commit

## Troubleshooting

### Missing Components Error
```bash
ERROR: Missing components: QEMU SPL FIT Kernel Initrd
```
**Fix**: Run `./scripts/build_all.sh` first.

### GDB "Remote 'g' packet reply is too long"
```gdb
(gdb) set architecture riscv:rv64
```

### Source Code Not Found in GDB
Run GDB from project root directory.
