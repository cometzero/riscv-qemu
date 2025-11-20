# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [single/web/mobile - determines source structure]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [ ] 빌드 재현성 (Principle I): 모든 빌드가 Ubuntu 24.04 (headless)에서 재현 가능한가?
- [ ] 컴포넌트 및 버전 관리 (Principle II): 사용될 모든 RISC-V 툴체인 및 컴포넌트 (U-Boot, OpenSBI, Linux Kernel, Buildroot)의 버전이 명시되었는가? 공식 또는 mainline에 가까운 버전을 사용하는가?
- [ ] 타깃 아키텍처 지원 (Principle III): QEMU virt RISC-V 64비트 머신을 기본 타깃으로 하며, 향후 확장성을 고려한 설계인가?
- [ ] 모듈화된 컴포넌트 관리 (Principle IV): 각 컴포넌트(u-boot SPL, OpenSBI, U-Boot, Linux Kernel, Buildroot)가 독립적인 설정 파일과 빌드 스크립트를 가지는가?
- [ ] 일관된 개발 환경 (Principle V): 크로스 컴파일 환경 설정이 스크립트화되어 제공되는가?
- [ ] 디버깅 및 성능 관리 (Principle VI): 디버깅 옵션 제공 여부 및 릴리즈 빌드 시 성능 저하 최소화 방안이 고려되었는가?
- [ ] 문서 및 코드 동기화 (Principle VII): Spec, Plan, Tasks 문서와 실제 스크립트/코드의 동기화 계획이 수립되었는가? 큰 변경 전 Spec 업데이트 원칙을 따르는가?
- [ ] 라이선스 및 SBOM 관리 (Principle VIII): 라이선스 정보, SBOM, 오픈소스 컴포넌트 버전 문서화 계획이 포함되었는가?

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
