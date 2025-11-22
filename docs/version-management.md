# Version Management Guide

This project uses Git submodules to manage dependencies (QEMU, U-Boot, Linux, OpenSBI, Buildroot). This ensures reproducibility by locking each component to a specific commit.

## Submodule Status

To check the status of submodules:
```bash
git submodule status
```

## Updating Submodules

To update a submodule to a newer version (e.g., `u-boot`):

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

## Pinning Versions

It is recommended to pin submodules to stable release tags (e.g., `v2025.01`) rather than moving branches (e.g., `master`) to avoid instability.
