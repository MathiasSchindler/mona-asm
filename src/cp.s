.section .bss
.L_buf:
    .space 4096

.section .data
.L_usage_str:
    .ascii "usage: cp <src> <dst>\n"
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
    cmp $2, %rcx
    jne .L_usage_err

    mov (%r8), %r12
    mov 8(%r8), %r13

    mov $-100, %rdi
    mov %r12, %rsi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail
    mov %rax, %r14

    mov $-100, %rdi
    mov %r13, %rsi
    mov $577, %rdx
    mov $0666, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail_close_src
    mov %rax, %r15

.L_read:
    lea .L_buf(%rip), %rsi
    mov $4096, %rdx
    mov %r14, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail_close
    cmp $0, %rax
    je .L_done

    mov %rax, %r8
    lea .L_buf(%rip), %rsi
    mov %r8, %rdx

.L_write:
    mov %r15, %rdi
    call sys_write
    test %rax, %rax
    js .L_fail_close
    cmp %rax, %rdx
    je .L_read
    sub %rax, %rdx
    add %rax, %rsi
    jmp .L_write

.L_done:
    mov %r15, %rdi
    call sys_close
    mov %r14, %rdi
    call sys_close
    xor %rdi, %rdi
    call sys_exit

.L_fail_close:
    mov %r15, %rdi
    call sys_close
.L_fail_close_src:
    mov %r14, %rdi
    call sys_close
.L_fail:
    mov $1, %rdi
    call sys_exit

.L_usage_err:
    mov $2, %rdi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %rdi
    call sys_exit
