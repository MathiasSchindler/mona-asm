.section .bss
.L_buf:
    .space 4096

.section .data
.L_nl:
    .ascii "\n"
.L_usage_str:
    .ascii "usage: pwd\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"

_start:
    mov (%rsp), %rdi
    cmp $1, %rdi
    jne .L_usage

    lea .L_buf(%rip), %rdi
    mov $4096, %rsi
    mov $79, %rax
    syscall
    test %rax, %rax
    js .L_fail

    mov %rax, %rdx
    mov $1, %rdi
    lea .L_buf(%rip), %rsi
    call sys_write

    mov $1, %rdi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write

    xor %rdi, %rdi
    call sys_exit

.L_fail:
    mov $1, %rdi
    call sys_exit

.L_usage:
    mov $2, %rdi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %rdi
    call sys_exit
