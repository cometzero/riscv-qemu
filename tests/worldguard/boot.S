/*
 * RISC-V WorldGuard Bare-metal Test - Boot Code
 *
 * Entry point for M-mode execution on QEMU virt machine.
 * Sets up stack and jumps to C main().
 */

.section .text.start
.global _start

_start:
    /* Disable interrupts */
    csrw    mie, zero
    csrw    mip, zero

    /* Set up stack pointer */
    /* Stack at end of first 256MB (shared region) */
    li      sp, 0x90000000

    /* Clear BSS section */
    la      a0, __bss_start
    la      a1, __bss_end
1:
    bgeu    a0, a1, 2f
    sd      zero, 0(a0)
    addi    a0, a0, 8
    j       1b
2:

    /* Set up trap handler */
    la      t0, trap_handler
    csrw    mtvec, t0

    /* Jump to C main */
    call    main

    /* If main returns, halt */
    j       halt

.global halt
halt:
    /* Write to SiFive Test device to poweroff */
    li      t0, 0x100000
    li      t1, 0x5555      /* FINISHER_PASS */
    sw      t1, 0(t0)
1:
    wfi
    j       1b

/*
 * Trap handler - simple handler for testing access faults
 */
.align 4
.global trap_handler
trap_handler:
    /* Save registers we'll use */
    addi    sp, sp, -32
    sd      ra, 0(sp)
    sd      t0, 8(sp)
    sd      t1, 16(sp)
    sd      t2, 24(sp)

    /* Read mcause */
    csrr    t0, mcause

    /* Check if it's an access fault (5=load, 7=store) */
    li      t1, 5   /* Load access fault */
    beq     t0, t1, handle_access_fault
    li      t1, 7   /* Store access fault */
    beq     t0, t1, handle_access_fault

    /* Unknown trap - halt */
    j       trap_halt

handle_access_fault:
    /* Set global flag that fault occurred */
    la      t0, g_fault_occurred
    li      t1, 1
    sw      t1, 0(t0)

    /* Read mepc and skip the faulting instruction */
    csrr    t0, mepc

    /* Check if it's a compressed instruction (lowest 2 bits != 0b11) */
    lh      t1, 0(t0)
    andi    t2, t1, 0x3
    li      t1, 0x3
    beq     t2, t1, skip_4byte
    /* Compressed instruction - skip 2 bytes */
    addi    t0, t0, 2
    j       skip_done
skip_4byte:
    /* Normal instruction - skip 4 bytes */
    addi    t0, t0, 4
skip_done:
    csrw    mepc, t0

    /* Restore registers and return */
    ld      ra, 0(sp)
    ld      t0, 8(sp)
    ld      t1, 16(sp)
    ld      t2, 24(sp)
    addi    sp, sp, 32
    mret

trap_halt:
    /* Print trap info and halt */
    csrr    a0, mcause
    csrr    a1, mepc
    csrr    a2, mtval
    call    print_trap_info
    j       halt

.section .data
.global g_fault_occurred
g_fault_occurred:
    .word   0

.section .bss
.align 4
__bss_start:
    .space  4096
__bss_end:
