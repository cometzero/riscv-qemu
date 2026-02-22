# PREEMPT_RT + eBPF Enablement Guide

## 1) Goal

Enable PREEMPT_RT and core eBPF runtime support in the Linux kernel build, add eBPF user tools to rootfs, and provide reproducible runtime validation on QEMU.

## 2) Implementation Guide

### 2.1 Linux kernel configuration (PREEMPT_RT + eBPF)

- Added fragment: `configs/linux/rt_ebpf.fragment`
- Build integration: `scripts/build_linux.sh`
  - Merges fragment into `${LINUX_BUILD}/.config`
  - Runs `olddefconfig` to resolve dependencies

Key symbols:
- `CONFIG_PREEMPT_RT=y`
- `CONFIG_BPF=y`
- `CONFIG_BPF_SYSCALL=y`
- `CONFIG_BPF_JIT=y`
- `CONFIG_BPF_JIT_DEFAULT_ON=y`
- `CONFIG_CGROUP_BPF=y`
- `CONFIG_BPF_EVENTS=y`
- `CONFIG_NET_CLS_BPF=m`
- `CONFIG_NET_ACT_BPF=m`

### 2.2 Buildroot user-space eBPF tools

- Added fragment: `configs/buildroot/ebpf_tools.fragment`
- Updated base defconfig reference:
  - `configs/buildroot/qemu_riscv64_minimal.defconfig`
- Build integration: `scripts/build_buildroot.sh`
  - Merges fragment into `${ROOTFS_BUILD}/.config`
  - Runs `olddefconfig`

Installed tools:
- `bpftool`
- `iproute2` (`tc`, `ip`)
- `libbpf`

### 2.3 Runtime test path

- Added runtime harness: `test/run_rt_ebpf_test.py`
  - Boots guest with `scripts/run_qemu.sh`
  - Logs into Buildroot shell
  - Runs in-guest checks:
    - `uname -v | grep PREEMPT_RT`
    - `command -v bpftool`
    - `command -v tc`
    - `bpftool prog help`
    - `tc -V`
  - Saves logs/results under `build/test-logs/`

Overlay integration remains via existing worldguard pipeline:
- `scripts/build_worldguard_tests.sh` keeps `S99worldguard-test` in overlay

### 2.4 QEMU run path

- Updated `scripts/run_qemu.sh`
  - Default bootargs: `wgtest=off`
  - Default shell/login boot path remains unchanged

### 2.5 Runtime test artifacts

- `build/test-logs/rt-ebpf-test-<timestamp>.log`
- `build/test-logs/rt-ebpf-test-<timestamp>.result`

## 3) Execution Guide

## 3.1 Prerequisites

```bash
cd /build/risc-v/riscv-qemu
source scripts/env.sh
```

## 3.2 Build steps

```bash
./scripts/build_linux.sh
./scripts/build_worldguard_tests.sh
./scripts/build_buildroot.sh
```

## 3.3 Validation steps

### A. Normal boot smoke test (must reach shell/login)

```bash
python3 test/run_boot_test.py
```

Expected:
- Exit code `0`
- `build/test-logs/boot-test-*.result` contains all milestones

### B. PREEMPT_RT + eBPF runtime test

```bash
python3 test/run_rt_ebpf_test.py
```

Expected:
- Exit code `0`
- `build/test-logs/rt-ebpf-test-*.log` contains:
  - `[CHECK] PASS: preempt_rt`
  - `[CHECK] PASS: bpftool exists`
  - `[CHECK] PASS: tc exists`
  - `[CHECK] PASS: bpftool command`
  - `[CHECK] PASS: tc command`

## 4) Common failure modes

| Symptom | Likely Cause | Action |
|---|---|---|
| `[CHECK] FAIL: preempt_rt` | Kernel fragment not applied | Re-run `./scripts/build_linux.sh`, then verify `CONFIG_PREEMPT_RT=y` |
| `[CHECK] FAIL: bpftool command` | Missing runtime libs for bpftool | Rebuild rootfs with `./scripts/build_buildroot.sh --clean --defconfig` |
| `[CHECK] FAIL: tc command` | iproute2 not installed correctly | Re-run `./scripts/build_buildroot.sh` and verify rootfs packages |
| Boot test fails before login | General boot regression | Run `python3 test/run_boot_test.py`, inspect latest `boot-test-*.log` |

## 5) Quick command summary

```bash
source scripts/env.sh
./scripts/build_linux.sh
./scripts/build_worldguard_tests.sh
./scripts/build_buildroot.sh
python3 test/run_boot_test.py
python3 test/run_rt_ebpf_test.py
```
