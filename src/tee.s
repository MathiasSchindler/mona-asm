.section .bss
.L_buf:
    .space 4096
.L_fds:
    .space 256

.section .data
.L_usage_str:
    .ascii "usage: tee [FILE...]\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"

_start:
    mov (%rsp), %r12
    cmp $1, %r12
    je .L_open_done
    lea 16(%rsp), %rbx
    xor %r13d, %r13d

.L_open_loop:
    cmp $1, %r12
    jle .L_open_done
    mov (%rbx), %rsi
    movb (%rsi), %al
    cmp $'-', %al
    je .L_usage

    mov $-100, %rdi
    mov $577, %rdx
    mov $0666, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail

    lea .L_fds(%rip), %r8
    mov %r13, %rcx
    shl $3, %rcx
    add %rcx, %r8
    mov %rax, (%r8)
    inc %r13

    add $8, %rbx
    dec %r12
    jmp .L_open_loop

.L_open_done:
.L_read:
    xor %edi, %edi
    lea .L_buf(%rip), %rsi
    mov $4096, %rdx
    call sys_read
    test %rax, %rax
    jle .L_close_exit

    mov %rax, %r14
    mov $1, %edi
    lea .L_buf(%rip), %rsi
    mov %r14, %rdx
    call .L_write_all

    xor %r15d, %r15d
.L_fd_loop:
    cmp %r13d, %r15d
    je .L_read
    lea .L_fds(%rip), %rbx
    mov %r15, %rcx
    shl $3, %rcx
    add %rcx, %rbx
    mov (%rbx), %rdi
    lea .L_buf(%rip), %rsi
    mov %r14, %rdx
    call .L_write_all
    inc %r15d
    jmp .L_fd_loop

.L_close_exit:
    xor %r15d, %r15d
.L_close_loop:
    cmp %r13d, %r15d
    je .L_exit
    lea .L_fds(%rip), %rbx
    mov %r15, %rcx
    shl $3, %rcx
    add %rcx, %rbx
    mov (%rbx), %rdi
    call sys_close
    inc %r15d
    jmp .L_close_loop

.L_exit:
    xor %edi, %edi
    call sys_exit

.L_fail:
    mov $1, %edi
    call sys_exit

.L_usage:
    mov $2, %edi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %edi
    call sys_exit

.L_write_all:
    push %r12
    push %r13
    mov %rsi, %r12
    mov %rdx, %r13
.L_write_loop:
    mov %r12, %rsi
    mov %r13, %rdx
    call sys_write
    test %rax, %rax
    js .L_fail
    cmp %rax, %r13
    je .L_write_done
    sub %rax, %r13
    add %rax, %r12
    jmp .L_write_loop
.L_write_done:
    pop %r13
    pop %r12
    ret
