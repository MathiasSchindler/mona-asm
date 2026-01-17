.section .data
.L_usage_str:
    .ascii "usage: ln <target> <link>\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "utils.inc"

.equ SYS_exit, 60
.equ SYS_write, 1
.equ SYS_link, 86

_start:
    mov (%rsp), %rdi
    lea 8(%rsp), %rsi
    xor %rdx, %rdx
    call util_parse_flags
    test %rdx, %rdx
    jne .L_usage_err
    cmp $2, %rcx
    jne .L_usage_err

    mov (%r8), %rdi
    mov 8(%r8), %rsi
    mov $SYS_link, %eax
    syscall
    test %rax, %rax
    js .L_fail
    xor %edi, %edi
    mov $SYS_exit, %eax
    syscall

.L_fail:
    mov $1, %edi
    mov $SYS_exit, %eax
    syscall

.L_usage_err:
    mov $2, %edi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    mov $SYS_write, %eax
    syscall
    mov $1, %edi
    mov $SYS_exit, %eax
    syscall
