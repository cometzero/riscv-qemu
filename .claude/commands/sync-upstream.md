# Sync Submodules to Latest Upstream

Rebase all submodules (sources/) to their latest upstream versions, rebuild, and verify boot.

## Workflow

### 1. Fetch and Rebase Submodules

For each submodule (qemu, opensbi, u-boot, linux, buildroot):

```bash
cd sources/<component>
git fetch upstream --tags
git rebase upstream/master  # or stable tag like v2026.01 for u-boot
```

**Notes**:
- U-Boot: Prefer stable release tags (e.g., `v2026.01`) over `upstream/master` to avoid build regressions
- If rebase conflicts with upstream commits, reset to tag and cherry-pick custom commits:
  ```bash
  git checkout <tag>
  git checkout -B feature/qemu_boot
  git cherry-pick <custom-commit-hash>
  ```

### 2. Update Defconfigs (U-Boot, Linux)

Clean source trees first if needed:
```bash
cd sources/u-boot && make mrproper
cd sources/linux && make ARCH=riscv mrproper
```

Then regenerate configs from existing .config:
```bash
# U-Boot
source scripts/env.sh
cd sources/u-boot
make CROSS_COMPILE=${CROSS_COMPILE} O="${UBOOT_BUILD}" olddefconfig
make CROSS_COMPILE=${CROSS_COMPILE} O="${UBOOT_BUILD}" savedefconfig
cp "${UBOOT_BUILD}/defconfig" configs/qemu_rv64_craft_defconfig

# Linux
cd sources/linux
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} O="${LINUX_BUILD}" olddefconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} O="${LINUX_BUILD}" savedefconfig
cp "${LINUX_BUILD}/defconfig" arch/riscv/configs/qemu_rv64_craft_defconfig
```

### 3. Build All Components

```bash
./scripts/build_all.sh
```

Or individually if debugging build issues:
```bash
./scripts/build_qemu.sh
./scripts/build_opensbi.sh
./scripts/build_uboot.sh
./scripts/build_linux.sh
./scripts/build_buildroot.sh
```

### 4. Verify Boot

```bash
timeout 120 ./scripts/run_qemu.sh
```

**Required milestones in boot log**:
1. `U-Boot SPL` - SPL started
2. `OpenSBI v` or `SBI specification` - OpenSBI initialized
3. `U-Boot 20` - U-Boot proper running
4. `Linux version` - Kernel booting
5. `buildroot login:` - Userspace ready (optional, requires longer timeout)

### 5. Commit Changes

**In submodules** (if defconfig changed):
```bash
cd sources/linux
git add arch/riscv/configs/qemu_rv64_craft_defconfig
git commit -s -m "configs(riscv): sync qemu_rv64_craft_defconfig with <version>"
```

**In parent repo** (submodule revisions):
```bash
git add sources/qemu sources/opensbi sources/u-boot sources/linux sources/buildroot
git commit -s -m "build: update submodules to latest upstream

- qemu: <version>
- opensbi: <version>
- u-boot: <version>
- linux: <version>
- buildroot: <version>

Boot test verified."
```

## Troubleshooting

### Build Failures After Upstream Rebase

1. Check build logs in `build/logs/<component>-*.log`
2. If header conflicts (e.g., lzma), use stable release tag instead of master
3. Clean build directory: `rm -rf build/<component>` and retry

### Rebase Conflicts

If upstream has conflicting changes with feature branch:
1. Abort rebase: `git rebase --abort`
2. Reset to stable tag: `git checkout <tag>`
3. Create fresh feature branch: `git checkout -B feature/qemu_boot`
4. Cherry-pick only custom commits from origin
