.section .data
.L_space:
    .ascii " "
.L_nl:
    .ascii "\n"
.L_usage_str:
    .ascii "usage: echo [-n] [args...]\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %rdi
    lea 8(%rsp), %rsi
    mov $8192, %rdx
    call util_parse_flags
    test %rdx, %rdx
    jne .L_echo_usage
    mov %rax, %r10

    mov %rcx, %r12
    mov %r8, %rbx
    cmp $0, %r12
    je .L_echo_newline_or_exit

.L_echo_loop:
    mov (%rbx), %r8
    mov %r8, %rdi
    call util_strlen
    mov %rax, %rdx
    mov $1, %rdi
    mov %r8, %rsi
    call sys_write

    add $8, %rbx
    dec %r12
    je .L_echo_newline_or_exit

    mov $1, %rdi
    lea .L_space(%rip), %rsi
    mov $1, %rdx
    call sys_write
    jmp .L_echo_loop

.L_echo_newline_or_exit:
    test $8192, %r10
    jne .L_echo_exit
    mov $1, %rdi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write
.L_echo_exit:
    xor %rdi, %rdi
    call sys_exit

.L_echo_usage:
    mov $2, %rdi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %rdi
    call sys_exit
