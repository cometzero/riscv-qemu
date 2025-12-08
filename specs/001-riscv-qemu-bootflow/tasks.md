# Tasks: RISC-V QEMU Boot Flow

**Input**: Design documents from `/specs/001-riscv-qemu-bootflow/`  
**Prerequisites**: plan.md (required), spec.md (required), research.md, quickstart.md

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create project structure and initial documentation

- [x] T001 Create top-level directory structure: `./docs/`, `./sources/`, `./build/`, `./test/`, `./configs/`, `./scripts/`
- [x] T002 [P] Create `.gitignore` to ignore `./build/` directory
- [x] T003 [P] Create initial `README.md` with project overview and goals
- [x] T004 [P] Create placeholder `docs/boot-flow.md`
- [x] T005 [P] Create placeholder `docs/build-howto.md`
- [x] T006 [P] Create placeholder `docs/testing.md`
- [x] T007 [P] Create placeholder `docs/configuration.md`

**Checkpoint**: Directory structure in place, basic README committed

---

## Phase 2: Foundational (Submodules & Environment)

**Purpose**: Add all Git submodules and create environment setup scripts. MUST complete before user story work.

⚠️ **CRITICAL**: No user story work can begin until this phase is complete

- [x] T008 Add QEMU as Git submodule at `./sources/qemu` from `https://gitlab.com/qemu-project/qemu.git`
- [x] T009 Add U-Boot as Git submodule at `./sources/u-boot` from `https://source.denx.de/u-boot/u-boot.git`
- [x] T010 Add OpenSBI as Git submodule at `./sources/opensbi` from `https://github.com/riscv-software-src/opensbi.git`
- [x] T011 Add Linux kernel as Git submodule at `./sources/linux` from `https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git`
- [x] T012 Add Buildroot as Git submodule at `./sources/buildroot` from `https://git.buildroot.net/buildroot`
- [x] T013 Create environment setup script `scripts/env.sh` with ARCH, CROSS_COMPILE, paths
- [x] T014 Create prerequisite check script `scripts/check_prereqs.sh` that verifies required apt packages
- [x] T015 [P] Create config directory structure: `configs/qemu/`, `configs/u-boot/`, `configs/opensbi/`, `configs/linux/`, `configs/buildroot/`
- [x] T016 [P] Create QEMU run config file `configs/qemu/run_qemu.conf`
- [x] T017 [P] Create Linux kernel defconfig fragment `configs/linux/riscv64_virt.defconfig`
- [x] T018 [P] Create Linux bootargs fragment `configs/linux/bootargs.fragment`
- [x] T019 [P] Create Buildroot minimal defconfig `configs/buildroot/qemu_riscv64_minimal.defconfig`

**Checkpoint**: All submodules initialized. Run `git submodule status` to verify.

---

## Phase 3: User Story 1 - Study Complete Boot Chain (Priority: P1) 🎯 MVP

**Goal**: Achieve full boot from SPL to Buildroot login prompt

**Independent Test**: Run QEMU and observe boot log showing all 5 milestones (SPL, OpenSBI, U-Boot, Linux, login prompt)

### Build Scripts for US1

- [x] T020 [US1] Create QEMU build script `scripts/build_qemu.sh` with out-of-tree build to `./build/qemu/`
- [x] T021 [US1] Create OpenSBI build script `scripts/build_opensbi.sh` with PLATFORM=generic to `./build/opensbi/`
- [x] T022 [US1] Create U-Boot build script `scripts/build_uboot.sh` with qemu-riscv64_spl_defconfig, integrating OpenSBI fw_dynamic.bin to `./build/u-boot/`
- [x] T023 [US1] Create Linux kernel build script `scripts/build_linux.sh` with defconfig to `./build/linux/`
- [x] T024 [US1] Create Buildroot build script `scripts/build_buildroot.sh` for rootfs-only (no kernel) to `./build/rootfs/`
- [x] T025 [US1] Create build orchestration script `scripts/build_all.sh` calling all component scripts in order
- [x] T026 [US1] Create QEMU launch script `scripts/run_qemu.sh` with correct -bios and -device loader arguments
- [x] T027 [US1] Create clean script `scripts/clean.sh` with clean and distclean options

### Integration & Verification for US1

- [x] T028 [US1] Build all components using `scripts/build_all.sh`
- [x] T029 [US1] Verify boot reaches U-Boot SPL (log shows "U-Boot SPL")
- [x] T030 [US1] Verify OpenSBI initializes (log shows "OpenSBI v")
- [x] T031 [US1] Verify U-Boot proper runs (log shows "U-Boot 20")
- [x] T032 [US1] Verify Linux kernel boots (log shows "Linux version")
- [x] T033 [US1] Verify Buildroot login prompt appears (log shows "buildroot login:")

**Checkpoint**: Full boot flow working. User can clone, build, and boot to login prompt.

---

## Phase 4: User Story 2 - Configuration-Driven Experimentation (Priority: P2)

**Goal**: Enable configuration changes without source code modification

**Independent Test**: Modify kernel cmdline, rebuild, verify change appears in boot log

### Configuration Infrastructure for US2

- [ ] T034 [US2] Update `scripts/build_linux.sh` to merge `configs/linux/bootargs.fragment` into kernel config
- [ ] T035 [US2] Create U-Boot environment file `configs/u-boot/qemu_riscv64.env` for boot delay and variables
- [ ] T036 [US2] Update `scripts/build_uboot.sh` to apply custom environment from configs/u-boot/
- [ ] T037 [US2] Document configuration modification workflow in `docs/configuration.md`

### Verification for US2

- [ ] T038 [US2] Modify kernel cmdline in `configs/linux/bootargs.fragment`, rebuild, verify in boot log
- [ ] T039 [US2] Modify U-Boot boot delay in `configs/u-boot/qemu_riscv64.env`, rebuild, verify behavior

**Checkpoint**: Configuration changes take effect without patching source code.

---

## Phase 5: User Story 3 - Automated Regression Testing (Priority: P3)

**Goal**: Automated boot test with pass/fail detection

**Independent Test**: Run `python3 test/run_boot_test.py` and verify exit code 0 on success, non-zero on failure

### Test Framework for US3

- [ ] T040 [P] [US3] Create milestone pattern definitions in `test/milestones.py`
- [ ] T041 [P] [US3] Create QEMU runner module in `test/qemu_runner.py`
- [ ] T042 [P] [US3] Create log parser module in `test/log_parser.py`
- [ ] T043 [US3] Create main test harness in `test/run_boot_test.py` integrating all modules
- [ ] T044 [US3] Add error pattern detection (kernel panic, boot loop) to `test/log_parser.py`
- [ ] T045 [US3] Add 3-minute timeout handling to `test/qemu_runner.py`
- [ ] T046 [US3] Create test fixtures directory `test/fixtures/` with expected milestone patterns

### Verification for US3

- [ ] T047 [US3] Run boot test and verify exit code 0 on successful boot
- [ ] T048 [US3] Intentionally break boot (remove artifact), verify test detects failure with exit code 1

**Checkpoint**: Automated test returns pass/fail based on boot log analysis.

---

## Phase 6: User Story 4 - Learning with Documentation (Priority: P4)

**Goal**: Complete documentation for learning and reference

**Independent Test**: New user can follow documentation to understand and build the project

### Documentation for US4

- [ ] T049 [P] [US4] Write complete boot flow explanation in `docs/boot-flow.md` with ASCII diagram
- [ ] T050 [P] [US4] Write step-by-step build instructions in `docs/build-howto.md`
- [ ] T051 [P] [US4] Write test execution guide in `docs/testing.md`
- [ ] T052 [US4] Write configuration modification guide in `docs/configuration.md`
- [ ] T053 [US4] Update `README.md` with complete prerequisite list and quick-start commands
- [ ] T054 [US4] Add prerequisite apt package list to `docs/build-howto.md`

**Checkpoint**: Documentation covers 100% of first-time setup steps.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and validation

- [ ] T055 [P] Add logging improvements to all build scripts (warnings/errors to console, details to log files)
- [ ] T056 [P] Ensure all scripts return non-zero exit codes on failure
- [ ] T057 Perform fresh-clone test on clean Ubuntu 24.04 VM
- [ ] T058 Verify SC-001: Clone to boot in under 60 minutes
- [ ] T059 Verify SC-007: No undocumented prerequisites
- [ ] T060 Review and commit with proper 50/72 message format per constitution

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - can start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 - BLOCKS all user stories
- **Phase 3 (US1)**: Depends on Phase 2 - Core boot flow
- **Phase 4 (US2)**: Depends on Phase 3 (US1) - Requires working boot to test config changes
- **Phase 5 (US3)**: Depends on Phase 3 (US1) - Requires working boot to test
- **Phase 6 (US4)**: Depends on Phase 3 (US1) - Documentation needs working system to document
- **Phase 7 (Polish)**: Depends on all user stories

### User Story Independence

- **US1 (P1)**: Must complete first (provides boot flow)
- **US2 (P2)**: Can start after US1 complete
- **US3 (P3)**: Can start after US1 complete (parallel with US2 possible)
- **US4 (P4)**: Can start after US1 complete (parallel with US2/US3 possible)

### Within Each Phase

- Tasks marked [P] can run in parallel (different files)
- Sequential tasks depend on previous tasks in the phase
- Build scripts must exist before integration/verification tasks

---

## Parallel Execution Examples

### Phase 1 (after T001):
```bash
# All placeholder files can be created in parallel:
T002, T003, T004, T005, T006, T007
```

### Phase 2 (after T008-T012 submodules):
```bash
# Config files can be created in parallel:
T015, T016, T017, T018, T019
```

### Phase 5 (Test Framework):
```bash
# Test modules can be written in parallel:
T040, T041, T042
```

### Phase 6 (Documentation):
```bash
# Docs can be written in parallel:
T049, T050, T051
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (submodules, env scripts)
3. Complete Phase 3: User Story 1 (build scripts, boot flow)
4. **STOP and VALIDATE**: Boot reaches login prompt
5. Can demo/use at this point

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready
2. Add US1 (Phase 3) → Boot flow works → **MVP!**
3. Add US2 (Phase 4) → Config-driven changes work
4. Add US3 (Phase 5) → Automated testing works
5. Add US4 (Phase 6) → Documentation complete
6. Phase 7 → Production-ready

---

## Summary

| Phase | Tasks | Parallel | Description |
|-------|-------|----------|-------------|
| Phase 1 | 7 | 6 | Project setup |
| Phase 2 | 12 | 5 | Submodules & environment |
| Phase 3 (US1) | 14 | 0 | Core boot flow (MVP) |
| Phase 4 (US2) | 6 | 0 | Configuration infrastructure |
| Phase 5 (US3) | 9 | 3 | Test automation |
| Phase 6 (US4) | 6 | 3 | Documentation |
| Phase 7 | 6 | 2 | Polish |
| **Total** | **60** | **19** | |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
- Per constitution: configuration changes before source patches
- Per constitution: all commits with Signed-off-by and 50/72 format
