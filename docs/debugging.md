# Debugging Guide for RISC-V QEMU Boot Flow

## Overview

This guide explains how to debug the boot flow (U-Boot SPL → OpenSBI → U-Boot Proper → Linux Kernel) on QEMU using GDB.

## Prerequisites

- Built artifacts (`./scripts/build_all.sh`)
- `gdb-multiarch` installed
- `qemu-system-riscv64` installed

## Quick Start

### 1. Start QEMU in Debug Mode
The `--debug` flag starts QEMU in a "frozen" state (`-S`) and opens a GDB stub on port 1234 (`-s`).

```bash
# Standard Boot
./scripts/run_qemu.sh --debug

# OP-TEE Boot
./scripts/run_qemu.sh --optee --debug
```

QEMU will hang and wait for a GDB connection.

### 2. Connect with GDB
Use the provided GDB script to automatically load symbols for all boot stages.

```bash
gdb-multiarch -x scripts/debug.gdb
```

This script:
1. Connects to `localhost:1234`.
2. Loads symbols for SPL, OpenSBI, U-Boot, OP-TEE, and Linux.
3. Disables pagination for smoother automation.

### 3. Debugging Session
Once connected, you can set breakpoints and continue execution.

**Example Session:**

```gdb
# Break at Linux kernel start
(gdb) b start_kernel
Breakpoint 1 at 0xffffffff80c00716: file init/main.c, line 1005.

# Continue boot until breakpoint
(gdb) c

# Inspect variables
(gdb) print command_line
$1 = 0xffffffff80c00740 "earlycon=sbi console=ttyS0 ..."

# Step through source
(gdb) n
(gdb) list
```

## Component Details

### U-Boot SPL
- **Address**: `0x80000000` (Base of DRAM)
- **Symbol File**: `build/u-boot/spl/u-boot-spl`
- **Key Function**: `board_init_f`

### OpenSBI
- **Address**: Loaded by SPL (typically `0x80200000` or determined by FIT)
- **Symbol File**: `build/opensbi/platform/generic/firmware/fw_dynamic.elf`
- **Note**: `fw_dynamic` is position-independent. GDB symbols load at 0x0 by default. You may need to use `add-symbol-file ... <load_address>` if breakpoints don't hit.

### U-Boot Proper
- **Address**: Relocated to RAM (address varies, check map file or `bdinfo`)
- **Symbol File**: `build/u-boot/u-boot`
- **Key Function**: `board_init_f`, `board_init_r`
- **Relocation**: U-Boot moves itself to the top of RAM. Symbols must be reloaded to debug post-relocation code.
    - **Command**: `uboot_reloc`
    - **Usage**:
        1. Run `break_uboot_proper` (this sets breakpoints at `board_init_f` and `relocate_code`).
        2. `continue`. You will first hit `board_init_f` (Pre-Relocation).
        3. `continue` again. You will hit `relocate_code`.
        4. Run `uboot_reloc`. Scripts will re-load symbols for post-relocation.
        5. You can now break at `board_init_r` and continue debugging in high memory.

### Linux Kernel
- **Address**: Virtual Address (High Mem), managed by MMU setup in `head.S`
- **Symbol File**: `build/linux/vmlinux`
- **Config**: Ensure `CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT=y` is set (Done by default in this project).

## Troubleshooting

### "Remote 'g' packet reply is too long"
This is a known issue when switching modes (e.g., typically 32-bit to 64-bit or CSR changes).
**Fix**: Reset authentication or reconnect GDB.
```gdb
(gdb) set architecture riscv:rv64
```

### Source Code Not Found
Ensure you are running GDB from the project root (`miles-qemu/`). GDB looks for source files relative to the compilation directory.

## VS Code / IDE Debugging

This project includes configuration files for debugging directly within VS Code (or compatible editors like Antigravity).

### Setup
1.  Ensure the "C/C++" extension is installed.
2.  Open the project root in the editor.

### Debugging Steps
1.  **Start QEMU**: Run the Task **"Launch QEMU (Debug Mode)"**.
    *   Command Palette (`Ctrl+Shift+P`) -> `Tasks: Run Task` -> `Launch QEMU (Debug Mode)`
    *   This starts QEMU in the background, paused and waiting for GDB.

2.  **Start Debugger**: Run the Launch Configuration **"(gdb) Attach to QEMU"**.
    *   Press `F5` or go to the Run and Debug sidebar and click the play button.
    *   This connects GDB, loads all symbols (via `scripts/debug.gdb`), and pauses at `_start` (SPL entry).

### U-Boot Relocation in IDE
To handle U-Boot relocation within the IDE:
1.  In the **Debug Console** (bottom panel), you can type GDB commands directly (prefix with `-exec` if needed, but the console often accepts them directly).
2.  **Workflow**:
    *   Use the generic **Breakpoints** view to manage standard breakpoints.
    *   For the relocation step:
        *   Execute `-exec break_uboot_proper` in the Debug Console.
        *   Resume (`F5`) until hit.
        *   Execute `-exec uboot_reloc` in the Debug Console.
        *   Set breakpoint at `board_init_r`.
        *   Resume (`F5`).
