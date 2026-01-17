.section .data
.L_usage_str:
    .ascii "usage: chmod <mode> <file>\n"
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

    mov %r12, %rdi
    call .L_parse_octal
    test %rdx, %rdx
    je .L_usage_err

    mov %r13, %rdi
    mov %rax, %rsi
    call sys_chmod
    test %rax, %rax
    js .L_fail
    xor %rdi, %rdi
    call sys_exit

.L_fail:
    mov $1, %rdi
    call sys_exit

.L_parse_octal:
    xor %rax, %rax
    xor %rdx, %rdx
    mov %rdi, %rcx
    movb (%rcx), %bl
    test %bl, %bl
    je .L_parse_fail
.L_parse_loop:
    movb (%rcx), %bl
    test %bl, %bl
    je .L_parse_ok
    cmp $'0', %bl
    jb .L_parse_fail
    cmp $'7', %bl
    ja .L_parse_fail
    imul $8, %rax, %rax
    movzbq %bl, %r8
    sub $'0', %r8
    add %r8, %rax
    inc %rcx
    jmp .L_parse_loop
.L_parse_ok:
    mov $1, %rdx
    ret
.L_parse_fail:
    xor %rax, %rax
    xor %rdx, %rdx
    ret

.L_usage_err:
    mov $2, %rdi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %rdi
    call sys_exit
