# Feature Specification: RISC-V WorldGuard QEMU Integration

**Feature Branch**: `002-qemu-worldguard`  
**Created**: 2025-12-05  
**Status**: Draft  
**Input**: User description: "RISC-V WorldGuard의 QEMU 구현을 본 프로젝트에 통합 - WorldGuard Patch Integration, WorldGuard Option 활성화, OpenSBI/U-Boot/Linux 부팅 검증"

## Overview

RISC-V WorldGuard는 하드웨어 기반 소프트웨어 격리 솔루션으로, Trusted Execution Environment (TEE)를 RISC-V 플랫폼에서 구현할 수 있게 합니다. WorldGuard는 World ID (WID)를 사용하여 메모리 접근을 태깅하고, Access Control List (ACL)를 통해 권한을 검증합니다.

본 기능은 cwshu/qemu의 riscv-wg-v3 브랜치에 구현된 WorldGuard 패치를 프로젝트의 QEMU에 통합하여, WorldGuard가 활성화된 상태에서 전체 부트 체인(OpenSBI → U-Boot → Linux)이 정상 동작하도록 합니다.

## Clarifications

### Session 2025-12-05

- Q: 패치 충돌 시 어떤 통합 전략을 사용할 것인가? → A: Git cherry-pick으로 WorldGuard 관련 커밋만 선별 적용
- Q: WorldGuard 통합 후 프로젝트 QEMU 버전 관리 방식? → A: 현재 QEMU v10.1.3 유지 + WorldGuard 커밋 cherry-pick

## User Scenarios & Testing *(mandatory)*

### User Story 1 - WorldGuard 패치 QEMU 통합 (Priority: P1)

개발자는 cwshu/qemu의 riscv-wg-v3 브랜치의 WorldGuard 구현을 현재 프로젝트의 QEMU 소스에 통합하여, WorldGuard 하드웨어 기능을 에뮬레이션할 수 있어야 한다.

**Why this priority**: WorldGuard 기능을 사용하기 위한 가장 기본적인 전제조건이며, 이후 모든 스토리가 이에 의존함

**Independent Test**: QEMU 빌드가 성공하고, WorldGuard 관련 옵션이 QEMU에서 인식되는지 확인할 수 있다

**Acceptance Scenarios**:

1. **Given** 프로젝트의 QEMU 소스, **When** WorldGuard 패치를 적용하고 빌드를 실행, **Then** QEMU가 오류 없이 빌드됨
2. **Given** WorldGuard 패치가 적용된 QEMU, **When** `qemu-system-riscv64 --help` 또는 `-M virt,help`를 실행, **Then** WorldGuard 관련 옵션이 표시됨

---

### User Story 2 - WorldGuard 옵션 활성화 QEMU 실행 (Priority: P2)

개발자는 QEMU를 WorldGuard 옵션을 활성화한 상태로 실행하여, 가상 머신이 WorldGuard 하드웨어 기능을 사용할 수 있어야 한다.

**Why this priority**: WorldGuard 기능이 실제로 동작하는지 확인하는 핵심 단계

**Independent Test**: WorldGuard 옵션을 켜고 QEMU를 실행했을 때 오류 없이 시작되고, OpenSBI가 WorldGuard를 인식하는지 확인할 수 있다

**Acceptance Scenarios**:

1. **Given** WorldGuard 패치가 적용된 QEMU, **When** WorldGuard 옵션을 활성화하여 실행, **Then** QEMU가 오류 없이 실행됨
2. **Given** WorldGuard가 활성화된 QEMU, **When** OpenSBI가 부팅, **Then** OpenSBI 로그에서 WorldGuard 관련 정보가 표시되거나 정상 동작함

---

### User Story 3 - WorldGuard 활성화 상태에서 전체 부트 체인 동작 (Priority: P3)

개발자는 WorldGuard가 활성화된 QEMU 환경에서 OpenSBI, U-Boot, Linux 커널이 모두 정상적으로 부팅되어, WorldGuard 환경에서 시스템이 동작하는지 검증할 수 있어야 한다.

**Why this priority**: 최종 목표이며, WorldGuard가 실제 시스템에서 사용 가능함을 증명

**Independent Test**: WorldGuard 옵션이 켜진 QEMU에서 전체 부트 체인을 실행하여 Linux 로그인 프롬프트까지 도달하는지 확인할 수 있다

**Acceptance Scenarios**:

1. **Given** WorldGuard가 활성화된 QEMU, **When** 부트 체인(OpenSBI → U-Boot → Linux)을 실행, **Then** Linux 커널이 부팅되고 로그인 프롬프트가 표시됨
2. **Given** WorldGuard 활성화 부팅 완료, **When** 시스템 로그를 확인, **Then** WorldGuard 관련 오류나 경고 없이 정상 동작함

---

### Edge Cases

- WorldGuard 패치가 현재 QEMU 버전(v10.1.3)과 충돌할 경우: Git cherry-pick으로 WorldGuard 관련 커밋만 선별 적용하며, 충돌 시 각 커밋별로 수동 해결
- WorldGuard 옵션이 없는 펌웨어(OpenSBI/U-Boot/Linux)와의 호환성은 어떻게 유지하는가?
- 메모리 크기나 CPU 수 등 다른 QEMU 옵션과의 조합에서 문제가 발생하는가?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 시스템은 cwshu/qemu riscv-wg-v3 브랜치의 WorldGuard 패치를 프로젝트 QEMU에 적용할 수 있어야 함
- **FR-002**: 시스템은 WorldGuard 패치 적용 후 QEMU를 성공적으로 빌드할 수 있어야 함
- **FR-003**: QEMU는 WorldGuard 관련 명령줄 옵션을 제공해야 함 (예: `-M virt,worldguard=on`)
- **FR-004**: WorldGuard 옵션 활성화 시 QEMU가 오류 없이 시작되어야 함
- **FR-005**: WorldGuard 활성화 상태에서 OpenSBI가 정상 부팅되어야 함
- **FR-006**: WorldGuard 활성화 상태에서 U-Boot가 정상 부팅되어야 함
- **FR-007**: WorldGuard 활성화 상태에서 Linux 커널이 정상 부팅되어야 함
- **FR-008**: WorldGuard 활성화/비활성화 모두에서 기존 부트 체인이 동작해야 함 (하위 호환성)

### Key Entities

- **WorldGuard Patch**: cwshu/qemu riscv-wg-v3 브랜치에 포함된 QEMU 코드 변경사항
- **World ID (WID)**: WorldGuard에서 메모리 접근을 식별하는 태그
- **QEMU virt Machine**: WorldGuard 옵션이 추가될 RISC-V 가상 머신 정의

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: WorldGuard 패치 적용 후 QEMU 빌드가 5분 이내에 성공적으로 완료됨
- **SC-002**: WorldGuard 옵션을 켠 QEMU 실행 시 1초 이내에 정상 시작됨
- **SC-003**: WorldGuard 활성화 상태에서 OpenSBI → U-Boot → Linux 부팅이 기존 부팅 시간의 120% 이내에 완료됨
- **SC-004**: WorldGuard 비활성화 상태에서 기존 부트 체인이 동일하게 동작함 (기능 회귀 없음)
- **SC-005**: 부팅 로그에 WorldGuard 관련 심각한 오류(FATAL, PANIC)가 없음

## Assumptions

- 프로젝트 QEMU는 v10.1.3 기반을 유지하며, WorldGuard 커밋만 cherry-pick으로 추가함
- cwshu/qemu riscv-wg-v3 브랜치의 WorldGuard 관련 커밋은 선별적으로 적용 가능하며, 충돌 시 커밋별로 수동 해결함
- OpenSBI, U-Boot, Linux 커널은 WorldGuard 하드웨어가 있어도 없어도 부팅 가능함 (WorldGuard 인식은 선택적)
- WorldGuard의 본격적인 활용(TEE 구현 등)은 본 기능의 범위를 벗어나며, 부팅 검증에만 집중함

## Out of Scope

- WorldGuard를 활용한 TEE (Trusted Execution Environment) 구현
- OpenSBI/U-Boot/Linux 커널에 WorldGuard 지원 코드 추가
- WorldGuard 성능 최적화 및 벤치마킹
- 다른 RISC-V 시뮬레이터(Spike 등)에 WorldGuard 통합
