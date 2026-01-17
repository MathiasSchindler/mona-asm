.section .bss
.L_statbuf:
    .space 256
.L_numbuf:
    .space 64

.section .data
.L_nl:
    .ascii "\n"
.L_usage_str:
    .ascii "usage: du <path>\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "utils.inc"

.equ SYS_exit, 60
.equ SYS_write, 1
.equ SYS_openat, 257
.equ SYS_close, 3
.equ SYS_fstat, 5

_start:
    mov (%rsp), %rdi
    cmp $2, %rdi
    jne .L_usage_err
    mov 16(%rsp), %rsi
    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    mov $SYS_openat, %eax
    syscall
    test %rax, %rax
    js .L_fail
    mov %rax, %r12

    lea .L_statbuf(%rip), %rsi
    mov %r12, %rdi
    mov $SYS_fstat, %eax
    syscall
    test %rax, %rax
    js .L_fail_close

    mov %r12, %rdi
    mov $SYS_close, %eax
    syscall

    lea .L_statbuf(%rip), %rbx
    mov 48(%rbx), %rdi
    lea .L_numbuf(%rip), %rsi
    call util_utoa
    mov %rax, %rdx
    mov $1, %edi
    lea .L_numbuf(%rip), %rsi
    mov $SYS_write, %eax
    syscall

    mov $1, %edi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    mov $SYS_write, %eax
    syscall

    xor %edi, %edi
    mov $SYS_exit, %eax
    syscall

.L_fail_close:
    mov %r12, %rdi
    mov $SYS_close, %eax
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
