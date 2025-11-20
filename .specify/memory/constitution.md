<!--
Sync Impact Report:
Version change: 0.2.0 -> 0.3.0
List of modified principles:
  - (New) Ⅺ. 문서 작성 언어
Added sections: 문서 운영 원칙
Removed sections: None
Templates requiring updates:
  - .specify/templates/plan-template.md: ✅ updated
  - .specify/templates/spec-template.md: ⚠ pending (content should align)
  - .specify/templates/tasks-template.md: ⚠ pending (content should align)
  - .specify/commands/speckit.analyze.toml: ✅ updated
  - .specify/commands/speckit.checklist.toml: ✅ updated
  - .specify/commands/speckit.clarify.toml: ✅ updated
  - .specify/commands/speckit.constitution.toml: ✅ updated
  - .specify/commands/speckit.implement.toml: ✅ updated
  - .specify/commands/speckit.plan.toml: ✅ updated
  - .specify/commands/speckit.specify.toml: ✅ updated
  - .specify/commands/speckit.tasks.toml: ✅ updated
  - .specify/commands/speckit.taskstoissues.toml: ✅ updated
Follow-up TODOs:
  - TODO(RATIFICATION_DATE): Original adoption date unknown
-->
# RISC-V QEMU Virt 부트 체인 프로젝트 헌장

## 핵심 원칙

### Ⅰ. 빌드 재현성
모든 빌드는 Ubuntu 24.04 (headless) 서버 환경에서 완전하게 재현 가능해야 한다. 이는 개발 환경의 일관성을 보장하고 빌드 오류를 최소화하기 위함이다.

### Ⅱ. 컴포넌트 및 버전 관리
RISC-V 툴체인, U-Boot, OpenSBI, Linux Kernel, Buildroot는 공식 또는 mainline에 가까운 버전을 사용하며, 모든 컴포넌트의 정확한 버전은 명시적으로 기록되고 관리되어야 한다.

### Ⅲ. 타깃 아키텍처 지원
기본 개발 및 테스트 타깃은 QEMU virt RISC-V 64비트 머신으로 한다. 향후 다른 RISC-V 기반 하드웨어 머신 추가를 유연하게 지원할 수 있도록 설계한다.

### Ⅳ. 모듈화된 컴포넌트 관리
u-boot SPL, OpenSBI, U-Boot, Linux Kernel, Buildroot 각 컴포넌트는 독립적인 설정 파일과 빌드 스크립트를 가져야 한다. 이는 각 컴포넌트의 독립적인 개발, 테스트 및 유지보수를 용이하게 한다.

### Ⅴ. 일관된 개발 환경
크로스 컴파일 환경 설정(예: riscv64-linux-gnu-tool체인)은 스크립트화하여 개발자 간의 환경 설정 차이를 최소화하고 온보딩 프로세스를 간소화한다.

### Ⅵ. 디버깅 및 성능 관리
개발 및 디버깅을 위한 옵션(earlycon, UART log, QEMU 로그 옵션 등)을 기본 제공한다. 릴리즈 빌드 시에는 이러한 디버깅 옵션으로 인한 성능 저하를 최소화해야 한다.

### Ⅶ. 문서 및 코드 동기화
Spec, Plan, Tasks 문서와 실제 스크립트 및 코드는 항상 최신 상태로 동기화되어야 한다. 주요 변경 사항 발생 시에는 Spec 문서를 우선적으로 업데이트한 후 구현을 진행한다.

### Ⅷ. 라이선스 및 SBOM 관리
프로젝트에 사용되는 모든 오픈소스 컴포넌트의 라이선스 정보, SBOM (Software Bill of Materials) 및 정확한 버전은 명확하게 문서화되어야 한다.

## Git 운영 원칙

### Ⅸ. Git 커밋 및 형상관리
모든 Git 커밋은 각 오픈소스 프로젝트(U-Boot, Linux Kernel, OpenSBI, Buildroot 등)의 공식 커밋 스타일 가이드를 존중한다. Subsystem prefix, 태그 규칙, Signed-off-by 등의 관행을 가능하면 upstream 정책과 일치시키도록 한다. 모든 커밋은 atomic 하게 작성하여, 하나의 커밋이 하나의 논리적 변경만을 포함하도록 한다. 커밋 메시지는 50/72 규칙을 기본 원칙으로 한다. Summary는 50자 이내로 간결하게 작성하고, 본문은 72자 기준으로 줄바꿈한다. '왜(Why)'를 핵심적으로 기술하고, 필요 시 '무엇(What)'과 '어떻게(How)'를 덧붙인다.

### Ⅹ. 언어 정책
모든 커밋 메시지는 영어로 작성해야 한다. 코드 내 주석 또한 영어로 작성해야 한다. 이는 전역적인 협업과 가독성을 증진하기 위함이다.

## 소스/빌드 디렉터리 구조 원칙

### Ⅹ. 소스/빌드 디렉터리 구조
모든 빌드 산출물(build artifacts)은 소스 트리 외부의 전용 디렉터리에 생성하여, 소스 디렉터리 내부에 빌드 결과물이 섞이지 않도록 한다. 이는 재현성, clean 빌드, CI의 일관성을 보장하기 위한 필수 원칙이다. 프로젝트 최상위 저장소는 Git submodule을 사용하여 U-Boot, OpenSBI, Linux Kernel, Buildroot 등 여러 오픈소스 컴포넌트를 구조적으로 통합한다. 각 서브모듈의 버전(커밋 해시)은 명확히 고정하며, 변경 시 이력을 문서화한다.

## 추가 제약 사항

*   **운영체제**: 모든 개발 및 빌드 작업은 Ubuntu 24.04 (headless) 환경에서 이루어져야 한다.
*   **하드웨어 타깃**: 기본 타깃은 QEMU virt RISC-V 64비트 머신이며, 호환성 및 확장성을 고려하여 설계한다.

## 개발 워크플로우

*   **문서 중심 개발**: 모든 주요 기능 변경 및 추가는 Spec 문서 업데이트 → Plan 문서 작성 → Task 문서 작성 → 코드 구현 순서를 따른다.
*   **코드 리뷰**: 모든 코드 변경은 최소 1인 이상의 동료 개발자로부터 코드 리뷰를 받아야 한다.
*   **버전 관리**: Git을 통한 엄격한 버전 관리를 수행하며, semantic versioning 규칙을 준수한다.

## 문서 운영 원칙

### Ⅺ. 문서 작성 언어
Spec 문서는 가급적 한국어로 작성하여 국내 이해 관계자들의 접근성을 높이고, 필요한 경우에만 영어 번역본을 제공한다.

## 거버넌스

본 헌장은 프로젝트의 모든 결정과 활동에 우선한다. 헌장 개정은 문서화된 절차와 승인을 거쳐야 하며, 모든 변경 사항은 기존 규칙과의 호환성을 고려해야 한다. 모든 풀 리퀘스트(PR) 및 코드 리뷰는 본 헌장 준수 여부를 확인해야 한다. 복잡성은 명확히 정당화되어야 한다.

**버전**: 0.3.0 | **비준일**: TODO(RATIFICATION_DATE): Original adoption date unknown | **최종 개정일**: 2025-11-20