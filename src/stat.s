.section .bss
.L_statbuf:
    .space 256
.L_numbuf:
    .space 64

.section .data
.L_space:
    .ascii " "
.L_nl:
    .ascii "\n"
.L_usage_str:
    .ascii "usage: stat FILE\n"
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
    jne .L_usage
    cmp $0, %rcx
    je .L_usage

    mov %r8, %rbx
    mov (%rbx), %rsi

    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail
    mov %rax, %r12

    lea .L_statbuf(%rip), %rsi
    mov %r12, %rdi
    call sys_fstat
    test %rax, %rax
    js .L_fail_close

    mov %r12, %rdi
    call sys_close

    lea .L_statbuf(%rip), %rbx

    mov 48(%rbx), %rdi
    lea .L_numbuf(%rip), %rsi
    call util_utoa
    mov %rax, %rdx
    mov $1, %rdi
    lea .L_numbuf(%rip), %rsi
    call sys_write

    mov $1, %rdi
    lea .L_space(%rip), %rsi
    mov $1, %rdx
    call sys_write

    mov 24(%rbx), %eax
    and $0x0fff, %eax
    mov %rax, %rdi
    lea .L_numbuf(%rip), %rsi
    call util_utoa
    mov %rax, %rdx
    mov $1, %rdi
    lea .L_numbuf(%rip), %rsi
    call sys_write

    mov $1, %rdi
    lea .L_space(%rip), %rsi
    mov $1, %rdx
    call sys_write

    mov 88(%rbx), %rdi
    lea .L_numbuf(%rip), %rsi
    call util_utoa
    mov %rax, %rdx
    mov $1, %rdi
    lea .L_numbuf(%rip), %rsi
    call sys_write

    mov $1, %rdi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write

    xor %rdi, %rdi
    call sys_exit

.L_fail_close:
    mov %r12, %rdi
    call sys_close

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
