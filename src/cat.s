.section .bss
.L_buf:
    .space 4096

.section .data
.L_usage_str:
    .ascii "usage: cat [FILE...]\n"
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

    mov %rcx, %r14
    mov %r8, %rbx
    cmp $0, %r14
    je .L_cat_stdin

.L_cat_files:
    mov (%rbx), %rsi
    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail
    mov %rax, %r12
    mov %r12, %rdi
    call .L_cat_fd
    mov %r12, %rdi
    call sys_close

    add $8, %rbx
    dec %r14
    jne .L_cat_files

    xor %rdi, %rdi
    call sys_exit

.L_cat_stdin:
    xor %rdi, %rdi
    call .L_cat_fd
    xor %rdi, %rdi
    call sys_exit

.L_cat_fd:
    push %r13
    mov %rdi, %r13

.L_cat_read:
    lea .L_buf(%rip), %rsi
    mov $4096, %rdx
    mov %r13, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail
    cmp $0, %rax
    je .L_cat_done

    mov %rax, %r8
    lea .L_buf(%rip), %rsi
    mov %r8, %rdx

.L_cat_write:
    mov $1, %rdi
    call sys_write
    test %rax, %rax
    js .L_fail
    cmp %rax, %rdx
    je .L_cat_read

    sub %rax, %rdx
    add %rax, %rsi
    jmp .L_cat_write

.L_cat_done:
    pop %r13
    ret

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
