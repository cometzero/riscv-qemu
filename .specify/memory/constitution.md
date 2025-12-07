<!--
=============================================================================
Sync Impact Report
=============================================================================
Version change: 1.0.0 → 1.0.1

Modified Principles:
  - XI. Signed-off-by (DCO): Added requirement to use `git commit -s` flag

Added Sections: None

Removed Sections: None

Templates requiring updates:
  ✅ plan-template.md - No changes needed
  ✅ spec-template.md - No changes needed
  ✅ tasks-template.md - No changes needed

Follow-up TODOs: None
=============================================================================
-->
-->

# riscv-qemu-bootflow Constitution

This constitution defines the development workflow, quality standards, and guiding principles for the RISC-V QEMU boot flow project. It governs all boot chain components: QEMU, U-Boot (SPL + proper), OpenSBI, Linux Kernel, and Buildroot rootfs.

## Values

### I. Clarity and Reproducibility

Every aspect of this project MUST prioritize clarity and reproducibility over cleverness.

- All builds MUST be deterministic and reproducible from a clean state
- Configuration and build steps MUST be scripted, not performed ad-hoc
- Complex solutions require explicit justification; simple approaches are preferred

### II. Traceable Boot Flow

The boot flow MUST remain easy to understand and trace from BootROM to userspace shell.

- The boot sequence `QEMU BootROM → U-Boot SPL → OpenSBI → U-Boot proper → Linux Kernel → Buildroot rootfs` MUST be clearly documented
- Each handoff between boot stages MUST be observable and verifiable via boot logs
- Deviations from standard boot behavior MUST be documented with rationale

### III. Document Decisions

All decisions and deviations from upstream behavior MUST be documented.

- Non-obvious configuration choices MUST be recorded in `./docs`
- Local patches MUST include a commit message explaining why upstream defaults are insufficient
- Changes to the boot flow MUST be reflected in updated documentation before merge

## Coding and Change Principles

### IV. Follow Upstream Guidelines

All local patches MUST follow the upstream coding guidelines for each component.

- Linux kernel patches: Follow Documentation/process/coding-style.rst
- U-Boot patches: Follow doc/develop/codingstyle.rst
- OpenSBI patches: Follow OpenSBI coding conventions
- QEMU patches: Follow QEMU coding style
- Patches SHOULD be written in upstreamable style even if not intended for submission

### V. Configuration Before Code

Desired behavior MUST be achieved through configuration changes before resorting to source code modifications.

**Order of preference**:
1. Kconfig / `.config` / defconfig changes
2. Device Tree Source (DTS) modifications
3. Command-line options (kernel cmdline, QEMU args)
4. Environment variables
5. Source code changes (last resort)

### VI. Minimal Local Patches

Local patches MUST be minimal and well-justified.

- Each patch MUST represent the smallest change needed to achieve the goal
- Patches MUST NOT include unrelated changes (no style fixes mixed with functional changes)
- Temporary debug code MUST NOT be committed to the main branch

### VII. Justify Code Changes

Source code modifications are permitted only when configuration is insufficient.

- The commit message MUST explain why configuration was insufficient
- The commit message MUST describe what alternatives were considered
- Complex patches SHOULD include inline comments explaining non-obvious logic

## Git and Version Control Rules

### VIII. Git Submodules Structure

The project MUST use Git with submodules for all boot components under a single top-level repository.

- Each upstream component (QEMU, U-Boot, OpenSBI, Linux, Buildroot) MUST be a Git submodule under `./sources/`
- Submodules MUST point to specific commits (tags or known-good commits), not branches
- Updating a submodule MUST be a separate commit with rationale

### IX. Commit Message Format

All commit messages MUST follow the 50/72 rule and be written in English.

**Format**:
```
<summary line: ≤50 chars, imperative mood>

<body: wrapped at 72 columns>
- Explain the motivation/intention of the change
- Describe what was changed technically
- Reference relevant issues or documentation

Signed-off-by: Name <email>
```

### X. Atomic Commits

Each commit MUST represent one logical change.

- One feature, one fix, or one refactor per commit
- Do NOT mix unrelated changes (e.g., style cleanups + functional changes)
- Large changes SHOULD be split into a series of smaller, reviewable commits

### XI. Signed-off-by (DCO)

Every commit MUST include a Signed-off-by line complying with the Developer Certificate of Origin.

- Use `git commit -s` to automatically add Signed-off-by matching the Author
- The Signed-off-by identity MUST match the commit Author (same name and email)

```
Signed-off-by: Chanho Park <parkch98@gmail.com>
```

### XII. Commit Content Requirements

Commit messages MUST state both intention and technical changes.

- **Intention**: Why is this change being made? What problem does it solve?
- **Technical**: What files/functions were modified? How does the solution work?

## Repository Layout

### XIII. Directory Structure

The top-level repository MUST maintain the following directory structure:

```
./
├── docs/       # Design documents, boot flow descriptions, diagrams, HOWTOs
├── sources/    # Git submodules: QEMU, U-Boot, OpenSBI, Linux, Buildroot
├── build/      # All build outputs and intermediate artefacts
├── test/       # Test scripts, log analyzers, expected-output definitions
└── configs/    # .config, defconfig, DTS, QEMU run scripts/configs
```

### XIV. Source Purity

Source trees MUST NOT be polluted by build outputs.

- All build artefacts MUST be placed under `./build/`
- Out-of-tree builds MUST be used where supported
- If an upstream build system requires in-tree artefacts, document the exception in `./docs/build-exceptions.md`

### XV. Build Directory Organization

Build outputs MUST be organized by component under `./build/`:

```
./build/
├── qemu/       # QEMU build outputs
├── u-boot/     # U-Boot SPL and proper outputs
├── opensbi/    # OpenSBI firmware outputs
├── linux/      # Linux kernel outputs
├── rootfs/     # Buildroot root filesystem outputs
├── logs/       # Build logs
└── test-logs/  # Test execution logs
```

### XVI. Configuration Version Control

All configuration files MUST be version-controlled under `./configs/`:

```
./configs/
├── qemu/           # QEMU machine configs, run scripts
├── u-boot/         # U-Boot defconfig, environment
├── opensbi/        # OpenSBI platform config
├── linux/          # Kernel defconfig, fragments
├── buildroot/      # Buildroot defconfig
└── dts/            # Device Tree Sources
```

### XVII. Documentation Standards

Documentation MUST reside in `./docs/` with clear organization:

- `boot-flow.md`: Complete boot sequence description
- `build-howto.md`: Step-by-step build instructions
- `testing.md`: Test execution guide
- Component-specific docs in subdirectories as needed

## Build & Logging Rules

### XVIII. Script-Driven Builds

All builds MUST be driven by Bash-based build scripts.

- No ad-hoc manual command sequences for reproducible builds
- Scripts MUST be located in a well-known location (e.g., `./scripts/`)
- Each script MUST have a `--help` option documenting usage

### XIX. Build Granularity

Build scripts MUST support multiple granularities:

- **Per-component**: Build only QEMU, only U-Boot, only Linux, etc.
- **Full chain**: Build all components in dependency order
- **Clean operations**: Remove build artefacts without affecting source checkouts
- **Distclean**: Deep clean including generated configs (with confirmation)

### XX. Logging Discipline

Build scripts MUST implement structured logging:

- Detailed logs MUST be written to `./build/logs/<component>-<timestamp>.log`
- Console output (stdout/stderr) MUST show only warnings and errors
- Log files MUST capture full command output for debugging
- Build start/end timestamps MUST be recorded

### XXI. Exit Code Discipline

Build scripts MUST return proper exit codes for CI integration:

- Return `0` on success
- Return non-zero on any failure
- Fail fast: stop on first error unless explicitly running in continue-on-error mode
- Scripts MUST be composable in CI pipelines

## Testing Discipline

### XXII. Primary Test Method

The primary test is the QEMU boot log and QEMU exit status.

- QEMU MUST be configured to exit with status code on kernel panic or boot failure
- Boot logs MUST be captured to files for analysis
- Tests MUST NOT depend on network connectivity

### XXIII. Test Implementation

Tests MAY be written in Python (preferred) or Bash.

- Python tests SHOULD use standard library or minimal dependencies
- Bash tests MUST be POSIX-compatible where possible
- Test scripts MUST be executable and have a shebang line

### XXIV. Boot Milestone Verification

Tests MUST verify the following boot milestones:

1. **U-Boot SPL**: Started successfully, performed memory initialization, handed off to OpenSBI
2. **OpenSBI**: Initialized, reported version and platform information
3. **U-Boot proper**: Loaded, reached command prompt or auto-booted kernel
4. **Linux kernel**: Booted, reached userspace init
5. **Buildroot**: Init started, login prompt or expected shell available

### XXV. Pass/Fail Criteria

Tests MUST implement clear pass/fail logic:

**FAIL conditions** (any of these):
- Kernel panic detected in boot log
- Boot loop detected (repeated boot messages)
- Expected milestone message missing
- QEMU exits with non-zero status
- Timeout before reaching expected milestone

**PASS conditions** (all required):
- All milestone messages present in correct order
- QEMU exits cleanly (status 0) or reaches expected state
- No error patterns detected in boot log

### XXVI. Test Log Management

Test outputs MUST be stored in `./build/test-logs/`:

- `<test-name>-<timestamp>.log`: Full QEMU console output
- `<test-name>-<timestamp>.result`: Pass/fail summary with milestone checklist
- Test logs MUST be preserved for CI artifact collection

## Configuration-First Policy

### XXVII. Change Preference Order

For any requested change, follow this order of preference:

1. **Configuration files** (`./configs/`): Kconfig, defconfig, DTS, QEMU command line
2. **Source code** (minimal patch): Only when configuration is demonstrably insufficient
3. **Document the change**: Record non-obvious configurations in `./docs/`

### XXVIII. Configuration Versioning

All used configurations MUST be version-controlled.

- No local-only config state; all configs committed to repository
- Config changes MUST be separate commits with explanatory messages
- Derived configs (e.g., full `.config` from defconfig) MAY be gitignored but MUST be reproducible

### XXIX. Configuration Documentation

Non-obvious configuration changes MUST be documented.

- Document in `./docs/` or adjacent README files
- Explain **why** the configuration was chosen, not just **what** it is
- Cross-reference related configurations across components

## Governance

This constitution supersedes all other development practices for this project.

**Amendment Process**:
1. Propose amendment with rationale in a Git commit
2. Amendment requires explicit approval before merge
3. Update version number according to semantic versioning rules
4. Document migration plan if amendment affects existing work

**Compliance**:
- All pull requests MUST pass constitution compliance review
- Reviewers MUST verify adherence to these principles
- Non-compliance requires explicit justification and approval

**Versioning Policy**:
- MAJOR: Backward-incompatible principle changes or removals
- MINOR: New principles added or existing principles materially expanded
- PATCH: Clarifications, typo fixes, non-semantic refinements

**Runtime Guidance**:
- Use this constitution as the primary reference during development
- When in doubt, prefer the simpler and more transparent approach
- Ask for clarification rather than assuming compliance

**Version**: 1.0.1 | **Ratified**: 2025-12-07 | **Last Amended**: 2025-12-07
