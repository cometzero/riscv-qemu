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
- Git rules (50/72 commit format, DCO, atomic commits)
- Directory structure (`./docs/`, `./sources/`, `./build/`, `./test/`, `./configs/`)
- Build and testing discipline

### Configuration-First Policy

Per constitution, always prefer configuration changes over source code:
1. Kconfig / defconfig changes
2. Device Tree modifications
3. Command-line options
4. Environment variables
5. Source code (last resort)

## Current Feature Branch

**Branch**: `001-riscv-qemu-bootflow`

See `specs/001-riscv-qemu-bootflow/` for all specification documents.
