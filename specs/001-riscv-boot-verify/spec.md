# 기능 사양: RISC-V QEMU 부트 체인 검증

**기능 브랜치**: `001-riscv-boot-verify`  
**생성일**: 2025년 11월 20일  
**상태**: 초안  
**입력**: 사용자 설명: "Ubuntu 24.04 headless 서버에서 RISC-V QEMU virt 머신을 대상으로 다음 부트 체인을 end-to-end로 검증하는 프로젝트의 스펙을 작성해 주세요. 부트 체인: - QEMU riscv64 virt 머신 - U-Boot SPL - OpenSBI (firmware) - U-Boot (2nd stage bootloader) - Linux Kernel (riscv64) - Buildroot 기반 initramfs(rootfs) Spec은 아래 섹션을 포함해 주세요. 한국어로 작성해 주세요. 1) 프로젝트 개요 - 왜 이 부트 체인을 구성하려는지 (학습/PoC/향후 양산 SoC 준비 등) - 최종적으로 데모하고 싶은 시나리오 (예: QEMU 콘솔에서 busybox 셸까지 부팅) 2) 범위(Scope) - 포함: RISC-V 크로스 툴체인 설치, 각 컴포넌트 소스 다운로드, 설정, 빌드, QEMU 실행 스크립트 - 제외: 실제 보드 Bring-up, 복잡한 네트워크/스토리지, 보안 부팅, SMP 최적화 등 (필요시 향후 확장) 3) 사용자/개발자 시나리오 - "개발자" 관점: git clone → 한두 개의 스크립트를 실행하면 QEMU가 부팅되는 흐름 - "디버깅 사용자" 관점: 각 스테이지별로 로그를 확인하고, 특정 컴포넌트만 다시 빌드/실행하는 흐름 4) 기능 요구사항 - 단일 명령 또는 짧은 스크립트로 전체 빌드 및 QEMU 부팅이 가능해야 한다. - 각 컴포넌트(u-boot spl, opensbi, u-boot, linux, buildroot) 빌드를 개별적으로 수행할 수 있어야 한다. - QEMU 콘솔에서 /proc/cpuinfo, dmesg를 확인할 수 있어야 한다. - (선택) rootfs에 간단한 테스트 프로그램(예: "hello_riscv")을 포함하여 실행 가능해야 한다. 5) 비기능 요구사항 - 빌드 재현성: clean 상태에서 문서에 명시된 버전과 명령으로 동일한 결과가 나와야 한다. - 성능: 일반적인 개발용 서버(예: 4코어, 8GB RAM)에서 빌드 시간이 합리적인 수준이어야 한다(대략적인 목표 포함). - 관측 가능성: 각 단계별 아티팩트 경로, 로그 위치(예: build/artifacts/... )가 일관되게 정의될 것. 6) 기술 제약조건 - OS: Ubuntu 24.04 LTS(headless) - 아키텍처: riscv64 (RV64GC), QEMU virt 머신 - 크로스 툴체인 종류 및 최소 버전 (예: riscv64-linux-gnu-gcc 13 이상) - 기본 메모리/스토리지 설정 (QEMU -m, -drive 옵션 등 큰 틀의 제약) 7) 성공/완료 기준(Acceptance Criteria) - 문서에 정의된 단일 명령으로 QEMU가 부팅되어, 지정된 프롬프트(예: "riscv-qemu#")까지 도달한다. - spec, plan, tasks, 스크립트가 최신 상태로 동기화되어 있고, README에 전체 흐름이 정리되어 있다. - (선택) CI 또는 간단한 스크립트로 “빌드 + QEMU 부팅 smoke test”를 자동화할 수 있다. 8) 오픈 이슈/질문 목록 - 예: OpenSBI/U-Boot 버전 선택 기준 - Linux LTS 버전 선택 및 향후 업데이트 정책 - Buildroot로 할지, 나중에 Yocto로 확장할지 등"

## 사용자 시나리오 및 테스트 *(필수)*

### 사용자 스토리 1 - RISC-V QEMU 부트 체인 엔드투엔드 검증 (우선순위: P1)

개발자 또는 엔지니어는 Ubuntu 24.04 헤드리스 서버의 QEMU 가상 머신에서
완전한 RISC-V 부트 체인을 신속하게 설정하고 검증하기를 원합니다. 이들은
리포지토리를 클론하고 단일 스크립트를 실행하여 필요한 모든 구성 요소를 빌드하고
기능하는 busybox 셸로 부팅되기를 기대합니다.

**이 우선순위인 이유**: 이는 핵심 기능이며, 모든 부트 구성 요소의 성공적인 통합을
시연하여 즉각적인 가치를 제공합니다.

**독립 테스트**: 주요 빌드/부트 스크립트를 실행하고 QEMU 콘솔에서 예상되는 busybox
프롬프트를 관찰하여 완전히 테스트할 수 있습니다.

**수락 시나리오**:

1.  **조건** 필요한 전제 조건이 설치된 깨끗한 Ubuntu 24.04 서버에서,
    **사용자가** 주요 빌드 및 부트 스크립트를 실행하면, **QEMU 가상 머신이** 시작되고
    busybox 셸로 성공적으로 부팅되어 "riscv-qemu#" 프롬프트가 표시됩니다.
2.  **조건** QEMU 가상 머신이 busybox 셸로 부팅된 후, **사용자가** `ls /proc/cpuinfo`
    및 `dmesg`를 입력하면, **명령이** 성공적으로 실행되어 CPU 정보와 커널 메시지를
    표시합니다.

---

### 사용자 스토리 2 - 개별 구성 요소 개발 및 디버깅 (우선순위: P2)

개발자는 RISC-V 부트 체인(예: U-Boot, Linux Kernel)의 특정 구성 요소를 수정하거나
디버깅해야 합니다. 이들은 전체 부트 체인을 다시 컴파일하지 않고도 개별 구성 요소를
다시 빌드하고 테스트할 수 있는 기능과 부트 프로세스의 각 단계에 대한 로그에
쉽게 액세스할 수 있는 기능이 필요합니다.

**이 우선순위인 이유**: 복잡한 임베디드 시스템의 반복적인 개발 및 효율적인 디버깅을
가능하게 하며, 구성 요소별 작업에 중요합니다.

**독립 테스트**: 특정 구성 요소의 소스를 수정하고, 전용 스크립트를 사용하여 해당
구성 요소만 다시 빌드한 다음, QEMU를 부팅하여 변경 사항 및 로그를 관찰하여
테스트할 수 있습니다.

**수락 시나리오**:

1.  **조건** U-Boot 소스 코드에 변경 사항이 적용된 후, **사용자가** U-Boot 특정 빌드
    스크립트를 실행하면, **U-Boot만** 다시 빌드되고 새 바이너리가 QEMU 부팅을 위해
    준비됩니다.
2.  **조건** QEMU 가상 머신이 부팅 중일 때, **사용자가** 미리 정의된 로그 경로를 확인하면,
    **U-Boot SPL, OpenSBI, U-Boot 및 Linux Kernel** 단계에 대한 로그를 찾아
    검사할 수 있습니다.

---

### 사용자 스토리 3 - 사용자 정의 루트 파일 시스템 통합 (우선순위: P3)

개발자는 Buildroot에서 생성된 루트 파일 시스템(initramfs)에 간단한 "hello_riscv"
프로그램과 같은 사용자 정의 애플리케이션 또는 테스트를 포함하기를 원합니다. 이들은
자신의 프로그램을 통합하고 검증하기 위한 명확한 프로세스가 필요합니다.

**이 우선순위인 이유**: 초기 부팅 검증에는 필수적이지 않지만, 이는 실제 임베디드
개발에 대한 일반적인 요구 사항이며 프로젝트의 유용성을 확장합니다.

**독립 테스트**: Buildroot 구성에 새 프로그램을 추가하고, Buildroot를 다시 빌드한 다음,
QEMU를 부팅하여 busybox 셸에서 새 프로그램을 실행하여 테스트할 수 있습니다.

**수락 시나리오**:

1.  **조건** 간단한 "hello_riscv" 테스트 프로그램이 Buildroot 구성에 추가된 후,
    **Buildroot가** 다시 빌드되고 QEMU가 부팅되면, **사용자는** busybox 셸에서
    "hello_riscv"를 실행하고 출력을 관찰할 수 있습니다.

---

### 사용자 스토리 4 - QEMU 소스 빌드 환경 설정 (우선순위: P1)

개발자는 QEMU 소스 빌드에 필요한 모든 의존성 패키지를 쉽게 설치하고, 빌드 환경을 설정할 수 있어야 한다.

**Why this priority**: QEMU를 소스로 빌드하기 위한 가장 기본적인 선행 조건이다. 이 단계가 없으면 이후 모든 작업이 불가능하다.

**Independent Test**: `scripts/setup-env.sh` 스크립트를 실행하여 필요한 패키지가 모두 설치되고, QEMU 빌드에 필요한 환경 변수가 설정되는지 확인할 수 있다.

**Acceptance Scenarios**:

1.  **Given** Ubuntu 24.04 headless 서버 환경에서, **When** `scripts/setup-env.sh`를 실행하면, **Then** QEMU 빌드에 필요한 모든 기본 패키지(예: `libglib2.0-dev`, `libpixman-1-dev`, `libfdt-dev`, `zlib1g-dev`, `ninja-build` 등)가 성공적으로 설치된다.
2.  **Given** 모든 의존성 패키지가 설치된 상태에서, **When** `scripts/toolchain-env.sh`를 실행하면, **Then** QEMU 빌드 및 실행에 필요한 환경 변수(예: `PATH`에 QEMU 빌드 디렉토리 추가)가 올바르게 설정된다.

---

### 사용자 스토리 5 - QEMU 소스 다운로드 및 초기 설정 (우선순위: P1)

개발자는 프로젝트 저장소 내에 QEMU 소스 코드를 쉽게 다운로드하고, 초기 설정(configure)을 수행할 수 있어야 한다.

**Why this priority**: 실제 QEMU 빌드를 시작하기 위한 필수 단계이며, 소스 기반 빌드의 핵심이다.

**Independent Test**: `scripts/get-qemu-source.sh`를 실행하여 QEMU 소스가 `sources/qemu` 디렉토리에 클론되고, `scripts/configure-qemu.sh`를 실행하여 빌드 디렉토리(`build/qemu`)에 QEMU가 성공적으로 설정(configure)되는지 확인할 수 있다.

**Acceptance Scenarios**:

1.  **Given** Git이 설정된 개발 환경에서, **When** `scripts/get-qemu-source.sh`를 실행하면, **Then** 최신 또는 특정 버전의 QEMU 소스 코드가 `sources/qemu` 디렉토리에 성공적으로 클론된다.
2.  **Given** QEMU 소스 코드가 `sources/qemu`에 있고, 빌드 환경이 설정된 상태에서, **When** `scripts/configure-qemu.sh`를 실행하면, **Then** `build/qemu` 디렉토리에 QEMU 빌드를 위한 설정 파일이 오류 없이 생성된다.
3.  **Given** QEMU 소스 코드 클론 후, **When** 특정 커밋 해시로 고정하는 작업을 수행하면, **Then** `sources/qemu` submodule의 버전이 안정적으로 관리된다.

---

### 사용자 스토리 6 - QEMU 소스 빌드 및 설치 (우선순위: P1)

개발자는 설정된 QEMU 소스 코드를 컴파일하고, 지정된 디렉토리에 설치할 수 있어야 한다.

**Why this priority**: QEMU를 소스로부터 직접 사용하는 궁극적인 목표이다.

**Independent Test**: `scripts/build-qemu.sh` 스크립트를 실행하여 QEMU가 `build/qemu` 디렉토리에서 성공적으로 빌드되고, 지정된 `build/toolchain/qemu` (또는 유사한) 디렉토리에 바이너리가 설치되는지 확인할 수 있다.

**Acceptance Scenarios**:

1.  **Given** QEMU 소스 코드가 설정된 상태에서, **When** `scripts/build-qemu.sh`를 실행하면, **Then** QEMU 바이너리 및 관련 파일들이 `build/qemu` 디렉토리 내에서 성공적으로 컴파일된다.
2.  **Given** QEMU가 성공적으로 빌드된 상태에서, **When** `scripts/install-qemu.sh` (또는 빌드 스크립트 내 포함)를 실행하면, **Then** QEMU 실행 파일 (`qemu-system-riscv64` 등)이 `build/toolchain/qemu/bin` (또는 유사한) 경로에 설치된다.
3.  **Given** QEMU가 설치된 상태에서, **When** 설치된 QEMU 바이너리(`build/toolchain/qemu/bin/qemu-system-riscv64`)를 실행하면, **Then** `qemu-system-riscv64 --version` 명령어가 정상적으로 실행되고 버전 정보를 출력한다.

---

### Edge Cases

-   QEMU 소스 다운로드 실패 시 (`git clone` 실패): 사용자에게 명확한 오류 메시지 및 재시도 방법 안내.
-   의존성 패키지 설치 실패 시: 어떤 패키지가 실패했는지 명확히 알리고 수동 설치 가이드 제공.
-   QEMU configure 또는 빌드 실패 시: 빌드 로그(`build/logs/qemu_build.log`)를 통해 오류 원인을 쉽게 파악할 수 있도록 상세 로그 출력.
-   특정 QEMU 버전이 필요한 경우: `scripts/get-qemu-source.sh`에서 특정 태그나 커밋 해시를 지정할 수 있는 옵션 제공.
-   기존 시스템 QEMU와 빌드된 QEMU 간의 PATH 충돌: `toolchain-env.sh`에서 빌드된 QEMU 경로를 `PATH`에 우선하도록 관리하거나, 특정 스크립트에서만 사용하도록 경로를 명시.

## 요구 사항 *(필수)*

### 기능 요구 사항

-   **FR-001**: 시스템은 모든 부트 체인 구성 요소를 완전히 빌드하고 QEMU 가상 머신
    부팅을 시작하기 위한 단일 명령 또는 짧은 스크립트를 제공해야 합니다.
-   **FR-002**: 시스템은 개별 구성 요소(U-Boot SPL, OpenSBI, U-Boot, Linux Kernel,
    Buildroot)를 전용 명령 또는 스크립트를 통해 독립적으로 빌드할 수 있도록 허용해야 합니다.
-   **FR-003**: 시스템은 성공적인 부팅 후 QEMU 콘솔 내에서 `/proc/cpuinfo` 및 `dmesg`
    출력 확인을 가능하게 해야 합니다.
-   **FR-004**: 시스템은 간단한 테스트 프로그램(예: "hello_riscv")을 Buildroot에서 생성된
    루트 파일 시스템에 포함하고 QEMU 환경 내에서 실행할 수 있는 메커니즘을 제공해야 합니다.
-   **FR-005**: 시스템은 QEMU 소스 코드(upstream)를 `sources/qemu` 디렉토리에 다운로드할 수 있어야 한다.
-   **FR-006**: 시스템은 `sources/qemu`에 다운로드된 QEMU 소스를 사용하여 `build/qemu` 디렉토리에서 out-of-tree 방식으로 빌드할 수 있어야 한다.
-   **FR-007**: 시스템은 `build/qemu`에서 빌드된 QEMU 바이너리(예: `qemu-system-riscv64`)를 `build/toolchain/qemu/bin`과 같은 프로젝트 내 특정 경로에 설치할 수 있어야 한다.
-   **FR-008**: 시스템은 QEMU 빌드에 필요한 모든 OS 수준의 의존성 패키지를 자동으로 설치하는 스크립트를 제공해야 한다.
-   **FR-009**: 시스템은 빌드된 QEMU 바이너리를 사용하여 RISC-V QEMU virt 머신을 실행할 수 있어야 한다.
-   **FR-010**: 시스템은 QEMU 소스 코드의 특정 버전(커밋 해시)을 고정하고 관리할 수 있어야 한다.

### 주요 엔티티 *(기능에 데이터가 포함된 경우 포함)*

-   **부트 체인 구성 요소**: RISC-V QEMU 가상 머신의 부트 시퀀스를 함께 구성하는 개별
    소프트웨어 요소(U-Boot SPL, OpenSBI, U-Boot, Linux Kernel, Buildroot/rootfs).
-   **빌드 아티팩트**: 각 부트 체인 구성 요소의 컴파일로 생성된 출력 파일(예: 바이너리, 이미지).
-   **QEMU 가상 머신**: Ubuntu 호스트에서 실행되는 에뮬레이트된 RISC-V 하드웨어 환경.
-   **루트 파일 시스템 (initramfs)**: Linux 커널이 부팅되고 사용자 공간을 설정하는 데
    필요한 기본 도구 및 애플리케이션(예: busybox) 세트를 포함하는 초기 램디스크.
-   **QEMU Source**: RISC-V QEMU virt 머신 에뮬레이션을 위한 QEMU 오픈소스 프로젝트의 소스 코드. `sources/qemu` 디렉토리에 위치한다.
-   **QEMU Build Artifacts**: QEMU 소스를 컴파일하여 생성된 바이너리 파일 및 중간 빌드 파일들. `build/qemu` 디렉토리에 위치한다. 주요 산출물은 `qemu-system-riscv64` 실행 파일이다.
-   **QEMU Installation Path**: 빌드된 QEMU 실행 파일이 최종적으로 위치할 프로젝트 내 경로. 예를 들어 `build/toolchain/qemu/bin`

## 프로젝트 구조

### 소스 디렉터리 구조(Source Tree Layout)

본 프로젝트의 최상위 Git 저장소는 여러 오픈 소스 컴포넌트(U-Boot, OpenSBI, Linux Kernel, Buildroot, QEMU 등)를 Git submodule로 통합하며, 소스 코드는 다음과 같은 디렉터리 구조를 기본으로 한다.

- `<repo_root>/`
    - `sources/`
        - `qemu/` : QEMU 소스 (git submodule)
        - `u-boot/` : U-Boot 소스 (git submodule)
        - `opensbi/` : OpenSBI 소스 (git submodule)
        - `linux/` : Linux Kernel 소스 (git submodule)
        - `buildroot/` : Buildroot 소스 (git submodule)
    - `configs/`
        - 각 컴포넌트(u-boot, opensbi, linux, buildroot, qemu)에 대한 기본 설정 파일, defconfig, 패치 등을 관리
    - `scripts/`
        - 전체/부분 빌드 스크립트, QEMU 실행 스크립트, 클린업 스크립트 등 자동화 스크립트 모음
    - `docs/`
        - 빌드/부트 절차, 디버깅 방법, 버전/의존성 정보 등 문서화 파일
    - 기타 프로젝트 고유의 도구/설정을 위한 디렉터리(`tools/`, `ci/` 등)는 필요에 따라 추가한다.

이 구조의 목표는 다음과 같다.

- 외부 오픈 소스 컴포넌트와 프로젝트 자체 스크립트/설정/문서를 명확히 분리한다.
- Git submodule을 통해 각 컴포넌트 버전을 명시적으로 관리하고, 재현 가능한 빌드 환경을 제공한다.
- 새로운 오픈 소스 컴포넌트(예: 추가 부트로더, 다른 rootfs 시스템) 추가 시 `sources/` 이하에 일관되게 편입할 수 있도록 한다.

### 빌드 디렉터리 구조(Build Tree Layout)

모든 빌드 산출물(build artifacts)은 소스 트리 밖 또는 소스 트리 내의 전용 `build/` 디렉터리에 생성되며, 소스 디렉터리(`sources/*`) 내부에는 빌드 결과물이 생성되지 않도록 한다. 기본 빌드 디렉터리 레이아웃은 다음과 같다.

- 기본 빌드 루트: `<repo_root>/build/` (필요시 환경 변수 `BUILD_ROOT`로 변경 가능)
- `<repo_root>/build/`
    - `toolchain/` : 선택 사항. 별도 설치한 RISC-V 크로스 툴체인을 로컬에 두는 경우 사용
        - `qemu/` : 빌드된 QEMU 바이너리 및 관련 파일 설치 경로
    - `qemu/` : QEMU 빌드 산출물
    - `u-boot/` : U-Boot 빌드 산출물(예: SPL 이미지, u-boot.bin 등)
    - `opensbi/` : OpenSBI 빌드 산출물(예: fw_dynamic.bin 등)
    - `linux/` : Linux Kernel 빌드 산출물(예: vmlinux, Image, System.map 등)
    - `buildroot/` : Buildroot 빌드 산출물(예: rootfs.cpio, rootfs.ext2 등)
    - `images/` : QEMU 실행에 사용되는 최종 통합 이미지 모음
        - 예: `Image`, `fw_dynamic.bin`, `u-boot-spl.bin`, `rootfs.cpio` 등
    - `logs/` : 빌드 및 QEMU 실행 로그 파일(각 컴포넌트 및 전체 빌드 로그를 구분해서 저장)

각 컴포넌트는 가능한 한 **out-of-tree build**를 사용한다. 예를 들어:

- U-Boot: `O=<repo_root>/build/u-boot` 형태의 out-of-tree 옵션 사용
- Linux Kernel: `O=<repo_root>/build/linux` 형태로 빌드 디렉터리 분리
- Buildroot: `O=<repo_root>/build/buildroot` 또는 유사한 메커니즘 사용
- QEMU: `--prefix=<repo_root>/build/toolchain/qemu`와 같은 옵션을 사용하여 out-of-tree 빌드 및 설치

이 빌드 디렉터리 구조를 통해 다음을 보장한다.

- 소스와 빌드 산출물의 명확한 분리 → 깔끔한 git diff 및 clean 빌드 환경 유지
- CI/자동화 스크립트에서 공통된 경로 규칙을 사용하여 빌드/테스트/클린 작업을 단순화
- 각 컴포넌트별 빌드/클린/재빌드를 독립적으로 수행할 수 있는 구조 제공

## 성공 기준 *(필수)*

### 측정 가능한 결과

-   **SC-001**: 전체 부트 체인(크로스 툴체인 설정에서 QEMU의 busybox 셸 프롬프트까지)은
    표준 개발 서버(4코어, 8GB RAM)에서 단일 명령으로 30분 이내에 빌드 및 부팅될 수 있습니다.
-   **SC-002**: 개별 부트 체인 구성 요소는 5분 이내에 다시 빌드될 수 있습니다.
-   **SC-003**: QEMU 가상 머신은 부팅 명령이 발행된 후 60초 이내에 "riscv-qemu#"
    busybox 프롬프트로 일관되게 부팅됩니다.
-   **SC-004**: 각 부트 단계에 대한 모든 아티팩트 및 로그 파일은 문서화된 경로(예:
    `build/artifacts/`, `build/logs/`)에 일관되게 배치됩니다.

## 가정

-   Ubuntu 24.04 호스트 시스템은 소스 코드 및 툴체인 다운로드를 위한 인터넷 연결을 가지고 있습니다.
-   사용자는 필요한 호스트 패키지 및 툴체인 설치를 위한 root/sudo 권한을 가지고 있습니다.
-   사용자는 기본적인 Linux 명령줄 작업 및 `git`에 익숙합니다.

## 미해결 질문 / 명확화

-   **Q1: OpenSBI/U-Boot 버전 선택 기준**
    *   **맥락**: 빌드 재현성 및 호환성을 보장하기 위해 OpenSBI 및 U-Boot의 어떤 버전을
        사용할지 정의해야 합니다.
    *   **알아야 할 사항**: 이 프로젝트에 대한 OpenSBI 및 U-Boot의 특정 버전을 선택하는
        기준은 무엇입니까? (예: 초기 프로젝트 설정 시 최신 안정 버전, 특정 LTS, 알려진
        양호한 조합)
    *   **제안된 답변**:

        | 옵션 | 답변 | 영향 |
        |--------|--------|--------------|
        | A      | 초기 프로젝트 설정 시 최신 안정 버전 | 잠재적으로 더 많은 기능/버그 수정이 있지만,
             새로운 릴리스와 함께 불안정성을 초래할 수 있습니다. |
        | B      | 호환되는 것으로 알려진 특정 LTS 버전 | 안정성 및 장기 지원을 보장하지만,
             최신 기능이 부족할 수 있습니다. |
        | C      | RISC-V 레퍼런스(예: SiFive, 기타 오픈 소스 프로젝트)에서 명시적으로 권장하는 버전 |
             기존에 테스트된 구성을 활용하여 통합 노력을 줄입니다. |
        | 사용자 정의 | 사용자 정의 답변을 제공하십시오 | [사용자 정의 입력을 제공하는 방법 설명] |

    *   **귀하의 선택**: A

-   **Q2: QEMU Virt Machine 상세 설정**
    *   **맥락**: Spec은 QEMU virt RISC-V 64비트 머신을 사용한다고 명시하지만, 구체적인 QEMU 옵션(예: CPU 코어 수, 메모리 크기, virtio 장치 사용 여부, 네트워크 설정 등)은 명확하지 않습니다.
    *   **알아야 할 사항**: QEMU 가상 머신에 대한 초기 기본 설정(예: CPU 코어 수, RAM 크기, 주요 I/O 장치 타입)은 어떻게 구성되어야 합니까?
    *   **제안된 답변**: 4코어, 2GB RAM, virtio 콘솔 및 virtio-blk 스토리지 (SC-001의 "표준 개발 서버(4코어, 8GB RAM)"와 일관성을 유지)
    *   **귀하의 선택**: Custom - 4코어, 2GB RAM, virtio 콘솔 및 virtio-blk 스토리지 (호스트 시스템 메모리 제약)

-   **Q4: Buildroot vs. Yocto 확장 전략**
    *   **맥락**: 사용자가 Buildroot를 언급했지만 향후 Yocto 확장도 문의했습니다. 이 경로에
        대한 명확한 결정은 초기 설정 및 장기적인 유지 관리성에 영향을 미칠 것입니다.
    *   **알아야 할 사항**: 초기 구현이 Buildroot에 엄격하게 집중해야 합니까, 아니면 향후
        Yocto로의 확장을 염두에 두고 설계되어야 합니까? 그렇다면 어떤 수준의 고려가 예상됩니까?
    *   **제안된 답변**:

        | 옵션 | 답변 | 영향 |
        |--------|--------|--------------|
        | A      | 초기 설정의 단순성과 속도를 위해 Buildroot를 엄격하게 사용하고 Yocto 고려 사항을
             완전히 연기합니다. | 초기 개발 속도가 빠르지만, 나중에 Yocto로 마이그레이션하려면
             상당한 노력이 필요합니다. |
        | B      | Buildroot에 집중하되, 잠재적인 Yocto 마이그레이션 고려 사항(예: rootfs용 별도
             디렉토리, 구성 요소 빌드를 위한 모듈식 스크립트)을 문서화합니다. | 초기 속도와 향후 유연성의
             균형을 맞추며, 약간의 설계 예측이 필요합니다. |
        | C      | 처음부터 최소한의 Yocto 설정을 구현하여, 장기적인 확장성을 위해 더 높은 초기
             학습 곡선을 수용합니다. | 초기 복잡성은 가장 높지만, 처음부터 고급 임베디드 Linux 개발을 위한
             확장 가능하고 유연한 프레임워크를 제공합니다. |
        | 사용자 정의 | 사용자 정의 답변을 제공하십시오 | [사용자 정의 입력을 제공하는 방법 설명] |

    *   **귀하의 선택**: A