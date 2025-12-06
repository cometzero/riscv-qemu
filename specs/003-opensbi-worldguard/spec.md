# Feature Specification: OpenSBI WorldGuard Support

**Feature Branch**: `003-opensbi-worldguard`  
**Created**: 2025-12-06  
**Status**: Draft  
**Input**: "OpenSBI WorldGuard 지원 추가 - 초기에는 임시 테스트 코드로 설정, 테스트 후 Device Tree 기반 mwid/CSR 설정 및 wgChecker 설정 구현"

## Overview

OpenSBI에 RISC-V WorldGuard 지원을 추가합니다. WorldGuard는 하드웨어 기반 메모리 격리 메커니즘으로, World ID(WID)를 통해 다른 보안 도메인 간의 격리를 제공합니다.

이 기능은 두 단계로 구현됩니다:
1. **Phase 1 (테스트)**: 하드코딩된 WorldGuard 설정으로 기본 동작 검증
2. **Phase 2 (제품화)**: Device Tree를 통한 유연한 WorldGuard 설정

OpenSBI는 M-mode에서 실행되어 WorldGuard CSR(mlwid, slwid, mwiddeleg)을 초기화하고, 필요시 wgChecker MMIO를 구성합니다.

## Prerequisites

- QEMU v10.1.3 + WorldGuard 패치 (002-qemu-worldguard에서 완료)
- WorldGuard QEMU 옵션 (`-M virt,wg=on,wg-nworlds=4,wg-trustedwid=3`)
- OpenSBI v1.7 소스 코드

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 임시 테스트 코드로 WorldGuard 초기화 (Priority: P1)

개발자는 OpenSBI에 하드코딩된 WorldGuard 설정을 추가하여, WorldGuard CSR이 올바르게 초기화되는지 검증할 수 있어야 한다.

**Why this priority**: WorldGuard 동작을 검증하기 위한 가장 빠른 방법이며, Device Tree 통합 전 기능 검증이 필요함

**Independent Test**: QEMU 부팅 시 OpenSBI 로그에서 WorldGuard 초기화 메시지를 확인할 수 있다

**Acceptance Scenarios**:

1. **Given** WorldGuard 패치된 OpenSBI, **When** QEMU에서 `wg=on`으로 부팅, **Then** OpenSBI 로그에 "WorldGuard: enabled, mlwid=X" 메시지가 표시됨
2. **Given** WorldGuard 초기화 완료, **When** OpenSBI가 U-Boot로 전환, **Then** U-Boot가 정상 부팅됨
3. **Given** WorldGuard CSR 설정 완료, **When** 부팅 로그 확인, **Then** mlwid=3(trusted), slwid=2가 설정됨

---

### User Story 2 - Device Tree 기반 WID 및 CSR 설정 (Priority: P2)

개발자는 Device Tree를 통해 WorldGuard WID 할당과 CSR 설정을 구성할 수 있어야 하며, 하드코딩 없이 다양한 설정을 지원해야 한다.

**Why this priority**: 제품화 및 다양한 플랫폼 지원을 위해 유연한 설정 방식이 필요함

**Independent Test**: Device Tree에서 WorldGuard 노드를 수정하고, OpenSBI가 해당 설정을 읽어 적용하는지 확인할 수 있다

**Acceptance Scenarios**:

1. **Given** Device Tree에 WorldGuard 노드가 정의됨, **When** OpenSBI가 부팅, **Then** Device Tree에서 nworlds, trustedwid 값을 읽어 CSR에 적용됨
2. **Given** 다른 trustedwid 값(예: 7)이 Device Tree에 설정됨, **When** OpenSBI 부팅, **Then** mlwid가 7로 설정됨
3. **Given** Device Tree에 WID 할당 정책이 정의됨, **When** S-mode 전환, **Then** slwid가 정책에 따라 설정됨

---

### User Story 3 - Device Tree 기반 wgChecker 설정 (Priority: P3)

개발자는 Device Tree를 통해 wgChecker 슬롯 구성을 정의하여, OpenSBI가 메모리 보호 규칙을 동적으로 설정할 수 있어야 한다.

**Why this priority**: wgChecker 슬롯은 메모리 보호의 핵심이며, 플랫폼별로 다른 메모리 레이아웃을 지원해야 함

**Independent Test**: Device Tree에서 wgChecker 슬롯을 정의하고, OpenSBI가 해당 슬롯을 MMIO에 프로그래밍하는지 확인할 수 있다

**Acceptance Scenarios**:

1. **Given** Device Tree에 wgchecker 노드와 슬롯 정의, **When** OpenSBI 부팅, **Then** wgChecker MMIO에 슬롯이 프로그래밍됨
2. **Given** 특정 메모리 영역에 WID=3만 접근 가능하도록 설정, **When** WID=2로 해당 영역 접근 시도, **Then** 접근이 차단됨
3. **Given** 슬롯에 Lock 비트 설정, **When** S-mode에서 슬롯 수정 시도, **Then** 수정이 거부됨

---

### Edge Cases

- WorldGuard CSR이 존재하지 않는 CPU에서 OpenSBI가 안전하게 감지하고 비활성화해야 함
- Device Tree에 WorldGuard 노드가 없으면 WorldGuard 기능을 비활성화해야 함
- nworlds 값이 CPU가 지원하는 범위를 초과하면 오류를 보고해야 함
- wgChecker 슬롯 수가 하드웨어 한계를 초과하면 경고를 출력해야 함

## Requirements *(mandatory)*

### Functional Requirements

#### Phase 1: 테스트 코드
- **FR-001**: OpenSBI는 WorldGuard CSR(mlwid, slwid, mwiddeleg)의 존재를 감지할 수 있어야 함
- **FR-002**: OpenSBI는 mlwid를 trustedwid(기본값 3)로 설정해야 함
- **FR-003**: OpenSBI는 slwid를 S-mode용 WID(기본값 2)로 설정해야 함
- **FR-004**: OpenSBI는 mwiddeleg를 설정하여 S-mode가 사용할 WID를 위임해야 함
- **FR-005**: WorldGuard 초기화 결과를 부팅 로그에 출력해야 함

#### Phase 2: Device Tree 통합
- **FR-006**: OpenSBI는 Device Tree에서 `riscv,worldguard` 노드를 파싱할 수 있어야 함
- **FR-007**: `nworlds`, `trustedwid` 속성을 읽어 CSR 설정에 반영해야 함
- **FR-008**: `wid-assignment` 속성을 통해 각 모드(M/S/U)의 WID를 설정할 수 있어야 함
- **FR-009**: Device Tree에서 wgChecker 슬롯 정의를 읽어 MMIO에 프로그래밍해야 함
- **FR-010**: 슬롯별 address, permission, config(TOR/NAPOT/OFF/Lock) 설정을 지원해야 함

### Non-Functional Requirements

- **NFR-001**: WorldGuard 초기화는 OpenSBI 부팅 시간에 10ms 미만의 오버헤드만 추가해야 함
- **NFR-002**: WorldGuard CSR 접근 오류 시 안전하게 실패하고 기능을 비활성화해야 함

### Key Entities

- **WorldGuard CSRs**: mlwid(0x390), slwid(0x190), mwiddeleg(0x748)
- **wgChecker**: 메모리 접근 제어를 위한 MMIO 디바이스 (0x6000000)
- **wgChecker Slot**: addr, perm, cfg로 구성된 메모리 보호 규칙
- **Device Tree Node**: WorldGuard 설정을 담는 FDT 노드

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: WorldGuard CSR 감지 및 초기화가 5ms 이내에 완료됨
- **SC-002**: OpenSBI 부팅 로그에 WorldGuard 상태(mlwid, slwid 값)가 표시됨
- **SC-003**: Device Tree 기반 설정 변경 시 OpenSBI 코드 수정 없이 동작함
- **SC-004**: WorldGuard 활성화/비활성화 모두에서 전체 부트 체인이 정상 동작함
- **SC-005**: wgChecker 슬롯이 Device Tree 정의에 따라 정확히 프로그래밍됨

## Assumptions

- QEMU의 WorldGuard 구현이 스펙 v0.4를 따름
- OpenSBI v1.7이 새로운 CSR 접근 API를 제공함
- Device Tree 파싱을 위한 libfdt가 OpenSBI에 이미 통합되어 있음
- wgChecker MMIO 주소는 QEMU virt 머신에서 0x6000000로 고정됨

## Dependencies

- `002-qemu-worldguard`: QEMU WorldGuard 통합 (완료)
- OpenSBI 소스: `sources/opensbi/` (v1.7)
- Device Tree Overlay 지원 (있는 경우 활용)

## Out of Scope

- Linux 커널 WorldGuard 드라이버 구현
- U-Boot WorldGuard 지원
- 동적 WID 변경 API
- WorldGuard SBI 확장 (별도 기능으로 개발)
