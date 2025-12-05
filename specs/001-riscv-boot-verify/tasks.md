# Tasks: RISC-V QEMU 부트 체인 검증

**Input**: Design documents from `/specs/001-riscv-boot-verify/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: Tests are not explicitly requested in the specification, so test tasks are not included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Repository root: `/home/ubuntu/work/risc-v/`
- Source directories: `sources/qemu/`, `sources/u-boot/`, `sources/opensbi/`, `sources/linux/`, `sources/buildroot/`
- Build directories: `build/qemu/`, `build/u-boot/`, `build/opensbi/`, `build/linux/`, `build/buildroot/`
- Scripts: `scripts/`
- Configs: `configs/`
- Documentation: `docs/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create project root directory structure (sources/, configs/, scripts/, docs/, build/)
- [x] T002 [P] Initialize Git repository with .gitignore, README.md, and LICENSE files
- [x] T003 [P] Create scripts/setup-env.sh for Ubuntu 24.04 package installation
- [x] T004 Execute scripts/setup-env.sh to install build-essential, git, and RISC-V toolchain dependencies
- [x] T005 Verify RISC-V cross-toolchain installation (riscv64-linux-gnu-gcc --version)
- [x] T006 Create scripts/toolchain-env.sh for environment variable management

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 [P] [US4] Initialize Git submodule for QEMU at sources/qemu/
- [x] T008 [P] [US4] Initialize Git submodule for U-Boot at sources/u-boot/
- [x] T009 [P] [US4] Initialize Git submodule for OpenSBI at sources/opensbi/
- [x] T010 [P] [US4] Initialize Git submodule for Linux Kernel at sources/linux/
- [x] T011 [P] [US4] Initialize Git submodule for Buildroot at sources/buildroot/
- [x] T012 [US4] Pin each submodule to a specific commit hash and commit .gitmodules
- [x] T013 [P] [US4] Create build/logs/ directory for build logs
- [x] T014 [P] [US4] Create build/images/ directory for final boot images

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 4 - QEMU 소스 빌드 환경 설정 (Priority: P1) 🎯 MVP Component 1

**Goal**: 개발자는 QEMU 소스 빌드에 필요한 모든 의존성 패키지를 쉽게 설치하고, 빌드 환경을 설정할 수 있어야 한다.

**Independent Test**: scripts/setup-env.sh 스크립트를 실행하여 필요한 패키지가 모두 설치되고, QEMU 빌드에 필요한 환경 변수가 설정되는지 확인할 수 있다.

### Implementation for User Story 4

- [x] T015 [US4] Update scripts/setup-env.sh to include QEMU build dependencies (libglib2.0-dev, libpixman-1-dev, libfdt-dev, zlib1g-dev, ninja-build, pkg-config)
- [x] T016 [US4] Update scripts/toolchain-env.sh to set QEMU-related environment variables (PATH for build/toolchain/qemu/bin)
- [x] T017 [US4] Verify QEMU build dependencies installation by checking package versions
- [x] T018 [US4] Document QEMU build environment setup in docs/qemu-build-setup.md

**Checkpoint**: At this point, QEMU build environment should be fully configured

---

## Phase 4: User Story 5 - QEMU 소스 다운로드 및 초기 설정 (Priority: P1) 🎯 MVP Component 2

**Goal**: 개발자는 프로젝트 저장소 내에 QEMU 소스 코드를 쉽게 다운로드하고, 초기 설정(configure)을 수행할 수 있어야 한다.

**Independent Test**: scripts/get-qemu-source.sh를 실행하여 QEMU 소스가 sources/qemu 디렉토리에 클론되고, scripts/configure-qemu.sh를 실행하여 빌드 디렉토리(build/qemu)에 QEMU가 성공적으로 설정(configure)되는지 확인할 수 있다.

### Implementation for User Story 5

- [x] T019 [US5] Create scripts/get-qemu-source.sh to clone QEMU source to sources/qemu/
- [x] T020 [US5] Pin QEMU submodule to specific stable commit hash
- [x] T021 [US5] Create configs/qemu/qemu_riscv_virt.config for QEMU configure options
- [x] T022 [US5] Create scripts/configure-qemu.sh to configure QEMU with --target-list=riscv64-softmmu --enable-virtfs --prefix=build/toolchain/qemu
- [x] T023 [US5] Execute scripts/configure-qemu.sh and verify build/qemu/ directory creation
- [x] T024 [US5] Document QEMU source download and configuration in docs/qemu-source-setup.md

**Checkpoint**: At this point, QEMU source should be downloaded and configured

---

## Phase 5: User Story 6 - QEMU 소스 빌드 및 설치 (Priority: P1) 🎯 MVP Component 3

**Goal**: 개발자는 설정된 QEMU 소스 코드를 컴파일하고, 지정된 디렉토리에 설치할 수 있어야 한다.

**Independent Test**: scripts/build-qemu.sh 스크립트를 실행하여 QEMU가 build/qemu 디렉토리에서 성공적으로 빌드되고, 지정된 build/toolchain/qemu 디렉토리에 바이너리가 설치되는지 확인할 수 있다.

### Implementation for User Story 6

- [x] T025 [US6] Create scripts/build-qemu.sh to build QEMU with make -j$(nproc) in build/qemu/
- [x] T026 [US6] Configure build-qemu.sh to log output to build/logs/qemu_build.log
- [x] T027 [US6] Create scripts/install-qemu.sh to install QEMU to build/toolchain/qemu/bin/
- [x] T028 [US6] Execute scripts/build-qemu.sh and verify QEMU compilation success
- [x] T029 [US6] Execute scripts/install-qemu.sh and verify qemu-system-riscv64 installation
- [x] T030 [US6] Verify installed QEMU version with build/toolchain/qemu/bin/qemu-system-riscv64 --version
- [x] T031 [US6] Document QEMU build and installation process in docs/qemu-build.md

**Checkpoint**: At this point, QEMU should be fully built and installed

---

## Phase 6: User Story 1 - RISC-V QEMU 부트 체인 엔드투엔드 검증 (Priority: P1) 🎯 MVP Core

**Goal**: 개발자 또는 엔지니어는 Ubuntu 24.04 헤드리스 서버의 QEMU 가상 머신에서 완전한 RISC-V 부트 체인을 신속하게 설정하고 검증하기를 원합니다.

**Independent Test**: 주요 빌드/부트 스크립트를 실행하고 QEMU 콘솔에서 예상되는 busybox 프롬프트를 관찰하여 완전히 테스트할 수 있습니다.

### Implementation for User Story 1 - U-Boot Component

- [x] T032 [P] [US1] Create configs/u-boot/riscv64_qemu_virt_defconfig for U-Boot configuration
- [x] T033 [US1] Create scripts/build-uboot.sh to build U-Boot SPL and U-Boot with out-of-tree build in build/u-boot/
- [x] T034 [US1] Configure build-u-boot.sh to log output to build/logs/u-boot_build.log
- [x] T035 [US1] Execute scripts/build-uboot.sh and verify u-boot-spl.bin and u-boot.itb creation

### Implementation for User Story 1 - OpenSBI Component

- [x] T036 [P] [US1] Create configs/opensbi/platform/qemu_virt.config for OpenSBI configuration
- [x] T037 [US1] Create scripts/build-opensbi.sh to build OpenSBI with PLATFORM=generic and FW_DYNAMIC in build/opensbi/
- [x] T038 [US1] Configure build-opensbi.sh to log output to build/logs/opensbi_build.log
- [x] T039 [US1] Execute scripts/build-opensbi.sh and verify fw_payload.bin or fw_dynamic.bin creation

### Implementation for User Story 1 - Linux Kernel Component

- [x] T040 [P] [US1] Create configs/linux/riscv_qemu_virt_defconfig for Linux Kernel configuration with console and earlycon options
- [x] T041 [US1] Create scripts/build-linux.sh to build Linux Kernel with out-of-tree build in build/linux/
- [x] T042 [US1] Configure build-linux.sh to log output to build/logs/linux_build.log
- [x] T043 [US1] Execute scripts/build-linux.sh and verify vmlinux and virt.dtb creation

### Implementation for User Story 1 - Buildroot Component

- [x] T044 [P] [US1] Create configs/buildroot/riscv64_virt_defconfig for Buildroot configuration with BusyBox
- [x] T045 [US1] Create scripts/build-buildroot.sh to build Buildroot rootfs with out-of-tree build in build/buildroot/
- [x] T046 [US1] Configure build-buildroot.sh to log output to build/logs/buildroot_build.log
- [x] T047 [US1] Execute scripts/build-buildroot.sh and verify rootfs.cpio creation
- [x] T048 [US1] Copy rootfs.cpio to build/images/ directory

### Implementation for User Story 1 - Boot Chain Integration

- [x] T049 [US1] Create scripts/prepare-images.sh to copy all boot images to build/images/ directory
- [x] T050 [US1] Create scripts/run-qemu.sh to launch QEMU with all boot chain components using build/toolchain/qemu/bin/qemu-system-riscv64
- [x] T051 [US1] Configure run-qemu.sh with QEMU options (-machine virt -cpu rv64 -smp 4 -m 2G -nographic)
- [x] T052 [US1] Configure run-qemu.sh to load OpenSBI (-bios), U-Boot, Kernel (-kernel), DTB (-dtb), and initramfs (-initrd)
- [ ] T053 [US1] Execute scripts/run-qemu.sh and verify boot to busybox shell prompt (Deferred to Phase 8)
- [ ] T054 [US1] Verify /proc/cpuinfo and dmesg commands work in QEMU console
- [x] T055 [US1] Create scripts/build-all.sh to orchestrate complete build of all components
- [ ] T056 [US1] Document end-to-end boot chain verification in docs/boot-chain-verification.md

**Checkpoint**: At this point, complete RISC-V boot chain should boot successfully to busybox shell

---

## Phase 7: User Story 2 - 개별 구성 요소 개발 및 디버깅 (Priority: P2)

**Goal**: 개발자는 RISC-V 부트 체인의 특정 구성 요소를 수정하거나 디버깅해야 합니다. 전체 부트 체인을 다시 컴파일하지 않고도 개별 구성 요소를 다시 빌드하고 테스트할 수 있는 기능이 필요합니다.

**Independent Test**: 특정 구성 요소의 소스를 수정하고, 전용 스크립트를 사용하여 해당 구성 요소만 다시 빌드한 다음, QEMU를 부팅하여 변경 사항 및 로그를 관찰하여 테스트할 수 있습니다.

### Implementation for User Story 2

- [x] T057 [P] [US2] Create scripts/rebuild-uboot.sh for incremental U-Boot rebuild
- [x] T058 [P] [US2] Create scripts/rebuild-opensbi.sh for incremental OpenSBI rebuild
- [x] T059 [P] [US2] Create scripts/rebuild-linux.sh for incremental Linux Kernel rebuild
- [x] T060 [P] [US2] Create scripts/rebuild-buildroot.sh for incremental Buildroot rebuild
- [x] T061 [US2] Create scripts/clean.sh to clean all build artifacts
- [x] T062 [P] [US2] Create scripts/clean-u-boot.sh for U-Boot specific clean
- [x] T063 [P] [US2] Create scripts/clean-opensbi.sh for OpenSBI specific clean
- [x] T064 [P] [US2] Create scripts/clean-linux.sh for Linux Kernel specific clean
- [x] T065 [P] [US2] Create scripts/clean-buildroot.sh for Buildroot specific clean
- [x] T066 [US2] Document component-specific build and debug workflow in docs/debugging.md
- [x] T067 [US2] Add QEMU debugging options documentation (-S -s for GDB, -d guest_errors) in docs/debugging.md
- [x] T068 [US2] Document log file locations and analysis in docs/debugging.md

**Checkpoint**: At this point, individual component rebuild and debugging should be fully supported

---

## Phase 8: User Story 3 - 사용자 정의 루트 파일 시스템 통합 (Priority: P3)

**Goal**: 개발자는 Buildroot에서 생성된 루트 파일 시스템(initramfs)에 간단한 "hello_riscv" 프로그램과 같은 사용자 정의 애플리케이션 또는 테스트를 포함하기를 원합니다.

**Independent Test**: Buildroot 구성에 새 프로그램을 추가하고, Buildroot를 다시 빌드한 다음, QEMU를 부팅하여 busybox 셸에서 새 프로그램을 실행하여 테스트할 수 있습니다.

### Implementation for User Story 3

- [x] T069 [US3] Create C source code for hello_riscv in configs/buildroot/custom-packages/hello_riscv/hello_riscv.c
- [x] T070 [US3] Create Buildroot package configuration for hello_riscv in configs/buildroot/custom-packages/hello_riscv/Config.in
- [x] T071 [US3] Create Buildroot package makefile for hello_riscv in configs/buildroot/custom-packages/hello_riscv/hello_riscv.mk
- [x] T072 [US3] Update configs/buildroot/riscv64_virt_defconfig to include hello_riscv package
- [x] T072b [US3] Configure Buildroot to generate partitioned sdcard.img using genimage for reliable booting
- [x] T073 [US3] Rebuild Buildroot with scripts/rebuild-buildroot.sh
- [x] T074 [US3] Boot QEMU and verify hello_riscv program execution in busybox shell
- [x] T075 [US3] Document custom application integration process in docs/custom-rootfs.md

**Checkpoint**: At this point, custom applications should be successfully integrated into rootfs

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T076 [US2] Update README.md with Quick Start Guide and links to detailed docs
- [x] T077 [US2] Create docs/build.md with detailed build instructions for all components
- [x] T078 [US2] Create docs/qemu.md with QEMU usage instructions and networking details
- [x] T079 [US2] Create scripts/menuconfig-uboot.sh helper script
- [x] T080 [US2] Create scripts/menuconfig-linux.sh helper script
- [x] T081 [US2] Create scripts/menuconfig-buildroot.sh helper script
- [x] T082 [US2] Create Makefile for unified build interface (make all, make clean, make qemu-run)
- [x] T083 [US2] Create scripts/ci-smoke-test.sh for automated build verification
- [x] T084 [US2] Document version management and submodule update procedures in docs/version-management.md
- [x] T085 [US2] Verify all documentation is up-to-date and synchronized with implementation
- [x] T086 [US2] Perform final end-to-end verification of the complete boot chain with all features

---

## Phase 10: Source Revision Update (Maintenance)

**Purpose**: Update all Git submodules to latest stable revisions and verify build compatibility

**Goal**: 개발자는 QEMU, U-Boot, OpenSBI, Linux Kernel, Buildroot의 Git 서브모듈을 최신 안정 버전으로 업데이트하고, 업데이트 후에도 전체 부트 체인이 정상 동작하는지 검증할 수 있어야 한다.

**Independent Test**: scripts/update-sources.sh를 실행하여 모든 서브모듈이 최신 버전으로 업데이트되고, scripts/build-all.sh로 전체 빌드가 성공하며, scripts/run-qemu.sh로 부트 체인이 정상 동작하는지 확인할 수 있다.

### Implementation for Source Update

- [x] T087 [P] Create scripts/update-qemu.sh to fetch and checkout latest stable QEMU tag in sources/qemu/
- [x] T088 [P] Create scripts/update-uboot.sh to fetch and checkout latest stable U-Boot tag in sources/u-boot/
- [x] T089 [P] Create scripts/update-opensbi.sh to fetch and checkout latest stable OpenSBI tag in sources/opensbi/
- [x] T090 [P] Create scripts/update-linux.sh to fetch and checkout latest stable Linux kernel tag in sources/linux/
- [x] T091 [P] Create scripts/update-buildroot.sh to fetch and checkout latest stable Buildroot tag in sources/buildroot/
- [x] T092 Create scripts/update-sources.sh to orchestrate update of all submodules with version logging
- [x] T093 Execute scripts/update-sources.sh and record updated commit hashes in docs/version-history.md
- [x] T094 Update .gitmodules with new pinned commit hashes for each submodule
- [x] T095 Execute scripts/build-all.sh to verify all components build successfully with updated sources
- [x] T096 Execute scripts/run-qemu.sh and verify boot chain works with updated components
- [x] T097 Update docs/version-management.md with latest version information and changelog
- [ ] T098 Commit updated submodule references and documentation

**Checkpoint**: At this point, all source components should be updated to latest stable versions with verified build and boot

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 4 (Phase 3)**: Depends on Foundational phase - QEMU build environment setup
- **User Story 5 (Phase 4)**: Depends on User Story 4 - QEMU source download and configuration
- **User Story 6 (Phase 5)**: Depends on User Story 5 - QEMU build and installation
- **User Story 1 (Phase 6)**: Depends on User Story 6 - Complete boot chain with built QEMU
- **User Story 2 (Phase 7)**: Depends on User Story 1 - Component-specific rebuild capabilities
- **User Story 3 (Phase 8)**: Depends on User Story 1 - Custom rootfs integration
- **Polish (Phase 9)**: Depends on all desired user stories being complete
- **Source Update (Phase 10)**: Depends on Phase 9 - Can be run periodically for maintenance

### User Story Dependencies

- **User Story 4 (P1)**: QEMU build environment - Must complete first (foundation for QEMU build)
- **User Story 5 (P1)**: QEMU source setup - Depends on US4
- **User Story 6 (P1)**: QEMU build - Depends on US5
- **User Story 1 (P1)**: Complete boot chain - Depends on US6 (needs built QEMU)
- **User Story 2 (P2)**: Component debugging - Depends on US1 (needs working boot chain)
- **User Story 3 (P3)**: Custom rootfs - Depends on US1 (needs working boot chain)

### Within Each User Story

- Environment setup before source download
- Source download and configuration before build
- Build before installation
- Individual component builds can proceed in parallel (marked with [P])
- Integration tasks depend on all component builds completing
- Documentation tasks can proceed in parallel with implementation

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] (submodule additions) can run in parallel
- Within User Story 1: U-Boot, OpenSBI, Linux, and Buildroot component builds can run in parallel
- Within User Story 2: All component-specific scripts can be created in parallel
- Within Phase 9: All documentation tasks can run in parallel

---

## Parallel Example: User Story 1 Component Builds

```bash
# Launch all component configuration tasks together:
Task: "Create configs/u-boot/riscv64_qemu_virt_defconfig"
Task: "Create configs/opensbi/platform/qemu_virt.config"
Task: "Create configs/linux/riscv_qemu_virt_defconfig"
Task: "Create configs/buildroot/riscv64_virt_defconfig"

# Launch all component builds together (after configs are ready):
Task: "Execute scripts/build-u-boot.sh"
Task: "Execute scripts/build-opensbi.sh"
Task: "Execute scripts/build-linux.sh"
Task: "Execute scripts/build-buildroot.sh"
```

---

## Implementation Strategy

### MVP First (User Stories 4, 5, 6, and 1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 4 (QEMU build environment)
4. Complete Phase 4: User Story 5 (QEMU source setup)
5. Complete Phase 5: User Story 6 (QEMU build and install)
6. Complete Phase 6: User Story 1 (Complete boot chain)
7. **STOP and VALIDATE**: Test complete boot chain independently
8. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 4 → QEMU environment ready
3. Add User Story 5 → QEMU source ready
4. Add User Story 6 → QEMU built and installed
5. Add User Story 1 → Complete boot chain working (MVP!)
6. Add User Story 2 → Component debugging enabled
7. Add User Story 3 → Custom rootfs integration
8. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Stories 4, 5, 6 (QEMU build chain)
   - Developer B: User Story 1 U-Boot + OpenSBI components
   - Developer C: User Story 1 Linux + Buildroot components
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- QEMU must be built from source before boot chain integration
- All build logs should be saved to build/logs/ for debugging
- Follow constitution principle XII for build automation and log management
