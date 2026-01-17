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

_start:
    xor %r10, %r10
    mov (%rsp), %rdi
    cmp $1, %rdi
    je .L_echo_newline_or_exit
    mov %rdi, %r12
    dec %r12
    lea 16(%rsp), %rbx
    mov (%rbx), %r8
    movb (%r8), %al
    cmp $'-', %al
    jne .L_echo_loop_start
    movb 1(%r8), %al
    cmp $0, %al
    je .L_echo_loop_start
    cmp $'n', %al
    jne .L_echo_check_ddash
    cmpb $0, 2(%r8)
    jne .L_echo_usage
    mov $1, %r10d
    add $8, %rbx
    dec %r12
    jmp .L_echo_loop_start
.L_echo_check_ddash:
    cmp $'-', %al
    jne .L_echo_usage
    cmpb $0, 2(%r8)
    jne .L_echo_usage
    add $8, %rbx
    dec %r12

.L_echo_loop_start:
    cmp $0, %r12
    je .L_echo_newline_or_exit

.L_echo_loop:
    mov (%rbx), %r8
    mov %r8, %rdi
    call .L_strlen
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

.L_strlen:
    xor %rax, %rax
.L_strlen_loop:
    movb (%rdi,%rax,1), %cl
    test %cl, %cl
    je .L_strlen_done
    inc %rax
    jmp .L_strlen_loop
.L_strlen_done:
    ret

.L_echo_usage:
    mov $2, %rdi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %rdi
    call sys_exit
