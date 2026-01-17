.section .data
.L_usage_str:
    .ascii "usage: chmod <mode> <file>\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start

.equ SYS_exit, 60
.equ SYS_write, 1
.equ SYS_chmod, 90

_start:
    mov (%rsp), %rdi
    cmp $3, %rdi
    jne .L_usage_err
    mov 16(%rsp), %r12
    mov 24(%rsp), %r13

    mov %r12, %rdi
    call .L_parse_octal
    test %rdx, %rdx
    je .L_usage_err

    mov %r13, %rdi
    mov %rax, %rsi
    mov $SYS_chmod, %eax
    syscall
    test %rax, %rax
    js .L_fail
    xor %edi, %edi
    mov $SYS_exit, %eax
    syscall

.L_fail:
    mov $1, %edi
    mov $SYS_exit, %eax
    syscall

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
    mov $2, %edi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    mov $SYS_write, %eax
    syscall
    mov $1, %edi
    mov $SYS_exit, %eax
    syscall
