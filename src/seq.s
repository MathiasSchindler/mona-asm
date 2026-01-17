.section .bss
.L_numbuf:
    .space 64

.section .data
.L_nl:
    .ascii "\n"
.L_usage_str:
    .ascii "usage: seq <last> | seq <first> <last>\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %rdi
    cmp $2, %rdi
    je .L_one_arg
    cmp $3, %rdi
    je .L_two_args
    jmp .L_usage_err

.L_one_arg:
    mov 16(%rsp), %r12
    mov %r12, %rdi
    call util_parse_int
    test %rdx, %rdx
    je .L_usage_err
    mov $1, %rbx
    mov %rax, %r13
    jmp .L_seq_start

.L_two_args:
    mov 16(%rsp), %r12
    mov 24(%rsp), %r13
    mov %r12, %rdi
    call util_parse_int
    test %rdx, %rdx
    je .L_usage_err
    mov %rax, %rbx
    mov %r13, %rdi
    call util_parse_int
    test %rdx, %rdx
    je .L_usage_err
    mov %rax, %r13

.L_seq_start:
    mov %rbx, %rax
    cmp %r13, %rax
    jle .L_loop
    jmp .L_done

.L_loop:
    mov %rbx, %rdi
    lea .L_numbuf(%rip), %rsi
    call util_itoa
    mov %rax, %rdx
    mov $1, %edi
    lea .L_numbuf(%rip), %rsi
    call sys_write

    mov $1, %edi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write

    inc %rbx
    cmp %r13, %rbx
    jle .L_loop

.L_done:
    xor %edi, %edi
    call sys_exit

.L_usage_err:
    mov $2, %edi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %edi
    call sys_exit
