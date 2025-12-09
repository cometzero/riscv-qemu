# Quick Start: OP-TEE Boot Flow

**Feature**: 002-optee-bootflow

## Prerequisites

Same as base project, plus:
- OP-TEE sources cloned
- Patches extracted and applied

## Build OP-TEE Boot Flow

### Option 1: Full Build (Recommended)

```bash
# Build all components with OP-TEE support
./scripts/build_all.sh --optee
```

### Option 2: Component-by-Component

```bash
# 1. Build OP-TEE OS
./scripts/build_optee.sh

# 2. Build OpenSBI with OP-TEE SPD
./scripts/build_opensbi.sh --optee

# 3. Build Linux with TEE driver
./scripts/build_linux.sh --optee

# 4. Build Buildroot with xtest
./scripts/build_buildroot.sh --optee

# 5. Build U-Boot (may not need changes)
./scripts/build_uboot.sh
```

## Run with OP-TEE

```bash
# Boot QEMU with OP-TEE enabled
./scripts/run_qemu.sh --optee
```

Expected output shows:
1. U-Boot SPL starting
2. OpenSBI with OP-TEE/SPD messages
3. U-Boot proper
4. Linux kernel with TEE driver init
5. Buildroot login prompt

## Verify OP-TEE

After login (user: `root`, no password):

```bash
# Check TEE devices exist
ls -la /dev/tee*
# Expected: /dev/tee0 and /dev/teepriv0

# Run hello world example
optee_example_hello_world
# Expected: "Hello World!" from Trusted Application

# Run test suite
xtest
# Expected: ~80% pass rate on core tests
```

## Troubleshooting

### No /dev/tee0 device

1. Check kernel config: `zcat /proc/config.gz | grep OPTEE`
2. Check dmesg: `dmesg | grep -i optee`
3. Verify OpenSBI loaded OP-TEE: check early boot log for SPD messages

### xtest failures

Many tests may fail on RISC-V due to ongoing port:
- Focus on categories 1-6 (core tests)
- 80% pass rate is acceptable for initial port
- Document known failures for tracking

### OP-TEE init fails

1. Check OpenSBI log for PMP configuration
2. Verify memory regions don't overlap
3. Check OP-TEE build log for platform config

## Switching Between Modes

```bash
# Boot WITHOUT OP-TEE (default)
./scripts/run_qemu.sh

# Boot WITH OP-TEE
./scripts/run_qemu.sh --optee
```

Both modes should work independently.
