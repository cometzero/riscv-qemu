#!/bin/bash
# Generate modified DTB with OpenSBI OP-TEE domain configuration
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

DTS_DIR="${BUILD_DIR}/dts"
mkdir -p "${DTS_DIR}"

# Step 1: Generate base DTB from QEMU
echo "Generating base DTB from QEMU virt..."
${QEMU_SRC}/build/qemu-system-riscv64 \
    -M virt,dumpdtb="${DTS_DIR}/virt-base.dtb" \
    -m 4G \
    -smp 2 \
    2>/dev/null

# Step 2: Convert to DTS
echo "Converting DTB to DTS..."
dtc -I dtb -O dts "${DTS_DIR}/virt-base.dtb" > "${DTS_DIR}/virt-base.dts" 2>/dev/null

# Step 3: Add opensbi-domains to chosen node
echo "Adding OpenSBI domain configuration for OP-TEE..."

# Find the line number of "chosen {" and insert domains before closing brace
awk '
/chosen \{/ {
    in_chosen = 1
    print
    next
}
in_chosen && /^\t};$/ {
    # Insert opensbi-domains before closing brace of chosen
    print ""
    print "\t\topensbi-domains {"
    print "\t\t\tcompatible = \"opensbi,domain,config\";"
    print ""
    print "\t\t\t/* OP-TEE secure memory: 16 MiB at 0xF1000000 */"
    print "\t\t\toptee_mem: optee-mem {"
    print "\t\t\t\tcompatible = \"opensbi,domain,memregion\";"
    print "\t\t\t\tbase = <0x0 0xF1000000>;"
    print "\t\t\t\torder = <24>;"
    print "\t\t\t};"
    print ""
    print "\t\t\t/* Shared memory: 2 MiB at 0xF2000000 */"
    print "\t\t\tshmem: shared-mem {"
    print "\t\t\t\tcompatible = \"opensbi,domain,memregion\";"
    print "\t\t\t\tbase = <0x0 0xF2000000>;"
    print "\t\t\t\torder = <21>;"
    print "\t\t\t};"
    print ""
    print "\t\t\t/* Full memory for normal world */"
    print "\t\t\tallmem: all-mem {"
    print "\t\t\t\tcompatible = \"opensbi,domain,memregion\";"
    print "\t\t\t\tbase = <0x0 0x0>;"
    print "\t\t\t\torder = <64>;"
    print "\t\t\t};"
    print ""
    print "\t\t\t/* OP-TEE domain (TEE) */"
    print "\t\t\toptee_domain: optee-domain {"
    print "\t\t\t\tcompatible = \"opensbi,domain,instance\";"
    print "\t\t\t\tpossible-harts = <&cpu0>;"
    print "\t\t\t\tregions = <&optee_mem 0x3f>, <&shmem 0x3f>;"
    print "\t\t\t\tboot-hart = <&cpu0>;"
    print "\t\t\t\tnext-arg1 = <0x0 0x0>;"
    print "\t\t\t\tnext-addr = <0x0 0xF1000000>;"
    print "\t\t\t\tnext-mode = <0x1>;"
    print "\t\t\t};"
    print ""
    print "\t\t\t/* Linux domain (REE) - assigned by default */"
    print "\t\t\tlinux_domain: linux-domain {"
    print "\t\t\t\tcompatible = \"opensbi,domain,instance\";"
    print "\t\t\t\tpossible-harts = <&cpu0 &cpu1>;"
    print "\t\t\t\tregions = <&optee_mem 0x0>, <&shmem 0x3f>, <&allmem 0x3f>;"
    print "\t\t\t\tsystem-reset-allowed;"
    print "\t\t\t\tsystem-suspend-allowed;"
    print "\t\t\t};"
    print "\t\t};"
    in_chosen = 0
}
{ print }
' "${DTS_DIR}/virt-base.dts" > "${DTS_DIR}/virt-optee.dts"

# Step 4: Add cpu labels
# Replace "cpu@0 {" with "cpu0: cpu@0 {" and "cpu@1 {" with "cpu1: cpu@1 {"
sed -i 's/cpu@0 {/cpu0: cpu@0 {/' "${DTS_DIR}/virt-optee.dts"
sed -i 's/cpu@1 {/cpu1: cpu@1 {/' "${DTS_DIR}/virt-optee.dts"

# Step 5: Add opensbi-domain property to CPU nodes
# HART 0 -> optee-domain (primary TEE core)
# HART 1 -> linux-domain (REE core)
# Insert after "cpu0: cpu@0 {" line
sed -i '/cpu0: cpu@0 {/a\                        opensbi-domain = <\&optee_domain>;' "${DTS_DIR}/virt-optee.dts"
sed -i '/cpu1: cpu@1 {/a\                        opensbi-domain = <\&linux_domain>;' "${DTS_DIR}/virt-optee.dts"

# Step 6: Compile back to DTB
echo "Compiling modified DTB..."
dtc -I dts -O dtb "${DTS_DIR}/virt-optee.dts" -o "${DTS_DIR}/virt-optee.dtb" 2>/dev/null

echo "Done! Modified DTB: ${DTS_DIR}/virt-optee.dtb"
ls -la "${DTS_DIR}/virt-optee.dtb"
