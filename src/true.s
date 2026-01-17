.section .data
.L_usage_str:
    .ascii "usage: true\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %rdi
    lea 8(%rsp), %rsi
    xor %rdx, %rdx
    call util_parse_flags
    test %rdx, %rdx
    jne .L_usage_err
    xor %rdi, %rdi
    call sys_exit

.L_usage_err:
    mov $2, %rdi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %rdi
    call sys_exit
