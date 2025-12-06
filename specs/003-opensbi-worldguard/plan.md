# Implementation Plan: OpenSBI WorldGuard Support

**Feature Branch**: `003-opensbi-worldguard`  
**Spec**: [spec.md](./spec.md)  
**Created**: 2025-12-06

## Overview

OpenSBI에 WorldGuard 지원을 추가합니다. 두 단계로 구현:
- **Phase 1**: 하드코딩된 테스트 코드로 기본 동작 검증
- **Phase 2**: Device Tree 기반 유연한 설정

## Technical Context

| Item | Value |
|------|-------|
| OpenSBI Version | v1.7 |
| CSR Read/Write | `csr_read()`/`csr_write()` in `sbi/riscv_asm.h` |
| Init Entry Point | `init_coldboot()` in `lib/sbi/sbi_init.c` |
| FDT Parser | `lib/utils/fdt/fdt_helper.c` |
| CSR Addresses | mlwid=0x390, slwid=0x190, mwiddeleg=0x748 |

---

## Proposed Changes

### Phase 1: 하드코딩 테스트 (Priority: P1)

#### [NEW] include/sbi/riscv_worldguard.h

WorldGuard CSR 정의:
```c
#define CSR_MLWID       0x390
#define CSR_SLWID       0x190  
#define CSR_MWIDDELEG   0x748
```

---

#### [NEW] lib/sbi/sbi_worldguard.c

WorldGuard 초기화 모듈:
- `sbi_worldguard_init()`: CSR 초기화 (mlwid=3, slwid=2, mwiddeleg=0x6)
- `sbi_worldguard_enabled()`: WorldGuard 활성화 상태 조회

---

#### [MODIFY] lib/sbi/sbi_init.c

`init_coldboot()` 함수에서 WorldGuard 초기화 호출:
```c
rc = sbi_worldguard_init(scratch, cold_hartid);
// 실패해도 부팅 계속 (silent skip)
```

---

#### [MODIFY] lib/sbi/objects.mk

새 소스 파일 추가:
```makefile
libsbi-objs-y += sbi_worldguard.o
```

---

### Phase 2: Device Tree 통합 (Priority: P2)

#### [MODIFY] lib/sbi/sbi_worldguard.c

FDT 파싱 추가:
- `riscv,worldguard` 노드 검색
- `nworlds`, `trustedwid`, `wid-assignment` 속성 읽기
- DT 노드 없으면 silent skip

---

#### [NEW] sources/worldguard.dts

WorldGuard Device Tree 노드 예시:
```dts
worldguard: worldguard@6000000 {
    compatible = "riscv,worldguard";
    nworlds = <4>;
    trustedwid = <3>;
    
    wgchecker@6000000 {
        compatible = "riscv,wgchecker";
        reg = <0x6000000 0x1000>;
        slots = <0x80000000 0x20000000 0xFF>,  /* slot 1: shared */
                <0xA0000000 0x10000000 0xC0>,  /* slot 2: W3 only */
                ...;
    };
};
```

---

### Phase 3: wgChecker MMIO 프로그래밍 (Priority: P3)

#### [MODIFY] lib/sbi/sbi_worldguard.c

wgChecker 슬롯 프로그래밍:
- DT에서 `slots = <addr size perm>` 배열 파싱
- wgChecker MMIO (0x6000000)에 슬롯 쓰기
- Lock 비트 설정으로 S-mode 수정 방지

---

## Verification Plan

### Test 1: Phase 1 빌드 검증

**Type**: Build Test  
**Command**:
```bash
cd sources/opensbi
make PLATFORM=generic CROSS_COMPILE=riscv64-linux-gnu- clean
make PLATFORM=generic CROSS_COMPILE=riscv64-linux-gnu-
```
**Expected**: 빌드 성공, `platform/generic/firmware/fw_dynamic.bin` 생성

---

### Test 2: WorldGuard 초기화 로그 확인

**Type**: QEMU Boot Test  
**Command**:
```bash
./build/qemu/qemu-system-riscv64 \
    -M virt,wg=on,wg-nworlds=4,wg-trustedwid=3 \
    -m 2G -smp 1 -nographic \
    -bios sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
    -kernel ./build/u-boot/u-boot.bin
```
**Expected**: OpenSBI 로그에 `WorldGuard: enabled, mlwid=3, slwid=2` 출력

---

### Test 3: WorldGuard 비활성화 호환성

**Type**: QEMU Boot Test  
**Command**:
```bash
./build/qemu/qemu-system-riscv64 \
    -M virt \
    -m 2G -smp 1 -nographic \
    -bios sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
    -kernel ./build/u-boot/u-boot.bin
```
**Expected**: WorldGuard 관련 로그 없이 정상 부팅

---

### Test 4: 전체 부트 체인 검증

**Type**: Full Boot Test  
**Command**:
```bash
./scripts/run-qemu-worldguard.sh
```
**Expected**: OpenSBI → U-Boot → Linux → Buildroot 로그인까지 성공

---

## Implementation Order

| Step | Task | Files | Est. Time |
|------|------|-------|-----------|
| 1 | CSR 헤더 추가 | `riscv_worldguard.h` | 30min |
| 2 | 초기화 모듈 작성 | `sbi_worldguard.c` | 2h |
| 3 | Init 훅 추가 | `sbi_init.c` | 30min |
| 4 | 빌드 시스템 수정 | `objects.mk` | 15min |
| 5 | 빌드 및 테스트 1-3 | - | 1h |
| 6 | DT 파싱 추가 | `sbi_worldguard.c` | 3h |
| 7 | 예시 DTS 작성 | `worldguard.dts` | 1h |
| 8 | wgChecker 프로그래밍 | `sbi_worldguard.c` | 3h |
| 9 | 최종 통합 테스트 | - | 2h |

**Total Estimated Time**: ~13 hours

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| CSR 접근 trap | Try-catch 패턴으로 안전하게 감지 |
| OpenSBI 구조 변경 | v1.7 API만 사용, 최소 침습적 수정 |
| DT 파싱 오류 | 모든 속성에 기본값 제공 |
| 하위 호환성 | WorldGuard 없이도 기존 동작 보장 |

---

## Dependencies

- ✅ `002-qemu-worldguard`: QEMU WorldGuard 통합 완료
- ⬜ OpenSBI v1.7 소스 (`sources/opensbi/`)
- ⬜ QEMU DTB dump 도구 (`dtc`)
