.section .data
.L_dot:
    .ascii ".\0"
.L_dotdot:
    .ascii "..\0"
.L_nl:
    .ascii "\n"
.L_usage_str:
    .ascii "usage: ls [-a] [dir]\n"
.equ L_usage_len, . - .L_usage_str

.section .bss
.L_buf:
    .space 8192

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %rdi
    lea 8(%rsp), %rsi
    mov $1, %rdx
    call util_parse_flags
    test %rdx, %rdx
    jne .L_usage
    mov %rax, %r10

    mov %rcx, %r12
    mov %r8, %rbx
    cmp $0, %r12
    je .L_use_dot

    mov (%rbx), %rsi
    jmp .L_open

.L_use_dot:
    lea .L_dot(%rip), %rsi

.L_open:
    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail
    mov %rax, %r12

.L_read:
    lea .L_buf(%rip), %rsi
    mov $8192, %rdx
    mov %r12, %rdi
    call sys_getdents64
    test %rax, %rax
    js .L_fail
    cmp $0, %rax
    je .L_done

    mov %rax, %r13
    lea .L_buf(%rip), %r14

.L_entry:
    cmp $0, %r13
    je .L_read

    movzwq 16(%r14), %r15
    lea 19(%r14), %r8

    test $1, %r10
    jne .L_print

    mov %r8, %rdi
    lea .L_dot(%rip), %rsi
    call util_streq
    cmp $1, %rax
    je .L_next

    mov %r8, %rdi
    lea .L_dotdot(%rip), %rsi
    call util_streq
    cmp $1, %rax
    je .L_next

.L_print:

    mov %r8, %rdi
    call util_strlen
    mov %rax, %rdx
    mov $1, %rdi
    mov %r8, %rsi
    call sys_write

    mov $1, %rdi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write

.L_next:
    add %r15, %r14
    sub %r15, %r13
    jmp .L_entry

.L_done:
    mov %r12, %rdi
    call sys_close
    xor %rdi, %rdi
    call sys_exit

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
