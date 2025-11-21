# RISC-V QEMU 부트 체인 구현 계획

## 1. 개요(Overview)

*   **목표**: Ubuntu 24.04 headless 서버 환경에서 RISC-V QEMU virt 머신을 위한 U-Boot SPL → OpenSBI → U-Boot → Linux Kernel → Buildroot initramfs 부트 체인을 성공적으로 구축하고 검증한다.
*   **입력(선행 조건)**: RISC-V QEMU Virt 부트 체인 프로젝트 헌장 (Constitution), 001-riscv-boot-verify/spec.md
*   **주요 산출물**: `plan.md` (본 문서), `data-model.md`, `research.md`, `/contracts/*`, 빌드된 부트 이미지들, 자동화 스크립트, README 및 상세 문서

## 2. 개발 환경 및 전제 조건

### 2.1. OS 및 기본 패키지

*   **OS**: Ubuntu 24.04 LTS (headless)
*   **필요 패키지**:
    *   `build-essential`: 기본적인 빌드 도구 (gcc, g++, make 등)
    *   `git`: 버전 관리 시스템
    *   `qemu-system-misc`: RISC-V QEMU 에뮬레이터 (추후 소스 빌드 QEMU로 대체 예정)
    *   `libncurses-dev`, `flex`, `bison`, `libssl-dev`, `libelf-dev`, `python3`, `python3-pip`, `device-tree-compiler`, `cpio`, `bc`: 커널 및 U-Boot 빌드에 필요한 추가 패키지
    *   `libglib2.0-dev`, `libpixman-1-dev`, `libfdt-dev`, `zlib1g-dev`, `ninja-build`, `pkg-config`: QEMU 소스 빌드에 필요한 추가 패키지
    *   `riscv64-linux-gnu-gcc`, `riscv64-linux-gnu-objdump`, `gdb-multiarch`: RISC-V 크로스 툴체인 (Ubuntu 패키지)

### 2.2. RISC-V 크로스 툴체인 및 QEMU 선택 전략

*   **RISC-V 크로스 툴체인 우선 전략**: Ubuntu 24.04 저장소에서 제공하는 `riscv64-linux-gnu-` 계열의 크로스 컴파일 도구를 우선적으로 사용한다. (`apt install g++-riscv64-linux-gnu`)
*   **RISC-V 크로스 툴체인 대체 전략**: 특정 버전 또는 기능이 필요한 경우, 직접 빌드하거나 pre-built 툴체인(`build/toolchain/` 아래)을 사용하는 방안을 고려하며, Plan에 교체할 수 있는 여지를 남긴다. `scripts/` 디렉토리에 툴체인 경로를 설정하는 공통 스크립트를 생성하여 관리한다.
*   **QEMU 선택 전략**: QEMU는 `sources/qemu`에 소스 코드를 다운로드하여 빌드하고, `build/toolchain/qemu/bin`에 설치하여 사용한다. 이는 시스템에 설치된 QEMU 버전과의 독립성을 보장하고, 필요한 경우 특정 QEMU 버전을 사용하거나 패치를 적용하기 위함이다.

### 2.3. Git 전략 요약

*   **저장소 구조**: 최상위 저장소는 Git submodule 기능을 활용하여 `sources/qemu`, `sources/u-boot`, `sources/opensbi`, `sources/linux`, `sources/buildroot` 등 각 컴포넌트 소스를 관리한다.
*   **커밋 원칙**:
    *   **Atomic Commit**: 하나의 커밋은 하나의 논리적 변경만을 포함한다.
    *   **50/72 규칙**: 커밋 메시지 요약은 50자 이내, 본문은 72자 기준으로 줄바꿈한다.
    *   **Upstream 스타일**: 각 submodule 프로젝트의 upstream 커밋 스타일(예: Subsystem prefix, Signed-off-by)을 최대한 따른다.

## 3. 단계별 구현 계획(Phased Implementation Plan)

### Phase 0: 프로젝트 스캐폴딩 및 환경 점검

*   **Phase 목표**: 프로젝트의 기본 구조를 설정하고, 개발 환경의 필수 도구들이 정상 작동하는지 확인한다.
*   **선행 조건**: 없음
*   **세부 작업**:
    *   프로젝트 루트 디렉토리(`risc-v`) 초기 Git 저장소 구성 (`.git/`, `.gitignore`, `README.md`, `LICENSE` 파일 생성) (1시간)
    *   `README.md`에 프로젝트 요약, 기본 환경 요구사항, 빌드/실행 지침의 개요 추가 (1시간)
    *   Ubuntu 24.04 기본 패키지(`build-essential`, `git`, `qemu-system-misc`, `g++-riscv64-linux-gnu`, `libglib2.0-dev`, `libpixman-1-dev`, `libfdt-dev`, `zlib1g-dev`, `ninja-build`, `pkg-config` 등) 설치 스크립트(`scripts/setup-env.sh`) 작성 및 실행 (2시간)
    *   `qemu-system-riscv64 --version` 명령어로 시스템 QEMU 버전 확인 및 정상 설치 검증 (30분)
    *   "hello world" 수준의 QEMU 실행 smoke test (예: 기본 QEMU 펌웨어로 부팅 시도, `qemu-system-riscv64 -machine virt -cpu rv64 -m 1G -nographic`) (1시간)
*   **산출물**: `<repo_root>/.git/`, `README.md`, `LICENSE`, `.gitignore`, `scripts/setup-env.sh`, QEMU 실행 확인 로그
*   **완료 기준**: 기본 Git 저장소 구성 완료 및 QEMU가 최소한의 명령으로 오류 없이 실행됨을 확인

### Phase 1: 저장소 레이아웃 및 submodule 구성

*   **Phase 목표**: 프로젝트의 디렉토리 구조를 확립하고, RISC-V 부트 체인 컴포넌트들을 Git submodule로 통합한다.
*   **선행 조건**: Phase 0 완료
*   **세부 작업**:
    *   프로젝트 루트에 `sources/`, `configs/`, `scripts/`, `docs/`, `build/` 디렉터리 생성 (30분)
    *   QEMU, U-Boot, OpenSBI, Linux Kernel, Buildroot 각각을 `sources/` 하위에 Git submodule로 추가 (각 1시간)
        *   `git submodule add <QEMU_repo_URL> sources/qemu`
        *   `git submodule add <U-Boot_repo_URL> sources/u-boot`
        *   `git submodule add <OpenSBI_repo_URL> sources/opensbi`
        *   `git submodule add <Linux_Kernel_repo_URL> sources/linux`
        *   `git submodule add <Buildroot_repo_URL> sources/buildroot`
    *   각 submodule의 초기 버전(특정 안정화된 커밋 해시)을 선정하고 `git submodule update --init --recursive` 명령으로 고정 (2시간)
    *   `sources/<component>` 내 소스 변경이 필요할 경우의 워크플로우 정의 (예: 임시 패치 적용, 포크 후 개발, upstream 기여) (1시간)
*   **산출물**: `<repo_root>/sources/*`, `<repo_root>/configs/`, `<repo_root>/scripts/`, `<repo_root>/docs/`, `<repo_root>/build/` 디렉터리, `.gitmodules` 파일, submodule 초기화 완료
*   **완료 기준**: 모든 핵심 컴포넌트가 submodule로 추가되고 특정 커밋 해시에 고정됨을 확인

### Phase 2: RISC-V 크로스 툴체인 설치 및 검증

*   **Phase 목표**: RISC-V 크로스 툴체인을 설치하고, 정상적으로 작동하는지 검증한다.
*   **선행 조건**: Phase 1 완료
*   **세부 작업**:
    *   Ubuntu 패키지 기반 툴체인 설치 확인 및 필요한 경우 `scripts/setup-env.sh` 업데이트 (1시간)
    *   `scripts/toolchain-env.sh` 스크립트를 생성하여 `PATH` 환경 변수 등 툴체인 관련 설정을 공통으로 관리 (1시간)
    *   `riscv64-linux-gnu-gcc -v`, `riscv64-linux-gnu-objdump --version`, `gdb-multiarch --version` 명령어로 설치된 툴체인 버전 확인 및 출력 기록 (30분)
    *   간단한 "Hello World" C 프로그램을 작성하고, `riscv64-linux-gnu-gcc`를 사용하여 크로스 컴파일 및 결과물(`a.out`) 생성 (1시간 30분)
    *   QEMU 환경에서 컴파일된 "Hello World" 실행 테스트 (30분)
*   **산출물**: `scripts/toolchain-env.sh`, 툴체인 버전 확인 로그, 크로스 컴파일된 "Hello World" 바이너리 및 실행 확인
*   **완료 기준**: RISC-V 크로스 툴체인이 성공적으로 설치 및 환경 설정되고, 간단한 프로그램 크로스 컴파일 및 QEMU 실행 검증 완료

### Phase 3: 각 컴포넌트별 단독 빌드 플로우 확립

#### 공통 패턴

*   **설정 파일**: `configs/` 디렉토리에 각 컴포넌트의 defconfig 또는 커스터마이징된 설정 파일을 관리한다.
*   **빌드 스크립트**: `scripts/build-<component>.sh` 형태로 각 컴포넌트의 빌드 절차를 자동화한다.
*   **빌드 디렉토리**: `build/<component>/` 경로에 out-of-tree 빌드를 수행하여 소스 트리를 깨끗하게 유지한다.
*   **로그 관리**: 빌드 로그는 `build/logs/<component>_build.log` 형태로 저장한다.

#### 3.1. U-Boot SPL Phase

*   **Phase 목표**: U-Boot SPL (Secondary Program Loader) 및 U-Boot 본체 빌드 플로우를 확립한다.
*   **선행 조건**: Phase 2 완료
*   **세부 작업**:
    *   `sources/u-boot` submodule 초기화 및 `riscv64_qemu_virt_defconfig` 선정 (1시간)
    *   `configs/u-boot/riscv64_qemu_virt_defconfig` 파일을 생성 및 필요시 커스터마이즈 (1시간)
    *   `scripts/build-u-boot.sh` 스크립트 작성:
        *   `make O=../../build/u-boot <defconfig_name>`
        *   `make O=../../build/u-boot ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- all`
        *   빌드 로그를 `build/logs/u-boot_build.log`에 저장 (2시간)
    *   빌드된 `u-boot-spl.bin` 및 `u-boot.itb` (또는 `u-boot.bin`) 파일이 `build/u-boot/`에 생성되는지 확인 (30분)
*   **산출물**: `configs/u-boot/riscv64_qemu_virt_defconfig`, `scripts/build-u-boot.sh`, `build/u-boot/u-boot-spl.bin`, `build/u-boot/u-boot.itb`, `build/logs/u-boot_build.log`
*   **완료 기준**: U-Boot SPL 및 U-Boot 본체가 성공적으로 빌드되고, 지정된 위치에 산출물 생성 확인

#### 3.2. OpenSBI Phase

*   **Phase 목표**: OpenSBI (RISC-V Supervisor Binary Interface) 빌드 플로우를 확립한다.
*   **선행 조건**: Phase 2 완료
*   **세부 작업**:
    *   `sources/opensbi` submodule 초기화 및 QEMU virt 플랫폼 설정 (1시간)
    *   `configs/opensbi/platform/qemu_virt.config` 파일 생성 및 필요시 커스터마이즈 (예: `FW_DYNAMIC` 활성화) (1시간)
    *   `scripts/build-opensbi.sh` 스크립트 작성:
        *   `make O=../../build/opensbi PLATFORM=generic ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- FW_PAYLOAD_PATH=... all` (U-Boot와 연동을 위해 `FW_PAYLOAD_PATH`는 초기에는 비워두거나 임시로 설정)
        *   빌드 로그를 `build/logs/opensbi_build.log`에 저장 (2시간)
    *   빌드된 `fw_payload.bin` (또는 `fw_dynamic.bin`) 파일이 `build/opensbi/`에 생성되는지 확인 (30분)
*   **산출물**: `configs/opensbi/platform/qemu_virt.config`, `scripts/build-opensbi.sh`, `build/opensbi/fw_payload.bin`, `build/logs/opensbi_build.log`
*   **완료 기준**: OpenSBI가 성공적으로 빌드되고, 지정된 위치에 산출물 생성 확인

#### 3.3. Linux Kernel Phase

*   **Phase 목표**: Linux Kernel 빌드 플로우를 확립한다.
*   **선행 조건**: Phase 2 완료
*   **세부 작업**:
    *   `sources/linux` submodule 초기화 및 `riscv_defconfig` 선정 (1시간)
    *   `configs/linux/riscv_qemu_virt_defconfig` 파일을 생성 및 QEMU virt에 필요한 옵션 추가:
        *   `CONFIG_INITRAMFS_SOURCE`, 콘솔 (`CONFIG_SERIAL_8250_CONSOLE=y`), earlycon 등 (2시간)
    *   `scripts/build-linux.sh` 스크립트 작성:
        *   `make O=../../build/linux <defconfig_name>`
        *   `make O=../../build/linux ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- vmlinux dtbs`
        *   빌드 로그를 `build/logs/linux_build.log`에 저장 (2시간)
    *   빌드된 `vmlinux`, `dtbs/*.dtb` 파일이 `build/linux/`에 생성되는지 확인 (30분)
*   **산출물**: `configs/linux/riscv_qemu_virt_defconfig`, `scripts/build-linux.sh`, `build/linux/vmlinux`, `build/linux/arch/riscv/boot/dts/qemu/virt.dtb`, `build/logs/linux_build.log`
*   **완료 기준**: Linux Kernel이 성공적으로 빌드되고, 지정된 위치에 vmlinux 및 DTB 산출물 생성 확인

#### 3.4. Buildroot Phase

*   **Phase 목표**: Buildroot를 사용하여 BusyBox 기반의 initramfs를 생성하는 빌드 플로우를 확립한다.
*   **선행 조건**: Phase 2 완료
*   **세부 작업**:
    *   `sources/buildroot` submodule 초기화 및 `riscv64_virt_defconfig` 선정 (1시간)
    *   `configs/buildroot/riscv64_virt_defconfig` 파일을 생성 및 필요시 커스터마이즈 (예: BusyBox 설정, 네트워크 유틸리티 추가) (1시간)
    *   `scripts/build-buildroot.sh` 스크립트 작성:
        *   `make O=../../build/buildroot <defconfig_name>`
        *   `make O=../../build/buildroot ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu-`
        *   빌드 로그를 `build/logs/buildroot_build.log`에 저장 (2시간)
    *   빌드된 `rootfs.cpio` (또는 `rootfs.ext2`) 파일이 `build/buildroot/images/`에 생성되고, 이를 `build/images/`로 복사하는 규칙 정의 (1시간)
*   **산출물**: `configs/buildroot/riscv64_virt_defconfig`, `scripts/build-buildroot.sh`, `build/buildroot/images/rootfs.cpio`, `build/images/rootfs.cpio`, `build/logs/buildroot_build.log`
*   **완료 기준**: Buildroot를 통해 BusyBox 기반 rootfs가 성공적으로 생성되고, 지정된 위치에 산출물 생성 및 `build/images/`로 복사 확인


#### 3.5. QEMU 소스 빌드 및 설치 Phase

*   **Phase 목표**: QEMU 소스 코드를 다운로드하고, 빌드 및 설치하여 프로젝트 내에서 사용할 수 있도록 확립한다.
*   **선행 조건**: Phase 2 완료 (RISC-V 크로스 툴체인 설치 및 검증), Phase 1 완료 (소스 저장소 레이아웃 구성)
*   **세부 작업**:
    *   `sources/qemu` submodule 초기화 및 특정 안정화된 QEMU 버전(커밋 해시) 선정 (1시간)
    *   `scripts/get-qemu-source.sh` 스크립트 작성: QEMU 소스 다운로드 및 특정 버전 고정 (1시간)
    *   `configs/qemu/qemu_riscv_virt.config` 파일 생성 (필요시 configure 옵션 관리용) (30분)
    *   `scripts/configure-qemu.sh` 스크립트 작성:
        *   `mkdir -p build/qemu`
        *   `../sources/qemu/configure --target-list=riscv64-softmmu --enable-virtfs --prefix=$REPO_ROOT/build/toolchain/qemu` (2시간)
    *   `scripts/build-qemu.sh` 스크립트 작성:
        *   `make -j$(nproc)` (out-of-tree 빌드: `build/qemu` 디렉토리에서 실행)
        *   빌드 로그를 `build/logs/qemu_build.log`에 저장 (2시간)
    *   `scripts/install-qemu.sh` 스크립트 작성: `make install` (QEMU 바이너리를 `build/toolchain/qemu/bin`에 설치) (1시간)
    *   `build/toolchain/qemu/bin/qemu-system-riscv64 --version` 명령어로 설치된 QEMU 버전 확인 및 정상 설치 검증 (30분)
*   **산출물**: `sources/qemu` submodule 초기화, `scripts/get-qemu-source.sh`, `scripts/configure-qemu.sh`, `scripts/build-qemu.sh`, `scripts/install-qemu.sh`, `build/qemu/` (빌드 디렉토리), `build/toolchain/qemu/bin/qemu-system-riscv64` (설치된 QEMU 바이너리), `build/logs/qemu_build.log`
*   **완료 기준**: QEMU 소스 다운로드, 설정, 빌드 및 설치가 성공적으로 완료되고, 프로젝트에서 빌드된 QEMU 바이너리가 정상 작동함을 확인.

### Phase 4: 부트 체인 통합 및 QEMU 실행 플로우

*   **Phase 목표**: 모든 컴포넌트(OpenSBI, U-Boot, Kernel, initramfs)를 통합하여 프로젝트에서 빌드된 QEMU에서 전체 부트 체인을 실행한다.
*   **선행 조건**: Phase 3 완료 (모든 개별 컴포넌트 빌드 완료), Phase 3.5 완료 (QEMU 소스 빌드 및 설치 완료)
*   **세부 작업**:
    *   `build/images/` 디렉토리에 QEMU가 참조할 최종 이미지 파일들을 모으는 규칙 확립 (예: `cp build/opensbi/fw_payload.bin build/u-boot/u-boot.itb build/linux/vmlinux build/linux/arch/riscv/boot/dts/qemu/virt.dtb build/buildroot/images/rootfs.cpio build/images/`) (1시간)
    *   `scripts/run-qemu.sh` 스크립트 작성:
        *   빌드된 QEMU 실행 경로 설정 (예: `QEMU_BIN=$REPO_ROOT/build/toolchain/qemu/bin/qemu-system-riscv64`) (30분)
        *   기본 QEMU 옵션 (`-machine virt -cpu rv64 -smp 4 -m 1G -nographic`) 설정 (1시간)
        *   OpenSBI (`-bios build/images/fw_payload.bin`) 연결 (1시간)
        *   Kernel (`-kernel build/images/vmlinux`), DTB (`-dtb build/images/virt.dtb`), U-Boot (`-initrd build/images/rootfs.cpio`) 연결 (이때 OpenSBI → U-Boot → Kernel → initramfs 순서의 로딩 방식 고려) (2시간)
        *   추가 QEMU 옵션 (`-append "console=ttyS0 earlycon=sbi"`) (30분)
    *   `scripts/run-qemu.sh` 실행 및 "end-to-end 부트 성공" 기준 검증:
        *   BusyBox `sh` 프롬프트 (`# ` 또는 커스터마이즈된 `PS1`)에 도달하는지 확인 (1시간)
        *   부팅 후 `cat /proc/cpuinfo`, `dmesg`, `mount` 명령을 통해 시스템 정보 확인 (30분)
*   **산출물**: `build/images/*` (통합된 부트 이미지들), `scripts/run-qemu.sh`, QEMU 부팅 성공 확인 스크린샷 또는 로그
*   **완료 기준**: `scripts/run-qemu.sh`를 통해 프로젝트에서 빌드된 QEMU가 성공적으로 부팅되어 BusyBox 쉘 프롬프트에 도달하고, 기본 시스템 정보를 확인할 수 있음

### Phase 5: 디버깅 및 개발 워크플로우

*   **Phase 목표**: 효율적인 디버깅 환경과 개발 워크플로우를 구축하여 문제 해결 능력을 향상시킨다.
*   **선행 조건**: Phase 4 완료
*   **세부 작업**:
    *   단계별 부트 실패 시 확인할 주요 로그 포인트 정의:
        *   U-Boot SPL: UART 로그 (QEMU `-serial mon:stdio` 활용) (1시간)
        *   OpenSBI: 초기 메시지 및 SBI 호출 로그 (1시간)
        *   Kernel: `earlycon`, `boot log` (dmesg) 확인 (1시간)
    *   QEMU 디버깅 옵션(`-S -s` for GDB, `-d guest_errors`, `-d int`, `-D qemu.log`)을 활용한 디버깅 플로우 문서화 (`docs/debugging.md`) (2시간)
    *   개발자가 자주 수행할 명령 시나리오 정의 및 스크립트화:
        *   `scripts/build-u-boot.sh` (특정 컴포넌트만 재빌드) (30분)
        *   `scripts/clean.sh` (클린 빌드) (30분)
        *   `make menuconfig` (각 컴포넌트의 설정 메뉴 진입)를 위한 헬퍼 스크립트 (30분)
*   **산출물**: `docs/debugging.md`, `scripts/clean.sh`, `scripts/menuconfig-u-boot.sh` 등 헬퍼 스크립트
*   **완료 기준**: 효과적인 디버깅 가이드라인이 문서화되고, 주요 개발 작업(재빌드, 클린, 설정 변경)을 위한 스크립트가 준비됨

### Phase 6: 문서화 및 자동화(빌드/부트 스크립트)

*   **Phase 목표**: 프로젝트의 사용성 및 유지보수성을 높이기 위한 문서화와 빌드/부트 프로세스 자동화를 구현한다.
*   **선행 조건**: Phase 5 완료
*   **세부 작업**:
    *   `README.md`에 "Quick Start Guide" 섹션 구조 정의:
        *   "의존성 설치 → submodule 초기화 → 전체 빌드 → QEMU 실행" 절차 명시 (2시간)
    *   `docs/` 디렉토리 내에 `build.md`, `qemu.md`, `debugging.md` 등의 상세 문서 구조 계획 및 주요 내용 작성 (각 2시간)
    *   `Makefile` 또는 `scripts/` 디렉토리 내 쉘 스크립트를 활용하여 전체 빌드, 클린, QEMU 실행 등의 자동화(`make all`, `make clean`, `make qemu-run`) 구현 (3시간)
    *   (선택) CI 도입을 고려한 `scripts/ci-smoke-test.sh` 스크립트 정의 (최소 빌드 및 QEMU 부팅 여부 체크) (2시간)
*   **산출물**: 업데이트된 `README.md`, `docs/build.md`, `docs/qemu.md`, `docs/debugging.md`, `Makefile` 또는 자동화 스크립트, (선택) `scripts/ci-smoke-test.sh`
*   **완료 기준**: 프로젝트를 처음 접하는 개발자가 쉽게 시작할 수 있도록 Quick Start 가이드가 완성되고, 주요 작업 자동화 및 상세 문서화가 완료됨

## 4. 디렉터리 구조와 Plan의 연결

각 Phase의 주요 작업이 영향을 미치는 디렉토리/파일 목록은 다음과 같다:

*   **Phase 0**: `<repo_root>/.git/`, `README.md`, `LICENSE`, `.gitignore`, `scripts/setup-env.sh`
*   **Phase 1**: `<repo_root>/sources/qemu`, `<repo_root>/sources/u-boot`, `<repo_root>/sources/opensbi`, `<repo_root>/sources/linux`, `<repo_root>/sources/buildroot`, `configs/`, `scripts/`, `docs/`, `build/`, `.gitmodules`
*   **Phase 2**: `scripts/toolchain-env.sh`, `build/toolchain/` (선택적)
*   **Phase 3**:
    *   `build/u-boot/`, `build/opensbi/`, `build/linux/`, `build/buildroot/` (각 컴포넌트의 빌드 디렉토리)
    *   `build/logs/` (각 컴포넌트의 빌드 로그)
    *   `configs/u-boot/`, `configs/opensbi/`, `configs/linux/`, `configs/buildroot/` (각 컴포넌트의 설정 파일)
    *   `scripts/build-u-boot.sh`, `scripts/build-opensbi.sh`, `scripts/build-linux.sh`, `scripts/build-buildroot.sh`
*   **Phase 3.5**: `sources/qemu`, `build/qemu/`, `build/toolchain/qemu/`, `configs/qemu/`, `scripts/get-qemu-source.sh`, `scripts/configure-qemu.sh`, `scripts/build-qemu.sh`, `scripts/install-qemu.sh`, `build/logs/qemu_build.log`
*   **Phase 4**: `build/images/` (통합된 부트 이미지들), `scripts/run-qemu.sh`
*   **Phase 5**: `docs/debugging.md`, `scripts/clean.sh`, `scripts/menuconfig-*.sh`
*   **Phase 6**: `README.md`, `docs/build.md`, `docs/qemu.md`, `docs/debugging.md`, `Makefile`, `scripts/ci-smoke-test.sh` (선택적)

## 5. 향후 확장 및 백로그

*   **추가 하드웨어 타깃 지원**: QEMU 외부의 실제 RISC-V 보드 (예: VisionFive 2, Nezha) 지원 추가
*   **펌웨어 업데이트 및 보안**: OTA(Over-The-Air) 업데이트 메커니즘 통합, Secure Boot 구현 검토
*   **성능 최적화**: 부트 시간 단축, 커널/부트 체인 컴포넌트별 성능 프로파일링
*   **고급 디버깅 기능**: GDB 원격 디버깅, JTAG/SWD 디버거 통합
*   **자동화된 테스트**: CI/CD 파이프라인에 통합된 자동화된 부트 체인 테스트 슈트 구축
*   **문서화 강화**: 상세한 아키텍처 다이어그램, 코드 흐름 분석 문서 추가