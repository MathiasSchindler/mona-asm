.section .bss
.L_buf:
    .space 4096

.section .data
.L_default:
    .ascii "y\n"
.L_default_n:
    .ascii "y"
.L_dash_n:
    .ascii "-n\0"

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %r15
    lea 8(%rsp), %r14
    xor %r9d, %r9d
    mov $1, %r12

    cmp $2, %r15
    jb .L_check_args
    mov 8(%r14), %rdi
    lea .L_dash_n(%rip), %rsi
    call util_streq
    cmp $1, %rax
    jne .L_check_args
    mov $1, %r9d
    mov $2, %r12

.L_check_args:
    cmp %r15, %r12
    jb .L_build

    test %r9d, %r9d
    je .L_default_line
    lea .L_default_n(%rip), %rsi
    mov $1, %rdx
    jmp .L_loop

.L_default_line:
    lea .L_default(%rip), %rsi
    mov $2, %rdx
    jmp .L_loop

.L_build:
    lea .L_buf(%rip), %rbx
    mov %rbx, %r13

.L_arg_loop:
    cmp %r15, %r12
    jge .L_done_build
    mov (%r14,%r12,8), %r10
    mov %r10, %rdi
    call util_strlen
    mov %rax, %r11
    mov %r13, %rdi
    mov %r10, %rsi
    mov %r11, %rdx
    call util_memcpy
    add %r11, %r13
    inc %r12
    cmp %r15, %r12
    jge .L_done_build
    movb $' ', (%r13)
    inc %r13
    jmp .L_arg_loop

.L_done_build:
    test %r9d, %r9d
    jne .L_no_nl
    movb $'\n', (%r13)
    inc %r13
.L_no_nl:
    mov %r13, %rdx
    sub %rbx, %rdx
    mov %rbx, %rsi

.L_loop:
    mov $1, %edi
    call sys_write
    jmp .L_loop
