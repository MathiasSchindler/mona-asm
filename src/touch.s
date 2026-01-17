.section .data
.L_usage_str:
    .ascii "usage: touch <file>\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start

.equ SYS_exit, 60
.equ SYS_write, 1
.equ SYS_openat, 257
.equ SYS_close, 3
.equ SYS_utimensat, 280


_start:
    mov (%rsp), %rdi
    cmp $2, %rdi
    jne .L_usage_err
    mov 16(%rsp), %r13
    mov $-100, %rdi
    mov %r13, %rsi
    mov $65, %rdx
    mov $0666, %r10
    mov $SYS_openat, %eax
    syscall
    test %rax, %rax
    js .L_fail
    mov %rax, %r12

    mov $-100, %rdi
    mov %r13, %rsi
    xor %rdx, %rdx
    xor %r10, %r10
    mov $SYS_utimensat, %eax
    syscall
    test %rax, %rax
    js .L_fail_close

    mov %r12, %rdi
    mov $SYS_close, %eax
    syscall
    xor %edi, %edi
    mov $SYS_exit, %eax
    syscall

.L_fail_close:
    mov %r12, %rdi
    mov $SYS_close, %eax
    syscall
.L_fail:
    mov $1, %edi
    mov $SYS_exit, %eax
    syscall

.L_usage_err:
    mov $2, %edi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    mov $SYS_write, %eax
    syscall
    mov $1, %edi
    mov $SYS_exit, %eax
    syscall
