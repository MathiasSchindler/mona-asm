.section .data
.L_usage_str:
    .ascii "usage: basename <path>\n"
.equ L_usage_len, . - .L_usage_str
.L_dot:
    .ascii "."
.L_slash:
    .ascii "/"
.L_nl:
    .ascii "\n"

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %rdi
    cmp $2, %rdi
    jne .L_usage

    mov 16(%rsp), %r12
    mov %r12, %rdi
    call util_strlen
    test %rax, %rax
    je .L_print_dot

    mov %r12, %r13
    add %rax, %r13
    dec %r13

.L_trim_slash:
    cmp %r13, %r12
    jae .L_all_slash_check
    movb (%r13), %al
    cmp $'/', %al
    jne .L_after_trim
    dec %r13
    jmp .L_trim_slash

.L_all_slash_check:
    movb (%r13), %al
    cmp $'/', %al
    jne .L_after_trim
    jmp .L_print_slash

.L_after_trim:
    mov %r13, %r14
.L_find_start:
    cmp %r14, %r12
    jae .L_start_found
    movb -1(%r14), %al
    cmp $'/', %al
    je .L_start_found
    dec %r14
    jmp .L_find_start

.L_start_found:
    mov %r14, %rsi
    mov %r13, %rdx
    sub %r14, %rdx
    inc %rdx
    mov $1, %rdi
    call sys_write
    jmp .L_print_nl

.L_print_dot:
    mov $1, %rdi
    lea .L_dot(%rip), %rsi
    mov $1, %rdx
    call sys_write
    jmp .L_print_nl

.L_print_slash:
    mov $1, %rdi
    lea .L_slash(%rip), %rsi
    mov $1, %rdx
    call sys_write
    jmp .L_print_nl

.L_print_nl:
    mov $1, %rdi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write
    xor %edi, %edi
    call sys_exit

.L_usage:
    mov $2, %edi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %edi
    call sys_exit
