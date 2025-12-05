# Implementation Plan: RISC-V WorldGuard QEMU Integration

**Branch**: `002-qemu-worldguard` | **Date**: 2025-12-05 | **Spec**: [spec.md](file:///home/ubuntu/work/risc-v/specs/002-qemu-worldguard/spec.md)
**Input**: Feature specification from `/specs/002-qemu-worldguard/spec.md`

## Summary

cwshu/qemu의 riscv-wg-v3 브랜치에 구현된 RISC-V WorldGuard 확장(v0.4)을 프로젝트 QEMU v10.1.3에 통합합니다. Git cherry-pick을 통해 17개의 WorldGuard 관련 커밋을 선별 적용하며, 충돌 발생 시 수동으로 해결합니다. 통합 후 WorldGuard 옵션을 활성화한 상태에서 OpenSBI → U-Boot → Linux 부트 체인이 정상 동작하는지 검증합니다.

## Technical Context

**Language/Version**: C (QEMU codebase), Bash (빌드 스크립트)  
**Primary Dependencies**: QEMU v10.1.3, OpenSBI v1.7, U-Boot v2024.10, Linux v6.18  
**Storage**: N/A  
**Testing**: QEMU 부팅 테스트 (scripts/run-qemu.sh), 수동 검증  
**Target Platform**: Ubuntu 24.04 (headless), QEMU virt RISC-V 64비트  
**Project Type**: Single (기존 QEMU 서브모듈에 패치 적용)  
**Performance Goals**: 부팅 시간 기존 대비 120% 이내  
**Constraints**: QEMU v10.1.3 기반 유지, 하위 호환성 보장 (WorldGuard 비활성화 시 기존 동작 유지)  
**Scale/Scope**: 17개 커밋 cherry-pick, 1개 QEMU 실행 스크립트 수정

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] 빌드 재현성 (Principle I): 모든 빌드가 Ubuntu 24.04 (headless)에서 재현 가능한가? → Git cherry-pick 사용으로 재현 가능
- [x] 컴포넌트 및 버전 관리 (Principle II): 사용될 모든 RISC-V 툴체인 및 컴포넌트 버전이 명시되었는가? → QEMU v10.1.3 + WorldGuard 커밋 명시
- [x] 타깃 아키텍처 지원 (Principle III): QEMU virt RISC-V 64비트 머신을 기본 타깃으로 하며, 향후 확장성을 고려한 설계인가? → virt 머신에 WorldGuard 옵션 추가
- [x] 모듈화된 컴포넌트 관리 (Principle IV): 각 컴포넌트가 독립적인 설정 파일과 빌드 스크립트를 가지는가? → 기존 build-qemu.sh 활용
- [x] 일관된 개발 환경 (Principle V): 크로스 컴파일 환경 설정이 스크립트화되어 제공되는가? → toolchain-env.sh 활용
- [x] 디버깅 및 성능 관리 (Principle VI): 디버깅 옵션 제공 여부 및 릴리즈 빌드 시 성능 저하 최소화 방안이 고려되었는가? → WorldGuard 옵션은 선택적 활성화
- [x] 문서 및 코드 동기화 (Principle VII): Spec, Plan, Tasks 문서와 실제 스크립트/코드의 동기화 계획이 수립되었는가? → 본 Plan 문서에서 정의
- [x] 라이선스 및 SBOM 관리 (Principle VIII): 라이선스 정보, SBOM, 오픈소스 컴포넌트 버전 문서화 계획이 포함되었는가? → QEMU GPL-2.0 라이선스 유지

## Project Structure

### Documentation (this feature)

```text
specs/002-qemu-worldguard/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file
├── research.md          # WorldGuard commits analysis
└── tasks.md             # Implementation tasks (to be generated)
```

### Source Code (repository root)

```text
sources/qemu/           # QEMU 소스 (v10.1.3 + WorldGuard 패치)
├── target/riscv/       # WorldGuard CSR 및 CPU 확장
├── hw/misc/            # WorldGuard checker 구현
├── hw/riscv/           # virt 머신 WorldGuard 지원
├── accel/tcg/          # TCG 메모리 접근 수정
└── exec/               # MemTxAttrs WID 추가

scripts/
├── build-qemu.sh       # QEMU 빌드 (기존)
├── run-qemu.sh         # QEMU 실행 (WorldGuard 옵션 추가)
└── run-qemu-worldguard.sh  # WorldGuard 전용 실행 스크립트 (신규)
```

**Structure Decision**: 기존 QEMU 서브모듈 구조를 유지하며, WorldGuard 패치를 cherry-pick으로 적용. 새로운 실행 스크립트로 WorldGuard 옵션 활성화 지원.

## Proposed Changes

### Phase 1: WorldGuard 패치 Cherry-pick

#### [MODIFY] sources/qemu (Git submodule)

17개의 WorldGuard 관련 커밋을 cherry-pick:

```text
Cherry-pick 순서 (의존성 순서):
1. d2daa188e8b6 exec: Add RISC-V WorldGuard WID to MemTxAttrs
2. f8ed123bac35 accel/tcg: memory access from CPU will pass access_type to IOMMU
3. 7fb836063f0d system/physmem: Remove the assertion of page-aligned section number
4. 02878bc9bbb4 accel/tcg: Store section pointer in CPUTLBEntryFull
5. a685479daf5f hw/misc: riscv_worldguard: Add RISC-V WorldGuard global config
6. 7612b5f0440b target/riscv: Add CPU options of WorldGuard CPU extension
7. 8a75b7b64a5c target/riscv: Add hard-coded CPU state of WG extension
8. cd336a384691 target/riscv: Add defines for WorldGuard CSRs
9. 851d73868318 target/riscv: Allow global WG config to set WG CPU callbacks
10. b2d5e0f5d673 target/riscv: Implement WorldGuard CSRs
11. bf77230b0c93 target/riscv: Add WID to MemTxAttrs of CPU memory transactions
12. 7a3d43bbfd57 target/riscv: Expose CPU options of WorldGuard
13. e928a260473f hw/misc: riscv_worldguard: Add API to enable WG extension of CPU
14. dcf690ef2c39 hw/misc: riscv_wgchecker: Implement RISC-V WorldGuard Checker
15. 8e3d8757c968 hw/misc: riscv_wgchecker: Implement wgchecker slot registers
16. 64269b0f97a3 hw/misc: riscv_wgchecker: Implement correct block-access behavior
17. 018e448e21c2 hw/misc: riscv_wgchecker: Check the slot settings in translate
18. b977233a0522 hw/riscv: virt: Add WorldGuard support
```

---

### Phase 2: QEMU 빌드 및 검증

#### [MODIFY] [scripts/build-qemu.sh](file:///home/ubuntu/work/risc-v/scripts/build-qemu.sh)

빌드 전 WorldGuard 패치 적용 여부 확인 로직 추가 (선택사항)

---

### Phase 3: WorldGuard 실행 스크립트

#### [NEW] scripts/run-qemu-worldguard.sh

WorldGuard 옵션을 활성화한 QEMU 실행 스크립트:
- `-M virt,worldguard=on` 또는 적절한 WorldGuard 활성화 옵션 사용
- 기존 run-qemu.sh 기반으로 WorldGuard 전용 버전 생성

---

## Verification Plan

### Automated Tests

1. **QEMU 빌드 테스트**
   ```bash
   cd /home/ubuntu/work/risc-v
   ./scripts/build-qemu.sh
   # 성공 기준: exit code 0, qemu-system-riscv64 바이너리 생성
   ```

2. **WorldGuard 옵션 확인**
   ```bash
   ./build/qemu/install/bin/qemu-system-riscv64 -M virt,help 2>&1 | grep -i worldguard
   # 성공 기준: worldguard 관련 옵션 표시
   ```

3. **WorldGuard 비활성화 부팅 테스트 (회귀 테스트)**
   ```bash
   timeout 60 ./scripts/run-qemu.sh 2>&1 | tail -50
   # 성공 기준: "Welcome to Buildroot" 또는 로그인 프롬프트 표시
   ```

4. **WorldGuard 활성화 부팅 테스트**
   ```bash
   timeout 60 ./scripts/run-qemu-worldguard.sh 2>&1 | tail -50
   # 성공 기준: Linux 부팅 완료, FATAL/PANIC 오류 없음
   ```

### Manual Verification

1. **Cherry-pick 충돌 해결**: 각 커밋 적용 시 충돌 발생 여부 수동 확인 및 해결
2. **부팅 로그 검토**: WorldGuard 관련 메시지 확인 (OpenSBI/U-Boot/Linux 로그)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |
