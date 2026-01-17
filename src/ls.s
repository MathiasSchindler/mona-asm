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

_start:
    xor %r10, %r10
    mov (%rsp), %rdi
    cmp $1, %rdi
    je .L_use_dot
    cmp $2, %rdi
    je .L_one_arg
    cmp $3, %rdi
    je .L_two_arg
    jmp .L_usage

.L_one_arg:
    mov 16(%rsp), %rsi
    movb (%rsi), %al
    cmp $'-', %al
    jne .L_open
    movb 1(%rsi), %al
    cmp $'a', %al
    jne .L_usage
    cmpb $0, 2(%rsi)
    jne .L_usage
    mov $1, %r10d
    jmp .L_use_dot

.L_two_arg:
    mov 16(%rsp), %rsi
    movb (%rsi), %al
    cmp $'-', %al
    jne .L_usage
    movb 1(%rsi), %al
    cmp $'a', %al
    jne .L_usage
    cmpb $0, 2(%rsi)
    jne .L_usage
    mov $1, %r10d
    mov 24(%rsp), %rsi
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

    movb (%r8), %al
    cmp $'.', %al
    jne .L_print
    movb 1(%r8), %al
    cmp $0, %al
    je .L_next
    cmp $'.', %al
    jne .L_print
    movb 2(%r8), %al
    cmp $0, %al
    je .L_next

.L_print:

    mov %r8, %rdi
    call .L_strlen
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
