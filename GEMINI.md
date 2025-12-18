# GEMINI.md - AI Development Guidelines

## Project Overview

This project implements a RISC-V boot flow on QEMU using Spec-Driven Development with `speckit`.

## Spec-Driven Development

This project uses `speckit` to generate and manage specifications. All development MUST follow the spec documents.

### Key Documents in `specs/` Directory

| Document | Purpose |
|----------|---------|
| `spec.md` | Feature specification (WHAT and WHY) |
| `plan.md` | Implementation plan (architecture, phases) |
| `tasks.md` | Actionable task checklist |
| `research.md` | Technical decisions and rationale |
| `quickstart.md` | Quick start guide |

### Development Workflow

1. **Read the spec first**: Before any implementation, read `specs/001-riscv-qemu-bootflow/spec.md`
2. **Follow the plan**: Use `plan.md` for architecture and component decisions
3. **Execute tasks**: Work through `tasks.md` checklist in order
4. **Reference research**: Check `research.md` for technical decisions

### Constitution

The project constitution at `.specify/memory/constitution.md` defines:
- Values (clarity, reproducibility, documentation)
- Coding principles (configuration-first, upstream guidelines)
- **Git Rules**:
  - **Commit Message Format**: Follow [Conventional Commits](https://www.conventionalcommits.org/).
    - Format: `<type>(<scope>): <subject>`
    - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  - **Message Wrapping**:
    - Subject line: Max 50 characters.
    - Body: Wrap at 72 characters.
  - **Signed-off-by**: All commits MUST include a `Signed-off-by` line (`git commit -s`).
  - **Atomic Commits**: Each commit must represent a single logical change.
- Directory structure (`./docs/`, `./sources/`, `./build/`, `./test/`, `./configs/`)
- Build and testing discipline

### Configuration-First Policy

Per constitution, always prefer configuration changes over source code:
1. Kconfig / defconfig changes
2. Device Tree modifications
3. Command-line options
4. Environment variables
5. Source code (last resort)

### File Formatting Rules

- **Newline at End of File**: Always ensure every source file (code, config, markdown, etc.) ends with a newline character (`\n`). This prevents "No newline at end of file" warnings in diffs.

## Configuration Locations

Custom configuration files should be maintained within their respective source trees:

| Component | File Type | Location |
|-----------|-----------|----------|
| **OpenSBI** | DTS | `sources/opensbi/platform/generic/qemu_rv64_craft.dts` |
| **U-Boot** | DTS | `sources/u-boot/arch/riscv/dts/qemu_rv64_craft.dts` |
| **U-Boot** | Defconfig | `sources/u-boot/configs/qemu_rv64_craft_defconfig` |
| **Linux** | DTS | `sources/linux/arch/riscv/boot/dts/qemu/qemu_rv64_craft.dts` |
| **Linux** | Defconfig | `sources/linux/arch/riscv/configs/qemu_rv64_craft_defconfig` |

## Current Feature Branch

**Branch**: `001-riscv-qemu-bootflow`

See `specs/001-riscv-qemu-bootflow/` for all specification documents.
