# Version Management Guide

This project uses Git submodules to manage dependencies (QEMU, U-Boot, Linux, OpenSBI, Buildroot). This ensures reproducibility by locking each component to a specific commit.

## Submodule Status

To check the status of submodules:
```bash
git submodule status
```

## Automated Update Scripts

The project provides automated scripts for updating submodules to the latest stable versions:

### Update All Components

```bash
# Update all submodules to latest stable tags
./scripts/update-sources.sh

# Preview changes without modifying (dry-run)
./scripts/update-sources.sh --dry-run

# Update a specific component only
./scripts/update-sources.sh --component qemu
```

### Individual Component Updates

Each component has its own update script that can be run independently:

| Script | Description |
|--------|-------------|
| `scripts/update-qemu.sh` | Updates QEMU to latest stable tag (vX.Y.Z) |
| `scripts/update-uboot.sh` | Updates U-Boot to latest stable tag (v20XX.XX) |
| `scripts/update-opensbi.sh` | Updates OpenSBI to latest stable tag (vX.Y) |
| `scripts/update-linux.sh` | Updates Linux Kernel to latest stable tag (vX.Y.Z) |
| `scripts/update-buildroot.sh` | Updates Buildroot to latest stable tag (20XX.XX) |

To update to a specific version:
```bash
./scripts/update-qemu.sh --tag v9.0.0
./scripts/update-uboot.sh --tag v2024.10
```

## Manual Update Process

To update a submodule manually (e.g., `u-boot`):

1.  **Enter the submodule directory**:
    ```bash
    cd sources/u-boot
    ```

2.  **Fetch and checkout**:
    ```bash
    git fetch origin
    git checkout <tag_or_branch>
    ```

3.  **Commit the change in the main repository**:
    ```bash
    cd ../..
    git add sources/u-boot
    git commit -m "Update U-Boot to version <version>"
    ```

## Rebuilding After Updates

After updating a submodule, you must rebuild the affected component.
Use the incremental rebuild scripts:

- `scripts/rebuild-uboot.sh`
- `scripts/rebuild-linux.sh`
- `scripts/rebuild-opensbi.sh`
- `scripts/rebuild-buildroot.sh`
- `scripts/build-qemu.sh` (QEMU usually requires a full build/install)

Or rebuild everything with:
```bash
./scripts/build-all.sh
```

## Version History

Update history is automatically recorded in `docs/version-history.md` when using `update-sources.sh`.

## Pinning Versions

It is recommended to pin submodules to stable release tags (e.g., `v2025.01`) rather than moving branches (e.g., `master`) to avoid instability.

