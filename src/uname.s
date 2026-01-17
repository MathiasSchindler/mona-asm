.section .bss
.L_buf:
    .space 390

.section .data
.L_usage_str:
    .ascii "usage: uname\n"
.equ L_usage_len, . - .L_usage_str
.L_nl:
    .ascii "\n"

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %rdi
    cmp $1, %rdi
    jne .L_usage

    lea .L_buf(%rip), %rdi
    call sys_uname
    test %rax, %rax
    js .L_fail

    lea .L_buf(%rip), %rdi
    call util_strlen
    mov %rax, %rdx
    mov $1, %rdi
    lea .L_buf(%rip), %rsi
    call sys_write

    mov $1, %rdi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write

    xor %edi, %edi
    call sys_exit

.L_fail:
    mov $1, %edi
    call sys_exit

.L_usage:
    mov $2, %edi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %edi
    call sys_exit
