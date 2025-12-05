# Research: RISC-V WorldGuard QEMU Integration

**Feature**: 002-qemu-worldguard  
**Date**: 2025-12-05  
**Purpose**: WorldGuard 패치 분석 및 통합 전략 결정

## 1. WorldGuard 개요

### Decision: RISC-V WorldGuard v0.4 확장 사용

**Rationale**: cwshu/qemu riscv-wg-v3 브랜치는 RISC-V WorldGuard 확장 v0.4를 구현. SiFive가 개발하고 RISC-V International에 기증한 하드웨어 기반 격리 솔루션.

**Alternatives considered**:
- Spike 시뮬레이터의 WorldGuard 구현 → QEMU 기반 프로젝트이므로 부적합
- 자체 구현 → 이미 검증된 구현이 존재하므로 불필요

## 2. Cherry-pick 대상 커밋 분석

### Decision: 17개 커밋 선별 적용

총 cwshu-wg-v3 브랜치에서 WorldGuard 관련 커밋만 선별:

| # | Commit | Component | Description |
|---|--------|-----------|-------------|
| 1 | d2daa188e8b6 | exec | MemTxAttrs에 WID 추가 |
| 2 | f8ed123bac35 | accel/tcg | CPU 메모리 접근 시 access_type을 IOMMU에 전달 |
| 3 | 7fb836063f0d | system/physmem | 페이지 정렬 assertion 제거 |
| 4 | 02878bc9bbb4 | accel/tcg | CPUTLBEntryFull에 section 포인터 저장 |
| 5 | a685479daf5f | hw/misc | WorldGuard 전역 설정 추가 |
| 6 | 7612b5f0440b | target/riscv | WorldGuard CPU 확장 옵션 추가 |
| 7 | 8a75b7b64a5c | target/riscv | WG 확장의 하드코딩된 CPU 상태 |
| 8 | cd336a384691 | target/riscv | WorldGuard CSR 정의 |
| 9 | 851d73868318 | target/riscv | 전역 WG 설정에서 CPU 콜백 설정 허용 |
| 10 | b2d5e0f5d673 | target/riscv | WorldGuard CSR 구현 |
| 11 | bf77230b0c93 | target/riscv | CPU 메모리 트랜잭션에 WID 추가 |
| 12 | 7a3d43bbfd57 | target/riscv | WorldGuard CPU 옵션 노출 |
| 13 | e928a260473f | hw/misc | CPU의 WG 확장 활성화 API |
| 14 | dcf690ef2c39 | hw/misc | WorldGuard Checker 구현 |
| 15 | 8e3d8757c968 | hw/misc | wgchecker slot 레지스터 구현 |
| 16 | 64269b0f97a3 | hw/misc | block-access 동작 구현 |
| 17 | 018e448e21c2 | hw/misc | translate 시 slot 설정 확인 |
| 18 | b977233a0522 | hw/riscv | virt 머신에 WorldGuard 지원 추가 |

**Rationale**: 의존성 순서대로 정렬. 기반 구조(exec, accel/tcg) → CPU 확장(target/riscv) → 하드웨어 장치(hw/misc) → 머신 통합(hw/riscv) 순서로 적용.

**Alternatives considered**:
- 전체 브랜치 merge → 불필요한 커밋 포함 (tcg/ppc, target/hexagon 등)
- 패치 파일로 추출 → Git 히스토리 손실

## 3. QEMU 버전 호환성

### Decision: QEMU v10.1.3 기반 유지

**Rationale**: 
- 현재 프로젝트는 v10.1.3 기반으로 OpenSBI/U-Boot/Linux 부팅 검증 완료
- riscv-wg-v3는 v10.2.0 개발 중 시점 기반 (약간 신규)
- Cherry-pick으로 핵심 기능만 이식하면 호환 가능

**Alternatives considered**:
- riscv-wg-v3 기반 버전으로 전환 → 기존 검증 결과 무효화
- 두 버전 병행 관리 → 복잡성 증가

## 4. WorldGuard 활성화 방법

### Decision: QEMU 명령줄 옵션으로 활성화

**Rationale**: 
- virt 머신의 worldguard 옵션 사용 예상: `-M virt,worldguard=on`
- 또는 CPU 옵션으로: `-cpu rv64,wg=true` 형태
- 정확한 옵션은 패치 적용 후 `-M virt,help` 출력으로 확인

**Alternatives considered**:
- 컴파일 시 옵션 → 런타임 유연성 부족
- 환경 변수 → QEMU 표준 방식 아님

## 5. 충돌 해결 전략

### Decision: 커밋별 수동 해결

**Rationale**:
- Cherry-pick 시 각 커밋에서 발생하는 충돌을 즉시 파악 가능
- v10.1.3과 riscv-wg-v3 기반 차이로 인한 컨텍스트 충돌 예상
- 충돌 해결 내용을 커밋 메시지에 기록하여 추적성 확보

**충돌 예상 파일**:
- `accel/tcg/cputlb.c` - TCG 관련 변경이 있을 수 있음
- `include/exec/memattrs.h` - MemTxAttrs 구조체 변경
- `hw/riscv/virt.c` - virt 머신 구현

## 6. 펌웨어 호환성

### Decision: 기존 펌웨어 수정 없이 사용

**Rationale**:
- WorldGuard는 QEMU 하드웨어 에뮬레이션 레벨의 기능
- OpenSBI/U-Boot/Linux는 WorldGuard 하드웨어 감지 및 무시 가능
- 본격적인 WorldGuard 활용은 Out of Scope

**향후 확장 가능성**:
- OpenSBI에 WorldGuard 초기화 코드 추가 (별도 기능)
- Linux 커널에 WorldGuard 드라이버 추가 (별도 기능)

## 7. 결론

WorldGuard 통합은 다음 단계로 진행:

1. **Phase 1**: 17개 커밋 순서대로 cherry-pick
2. **Phase 2**: QEMU 빌드 및 WorldGuard 옵션 확인
3. **Phase 3**: WorldGuard 활성화 부팅 테스트
4. **Phase 4**: 실행 스크립트 작성 및 문서화

예상 소요 시간: 2-3시간 (충돌 해결 난이도에 따라 변동)
