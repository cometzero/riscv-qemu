# Tasks: RISC-V WorldGuard QEMU Integration

**Input**: Design documents from `/specs/002-qemu-worldguard/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md

**Tests**: 수동 검증 (QEMU 빌드 및 부팅 테스트) - 자동화된 단위 테스트 없음

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (WorldGuard 패치 준비)

**Purpose**: WorldGuard 브랜치 fetch 및 cherry-pick 준비

- [x] T001 Fetch cwshu/qemu riscv-wg-v3 브랜치를 sources/qemu/ 로컬에 추가
- [x] T002 WorldGuard 관련 커밋 18개 목록 확인 및 cherry-pick 순서 검증

---

## Phase 2: Foundational (Cherry-pick 기반 커밋 적용)

**Purpose**: WorldGuard 핵심 기반 코드를 QEMU에 cherry-pick으로 적용

**⚠️ CRITICAL**: 이 Phase가 완료되어야 QEMU 빌드 및 WorldGuard 기능이 동작함

### Core Infrastructure Commits

- [x] T003 Cherry-pick d2daa188e8b6: exec: Add RISC-V WorldGuard WID to MemTxAttrs in sources/qemu/
- [x] T004 Cherry-pick f8ed123bac35: accel/tcg: memory access from CPU will pass access_type to IOMMU in sources/qemu/
- [x] T005 Cherry-pick 7fb836063f0d: system/physmem: Remove page-aligned section assertion in sources/qemu/
- [x] T006 Cherry-pick 02878bc9bbb4: accel/tcg: Store section pointer in CPUTLBEntryFull in sources/qemu/

### WorldGuard Global Config

- [x] T007 Cherry-pick a685479daf5f: hw/misc: riscv_worldguard: Add RISC-V WorldGuard global config in sources/qemu/

### RISC-V CPU Extension

- [x] T008 Cherry-pick 7612b5f0440b: target/riscv: Add CPU options of WorldGuard CPU extension in sources/qemu/
- [x] T009 Cherry-pick 8a75b7b64a5c: target/riscv: Add hard-coded CPU state of WG extension in sources/qemu/
- [x] T010 Cherry-pick cd336a384691: target/riscv: Add defines for WorldGuard CSRs in sources/qemu/
- [x] T011 Cherry-pick 851d73868318: target/riscv: Allow global WG config to set WG CPU callbacks in sources/qemu/
- [x] T012 Cherry-pick b2d5e0f5d673: target/riscv: Implement WorldGuard CSRs in sources/qemu/
- [x] T013 Cherry-pick bf77230b0c93: target/riscv: Add WID to MemTxAttrs of CPU memory transactions in sources/qemu/
- [x] T014 Cherry-pick 7a3d43bbfd57: target/riscv: Expose CPU options of WorldGuard in sources/qemu/

### WorldGuard API and Checker

- [x] T015 Cherry-pick e928a260473f: hw/misc: riscv_worldguard: Add API to enable WG extension of CPU in sources/qemu/
- [x] T016 Cherry-pick dcf690ef2c39: hw/misc: riscv_wgchecker: Implement RISC-V WorldGuard Checker in sources/qemu/
- [x] T017 Cherry-pick 8e3d8757c968: hw/misc: riscv_wgchecker: Implement wgchecker slot registers in sources/qemu/
- [x] T018 Cherry-pick 64269b0f97a3: hw/misc: riscv_wgchecker: Implement correct block-access behavior in sources/qemu/
- [x] T019 Cherry-pick 018e448e21c2: hw/misc: riscv_wgchecker: Check slot settings in translate in sources/qemu/

### Virt Machine Integration

- [x] T020 Cherry-pick b977233a0522: hw/riscv: virt: Add WorldGuard support in sources/qemu/

**Checkpoint**: Cherry-pick 완료 - QEMU 빌드 가능 상태 ✓

**Note**: Build fix applied - Changed `static Property` to `static const Property` in both riscv_worldguard.c and riscv_wgchecker.c for QEMU v10.1.3 compatibility.

---

## Phase 3: User Story 1 - WorldGuard 패치 QEMU 통합 (Priority: P1) 🎯 MVP

**Goal**: WorldGuard 패치가 적용된 QEMU를 빌드하고 WorldGuard 옵션이 인식되는지 확인

**Independent Test**: `./scripts/build-qemu.sh` 성공 및 `-M virt,help`에서 WorldGuard 옵션 표시

### Implementation for User Story 1

- [x] T021 [US1] Execute ./scripts/build-qemu.sh to build QEMU with WorldGuard patches
- [x] T022 [US1] Verify QEMU build success and binary exists at build/qemu/install/bin/qemu-system-riscv64
- [x] T023 [US1] Run `qemu-system-riscv64 -M virt,help` and confirm WorldGuard option is listed
- [x] T024 [US1] Document WorldGuard QEMU option syntax in docs/worldguard.md

**Checkpoint**: WorldGuard 패치 QEMU 빌드 완료, WorldGuard 옵션 확인됨 ✓ (`wg=<bool>`)

---

## Phase 4: User Story 2 - WorldGuard 옵션 활성화 QEMU 실행 (Priority: P2)

**Goal**: WorldGuard 옵션을 활성화하여 QEMU를 실행하고 오류 없이 시작되는지 확인

**Independent Test**: WorldGuard 옵션으로 QEMU 실행 시 오류 없이 시작되고 OpenSBI 부팅 확인

### Implementation for User Story 2

- [x] T025 [P] [US2] Create scripts/run-qemu-worldguard.sh based on scripts/run-qemu.sh with WorldGuard option enabled
- [x] T026 [US2] Test QEMU starts without errors with WorldGuard enabled using scripts/run-qemu-worldguard.sh
- [x] T027 [US2] Verify OpenSBI boots and check for WorldGuard-related messages in boot log
- [x] T028 [US2] Test regression: Verify existing scripts/run-qemu.sh still works (WorldGuard disabled)

**Checkpoint**: WorldGuard 활성화 QEMU 실행 성공, OpenSBI 부팅 확인 ✓

---

## Phase 5: User Story 3 - WorldGuard 활성화 전체 부트 체인 (Priority: P3)

**Goal**: WorldGuard가 활성화된 QEMU에서 OpenSBI → U-Boot → Linux 전체 부트 체인 동작 확인

**Independent Test**: Linux 로그인 프롬프트까지 도달하고 FATAL/PANIC 오류 없음

### Implementation for User Story 3

- [x] T029 [US3] Execute full boot chain with WorldGuard enabled and capture boot log
- [x] T030 [US3] Verify U-Boot boots successfully with WorldGuard enabled
- [x] T031 [US3] Verify Linux kernel boots and login prompt appears
- [x] T032 [US3] Check boot log for any WorldGuard-related errors or warnings
- [x] T033 [US3] Compare boot time with WorldGuard enabled vs disabled (should be within 120%)

**Checkpoint**: WorldGuard 활성화 전체 부트 체인 검증 완료 ✓

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 문서화 및 정리 작업

- [x] T034 [P] Update docs/worldguard.md with complete usage guide
- [x] T035 [P] Update docs/version-history.md with WorldGuard integration record
- [x] T036 Commit all WorldGuard changes with descriptive commit message
- [x] T037 Update README.md or project documentation mentioning WorldGuard support

---

## Summary

**All 44 tasks completed.**

- Phase 1-2: 18 WorldGuard commits cherry-picked, build fix applied
- Phase 3: QEMU build verified, WorldGuard option confirmed (`-M virt,wg=on`)
- Phase 4-5: Full boot chain verified (OpenSBI → U-Boot → Linux → Buildroot login)
- Phase 6: Documentation created
- Phase 7: Advanced features implemented

**Recent Additions (Phase 7):**
- [x] T038 Expose WorldGuard machine options (`wg-nworlds`, `wg-trustedwid`, `wg-hwbypass`, `wg-tzcompat`)
- [x] T039 Implement default wgChecker DRAM slots for hwbypass=off testing
- [x] T040 Implement default wgChecker UART slots for console access
- [x] T041 Verify full boot chain with hwbypass=off
- [x] T042 Create bare-metal test framework (`tests/worldguard/`)
- [x] T043 Implement WorldGuard CSR header definitions
- [x] T044 Implement wgChecker MMIO register definitions

**Key Files Created/Modified:**
- `scripts/run-qemu-worldguard.sh` - WorldGuard-enabled run script
- `docs/worldguard.md` - Usage documentation
- `docs/worldguard-testing-todo.md` - Future work documentation
- `sources/qemu/hw/misc/riscv_worldguard.c` - Fixed property array (const)
- `sources/qemu/hw/misc/riscv_wgchecker.c` - Fixed property array (const)
- `sources/qemu/hw/riscv/virt.c` - Machine options & default slots
- `sources/qemu/include/hw/riscv/virt.h` - RISCVVirtState fields
- `tests/worldguard/` - Bare-metal test framework

