# Research: OP-TEE Boot Flow Support

**Feature**: 002-optee-bootflow  
**Date**: 2025-12-09

## RISE Project Patch Analysis

### Source Repositories

RISE project maintains forked repositories with RISC-V OP-TEE support:

| Component | RISE Repository | Target Branch |
|-----------|-----------------|---------------|
| OP-TEE OS | `gitlab.com/riseproject/riscv-optee/optee_os.git` | `dev-optee-mpxy-v5` |
| OpenSBI | `gitlab.com/riseproject/riscv-optee/opensbi.git` | `dev-optee-mpxy-v5` |
| Linux | `gitlab.com/riseproject/riscv-optee/linux.git` | `dev-optee-mpxy-v5` |
| U-Boot | `gitlab.com/riseproject/riscv-optee/u-boot.git` | `dev-optee-mpxy-v5` |
| Buildroot | `gitlab.com/riseproject/riscv-optee/buildroot.git` | `dev-optee-mpxy-v5` |

### Patch Extraction Strategy

**Decision**: Extract patches from RISE branches and rebase on upstream latest.

**Rationale**: 
- Upstream receives security fixes that RISE forks may lag behind on
- Easier to track which changes are OP-TEE-specific vs upstream updates
- Aligns with constitution principle of minimal local patches

**Process**:
1. Clone RISE fork alongside upstream
2. Use `git format-patch` to extract OP-TEE-specific commits
3. Apply patches on upstream latest with `git am`
4. Resolve conflicts if any, document resolutions

---

## OP-TEE OS Build Research

### Platform Support

OP-TEE OS supports RISC-V QEMU virt platform via RISE patches.

**Build Configuration**:
```makefile
PLATFORM = virt
ARCH = riscv
CROSS_COMPILE = riscv64-linux-gnu-
CFG_TEE_CORE_LOG_LEVEL = 3
```

### Build Output

| File | Purpose |
|------|---------|
| `tee.bin` | OP-TEE OS binary loaded by OpenSBI |
| `tee.elf` | ELF format for debugging |

### Memory Requirements

- **OP-TEE Core**: 16 MiB at 0xF100_0000
- **Shared Memory**: 2 MiB at 0xF200_0000

---

## OpenSBI SPD Integration

### Secure Payload Dispatcher (SPD)

OpenSBI's domain support enables running OP-TEE as a secure payload.

**Key Features**:
- Domain isolation using PMP (Physical Memory Protection)
- Context switching between S-mode (Linux) and OP-TEE
- SBI calls forwarded to appropriate domain

### Configuration

```makefile
PLATFORM = generic
FW_PAYLOAD_PATH = /path/to/tee.bin
# Domain configuration via device tree
```

### Required Patches

1. **MPXY (Message Proxy)**: Communication between domains
2. **RPMI**: RISC-V Platform Management Interface
3. **Domain Context Switch**: Save/restore hart context

---

## Linux TEE Driver

### Driver Components

| Driver | Purpose |
|--------|---------|
| `tee` | Generic TEE subsystem |
| `optee` | OP-TEE specific driver |

### Kernel Configuration

```kconfig
CONFIG_TEE=y
CONFIG_OPTEE=y
CONFIG_OPTEE_SHM_NUM_PRIV_PAGES=1
```

### Device Tree

TEE node required in device tree:
```dts
optee {
    compatible = "linaro,optee-tz";
    method = "smc";
};
```

For RISC-V, method may be different (SBI-based).

---

## Buildroot Integration

### Required Packages

| Package | Purpose |
|---------|---------|
| `optee-client` | TEE userspace library |
| `optee-test` (xtest) | OP-TEE test suite |
| `optee-examples` | Sample Trusted Applications |

### Configuration

```kconfig
BR2_PACKAGE_OPTEE_CLIENT=y
BR2_PACKAGE_OPTEE_TEST=y
BR2_PACKAGE_OPTEE_EXAMPLES=y
```

---

## PMP Configuration

### Memory Isolation

RISC-V uses PMP for hardware memory isolation:

| Region | Access | Purpose |
|--------|--------|---------|
| OP-TEE (0xF100_0000) | Secure only | TEE code and data |
| Shared (0xF200_0000) | Both | Communication buffer |
| Linux (0x8000_0000+) | Non-secure | Normal world |

### PMP Requirements

- Minimum 8 PMP regions for basic isolation
- QEMU virt provides 16 PMP regions (sufficient)

---

## Alternatives Considered

### Alternative 1: Use RISE Forks Directly

**Rejected because**:
- Forks may lag behind upstream security fixes
- Harder to track OP-TEE-specific changes
- Submodule updates become complex

### Alternative 2: Wait for Upstream

**Rejected because**:
- RISC-V OP-TEE upstreaming is ongoing (TBD timeline)
- Need functional system now for development

### Alternative 3: Different TEE Implementation

**Rejected because**:
- OP-TEE is the de-facto standard for open-source TEE
- Best community support and documentation
- GlobalPlatform compliant

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Patch conflicts on rebase | Medium | Medium | Document resolutions, test incrementally |
| xtest failures on RISC-V | High | Low | Expect 80% pass rate, track known failures |
| PMP region exhaustion | Low | High | Verify QEMU virt has sufficient regions |
| Performance regression | Medium | Low | Not a goal; focus on correctness |
