.section .data
.L_usage_str:
    .ascii "usage: dirname <path>\n"
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
    jae .L_all_slash
    movb (%r13), %al
    cmp $'/', %al
    jne .L_after_trim
    dec %r13
    jmp .L_trim_slash

.L_all_slash:
    movb (%r13), %al
    cmp $'/', %al
    jne .L_after_trim
    jmp .L_print_slash

.L_after_trim:
    mov %r13, %r14
.L_find_slash:
    cmp %r14, %r12
    jae .L_no_slash
    movb -1(%r14), %al
    cmp $'/', %al
    je .L_found_slash
    dec %r14
    jmp .L_find_slash

.L_no_slash:
    jmp .L_print_dot

.L_found_slash:
    sub $2, %r14
    cmp %r12, %r14
    jb .L_print_slash
    jmp .L_output_dir

.L_output_dir:
    mov %r12, %rsi
    mov %r14, %rdx
    sub %r12, %rdx
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
