# RISC-V QEMU GDB Debug Script
# Usage: gdb-multiarch -x scripts/debug.gdb

# Connect to QEMU
# Connect to QEMU via environment or CLI arguments
# target remote :1234  <-- Removed to support IDE integration (launch.json handles connection)


# 1. SPL (Initial Boot)
# Running at 0x80000000
file build/u-boot/spl/u-boot-spl

# 2. OpenSBI
add-symbol-file build/opensbi/platform/generic/firmware/fw_dynamic.elf

# 3. U-Boot Proper (Initial Load Address)
add-symbol-file build/u-boot/u-boot

# 4. Linux Kernel
add-symbol-file build/linux/vmlinux

# Initial setup
set pagination off
set confirm off

# Helper functions
define reset
    monitor system_reset
end

# Python extension for U-Boot Relocation
python
import gdb

class UBootReloc(gdb.Command):
    """
    Load U-Boot proper symbols calculated from gd->relocaddr.
    Usage: uboot_reloc
    
    This command:
    1. Loads U-Boot Proper symbols to ensure types are available.
    2. Reads gd->relocaddr from the $gp register (RISC-V).
    3. Reloads U-Boot symbols at the relocated address.
    """
    def __init__(self):
        super(UBootReloc, self).__init__("uboot_reloc", gdb.COMMAND_USER)

    def invoke(self, arg, from_tty):
        print("[uboot_reloc] Checking environment...")
        
        try:
            # 1. Check if we are likely in SPL (low address) or U-Boot Proper
            pc = gdb.parse_and_eval("$pc")
            if pc < 0x80200000:
                print(f"Warning: PC ({pc}) is in low memory (SPL range).")
                print("You typically need to be in U-Boot Proper (common/board_r.c) to use this.")
            
            # 2. Get GD
            gp = gdb.parse_and_eval("$gp")
            if gp == 0:
                 print("Error: $gp register is 0. Global Data not initialized?")
                 return

            # Lookup struct global_data
            try:
                gd_type = gdb.lookup_type("struct global_data").pointer()
            except:
                print("Error: Could not find 'struct global_data'. Loading symbol file to fix types...")
                gdb.execute("symbol-file build/u-boot/u-boot")
                gd_type = gdb.lookup_type("struct global_data").pointer()

            gd = gp.cast(gd_type)
            
            # Read relocaddr safe
            try:
                relocaddr = gd['relocaddr']
            except gdb.MemoryError:
                print(f"Error: Cannot access memory at $gp ({gp}).")
                print("Are you running in a valid U-Boot Proper context?")
                return

            print(f"[uboot_reloc] Detected gd->relocaddr: {relocaddr}")
            
            # Fallback for relocation address if gd->relocaddr is 0
            if relocaddr == 0:
                print("Warning: gd->relocaddr is 0. Trying registers...")
                # In start.S, relocate_code(a0, a1, a2=dest)
                # If we are at the start of relocate_code, a2 might hold it
                try:
                    r_a2 = gdb.parse_and_eval("$a2")
                    print(f"Debug: $a2 = {r_a2}")
                    if r_a2 > 0x80000000:
                        relocaddr = int(r_a2)
                        print(f"[uboot_reloc] Using $a2 as relocaddr: {hex(relocaddr)}")
                except:
                    pass

            if relocaddr == 0:
                 # Check s4 (saved a2)
                 try:
                    r_s4 = gdb.parse_and_eval("$s4")
                    print(f"Debug: $s4 = {r_s4}")
                    if r_s4 > 0x80000000:
                        relocaddr = int(r_s4)
                        print(f"[uboot_reloc] Using $s4 as relocaddr: {hex(relocaddr)}")
                 except:
                    pass

            if relocaddr == 0:
                print("Error: Could not determine relocation address.")
                print("Tip: Break at 'relocate_code', ensuring you are in U-Boot Proper.")
                return
            
            # 3. Reload symbols
            gdb.execute("symbol-file") # Clear all symbols
            cmd = f"add-symbol-file build/u-boot/u-boot {hex(relocaddr)}"
            print(f"[uboot_reloc] Executing: {cmd}")
            gdb.execute(cmd)
            
            # Re-load other useful symbols
            print("[uboot_reloc] Re-loading OpenSBI and Linux symbols...")
            gdb.execute("add-symbol-file build/opensbi/platform/generic/firmware/fw_dynamic.elf")
            gdb.execute("add-symbol-file build/linux/vmlinux")
            
            print("[uboot_reloc] Done. You can now break at 'board_init_r'.")

        except Exception as e:
            print(f"Error during relocation symbol load: {e}")

UBootReloc()
end

# Helper to break safely at U-Boot Proper
# Helper to break safely at U-Boot Proper
define break_uboot_proper
    # Break at Pre-Relocation Init
    break common/board_f.c:board_init_f
    # Break at Relocation Point
    break relocate_code
    
    echo Breakpoints set at 'board_init_f' and 'relocate_code'.\n
    echo 1. Continue until 'board_init_f' (Pre-Reloc).\n
    echo 2. Continue again to reach 'relocate_code'.\n
    echo 3. Then run 'uboot_reloc' and continue to 'board_init_r'.\n
end

echo \n=== Debugging Configured ===\n
echo Symbols loaded for:\n
echo  - SPL (0x80000000)\n
echo  - OpenSBI\n
echo  - U-Boot Proper\n
echo  - Linux Kernel\n
echo \n
echo New Command: uboot_reloc\n
echo  Use this command after U-Boot relocation to fix symbol addresses.\n
echo \n


# Automate initial breakpoint
break _start

echo \n=== Debugging Configured ===\n
echo Symbols loaded. Debugger ready.\n
echo \n
echo Press Continue (F5) to reach SPL entry ('_start').
echo \n
