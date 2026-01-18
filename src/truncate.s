.section .data
.L_usage_str:
    .ascii "usage: truncate <size> <file>\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %rdi
    cmp $3, %rdi
    jne .L_usage

    mov 16(%rsp), %rdi
    call util_parse_int
    test %rdx, %rdx
    je .L_usage
    test %rax, %rax
    js .L_usage
    mov %rax, %r12

    mov 24(%rsp), %rsi
    mov $-100, %rdi
    mov $1, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail
    mov %rax, %r13

    mov %r13, %rdi
    mov %r12, %rsi
    call sys_ftruncate
    test %rax, %rax
    js .L_fail_close

    mov %r13, %rdi
    call sys_close
    xor %edi, %edi
    call sys_exit

.L_fail_close:
    mov %r13, %rdi
    call sys_close
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
