# +FHDR------------------------------------------------------------------------
# Copyright ownership belongs to CAG laboratory, Institute of Artificial
# Intelligence and Robotics, Xi'an Jiaotong University, shall not be used in
# commercial ways without permission.
# -----------------------------------------------------------------------------
# FILE NAME  : _init.s
# DEPARTMENT : CAG of IAIR
# AUTHOR     : XXXX
# AUTHOR'S EMAIL :XXXX@mail.xjtu.edu.cn
# -----------------------------------------------------------------------------
# Ver 1.0  2019--01--01 initial version.
# -----------------------------------------------------------------------------

# .include "./src/custom_ops.S"

.globl _start
.weak main

.include "./inc/memory_map.inc"

# Interrupt vector table
.section .text.init
.align 2
_intr_vector_entry:
    mret                                # User-mode software interrupt entry
    mret                                # Supervisor-mode software interrupt entry
    mret                                # Reserved-mode software interrupt entry
    mret                                # Machine-mode software interrupt entry

    mret                                # User-mode timer interrupt entry
    mret                                # Supervisor-mode timer interrupt entry
    mret                                # Reserved-mode timer interrupt entry
    mret                                # Machine-mode tiemr interrupt entry

    mret                                # User-mode external interrupt entry
    mret                                # Supervisor-mode external interrupt entry
    mret                                # Reserved-mode external interrupt entry
    j me_intr_entry                     # Machine-mode external interrrupt entry

    j c1_intr_entry                     # Customized external interrupt entry1
    mret                                # Customized external interrupt entry2
    mret                                # Customized external interrupt entry3
    mret                                # Customized external interrupt entry4
    mret                                # Customized external interrupt entry5
    mret                                # Customized external interrupt entry6
    mret                                # Customized external interrupt entry7

init_intr:
    addi sp, sp, -8                     # Allocate the stack frame
    sw ra, 4(sp)                        # Save return address of caller onto the stack frame

    li t0, STACK_BASE_ADDR              # Set interrupt stack space.
    csrrw zero, mscratch, t0
    li t0, 0x1800                       # Set CSR mie reg: set MEIP as 'b1, set Custom 1 as 'b1.
    csrrw zero, CSR_MIE, t0
    li t0, 0x1                          # Set CSR mtvec reg: set interrupt mode as vectored.
    csrrw zero, mtvec, t0
    li t0, 0x18ff                       # Set CSR mstatus reg: set MIE as 'b1, set MPP as 'h3.
    csrrw zero, CSR_MSTATUS, t0

    lw ra, 4(sp)
    addi sp, sp, 8                      # Deallocate the stack frame
    ret

# code section
.section .text
.balign 512
_start:                                 # Power on & reset vector
    li sp, STACK_BASE_ADDR              # Set stack base address
    call init_intr                      # Initialize the interrupt registers
    call main                           # Jump to main function

# Interrupt service code
me_intr_entry:
    csrrw a0, mscratch, a0              # Save a0 to temporal reg.
    sw t0, 4(a0)                        # Protect t0
    sw t1, 8(a0)                        # Protect t1

    # clear interrupt signal
    li t0, 2
    li t1, DPU_REGMGR
    sw t0, 0(t1)

    # Restore environment
    lw t0, 4(a0)                        # Restore t0
    lw t1, 8(a0)                        # Restore t1
    csrrw a0, mscratch, a0              # Restore a0
    # picorv32_retirq_insn()
    # .word 0x400000b
    mret

c1_intr_entry:
    csrrw a0, mscratch, a0              # Save a0 to temporal reg.
    sw t0, 4(a0)                        # Protect t0
    sw t1, 8(a0)                        # Protect t1

    # clear interrupt signal
    li t0, 4
    li t1, DPU_REGMGR
    sw t0, 0(t1)

    # Restore environment
    lw t0, 4(a0)                        # Restore t0
    lw t1, 8(a0)                        # Restore t1
    csrrw a0, mscratch, a0              # Restore a0
    mret
