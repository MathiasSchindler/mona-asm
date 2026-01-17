.section .bss
.L_ts:
    .space 16

.section .data
.L_usage_str:
    .ascii "usage: sleep <seconds>\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %rdi
    cmp $2, %rdi
    jne .L_usage

    mov 16(%rsp), %rdi
    call util_parse_int
    test %rdx, %rdx
    je .L_usage
    test %rax, %rax
    js .L_usage

    lea .L_ts(%rip), %rsi
    mov %rax, (%rsi)
    movq $0, 8(%rsi)

    mov %rsi, %rdi
    xor %rsi, %rsi
    call sys_nanosleep
    test %rax, %rax
    js .L_fail

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
