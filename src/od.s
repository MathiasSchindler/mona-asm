.section .bss
.L_inbuf:
    .space 2048
.L_outbuf:
    .space 8192

.section .text
.global _start
.include "syscalls.inc"

_start:
.L_read:
    xor %edi, %edi
    lea .L_inbuf(%rip), %rsi
    mov $2048, %rdx
    call sys_read
    test %rax, %rax
    jle .L_exit

    mov %rax, %rcx
    lea .L_inbuf(%rip), %rsi
    lea .L_outbuf(%rip), %rdi
    xor %r8d, %r8d

.L_byte_loop:
    test %rcx, %rcx
    je .L_write
    movb (%rsi), %bl

    mov %bl, %r9b
    shr $6, %r9b
    add $'0', %r9b
    movb %r9b, (%rdi)
    inc %rdi

    mov %bl, %r9b
    shr $3, %r9b
    and $7, %r9b
    add $'0', %r9b
    movb %r9b, (%rdi)
    inc %rdi

    mov %bl, %r9b
    and $7, %r9b
    add $'0', %r9b
    movb %r9b, (%rdi)
    inc %rdi

    movb $' ', (%rdi)
    inc %rdi

    add $4, %r8
    inc %rsi
    dec %rcx
    jmp .L_byte_loop

.L_write:
    test %r8, %r8
    je .L_read
    lea .L_outbuf(%rip), %rbx
    add %r8, %rbx
    dec %rbx
    movb $'\n', (%rbx)

    mov $1, %edi
    lea .L_outbuf(%rip), %rsi
    mov %r8, %rdx
    call sys_write
    jmp .L_read

.L_exit:
    xor %edi, %edi
    call sys_exit
