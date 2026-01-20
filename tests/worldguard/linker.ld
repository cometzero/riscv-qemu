/*
 * Linker Script for RISC-V WorldGuard Bare-metal Test
 *
 * Memory layout for QEMU virt machine with WorldGuard:
 * - 0x80000000: ROM/Text (loaded here by QEMU -bios)
 * - 0x80010000: Data/BSS
 * - 0x90000000: Stack (top, grows down)
 */

OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    /* Text in first 64KB */
    ROM (rx)  : ORIGIN = 0x80000000, LENGTH = 64K
    /* Data/BSS in next area */
    RAM (rwx) : ORIGIN = 0x80010000, LENGTH = 256K
}

SECTIONS
{
    /* Code section */
    .text : {
        *(.text.start)
        *(.text .text.*)
    } > ROM

    /* Read-only data */
    .rodata : {
        *(.rodata .rodata.*)
    } > ROM

    /* Data section */
    .data : {
        *(.data .data.*)
        *(.sdata .sdata.*)
    } > RAM

    /* BSS section */
    .bss : {
        __bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        __bss_end = .;
    } > RAM

    /* Discard unwanted sections */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
        *(.note.*)
    }
}
