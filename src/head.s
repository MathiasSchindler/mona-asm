.section .bss
.L_buf:
    .space 4096

.section .data
.L_usage_str:
    .ascii "usage: head [FILE]\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"


_start:
    mov (%rsp), %rdi
    cmp $1, %rdi
    je .L_stdin
    cmp $2, %rdi
    jne .L_usage_err

    mov 16(%rsp), %rsi
    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail
    mov %rax, %r13
    jmp .L_head

.L_stdin:
    xor %r13, %r13

.L_head:
    xor %r12, %r12

.L_read:
    lea .L_buf(%rip), %rsi
    mov $4096, %rdx
    mov %r13, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail
    cmp $0, %rax
    je .L_done

    mov %rax, %rbx
    xor %rcx, %rcx
    xor %r11b, %r11b
    mov %rbx, %r10
    lea .L_buf(%rip), %r9

.L_scan:
    cmp %rcx, %rbx
    je .L_write
    movb (%r9,%rcx,1), %al
    cmp $'\n', %al
    jne .L_scan_next
    inc %r12
    cmp $10, %r12
    jne .L_scan_next
    lea 1(%rcx), %r10
    mov $1, %r11b
    mov %rbx, %rcx
    jmp .L_write

.L_scan_next:
    inc %rcx
    jmp .L_scan

.L_write:
    lea .L_buf(%rip), %rsi
    mov %r10, %rdx
.L_write_loop:
    mov $1, %rdi
    call sys_write
    test %rax, %rax
    js .L_fail
    cmp %rax, %rdx
    je .L_write_done
    sub %rax, %rdx
    add %rax, %rsi
    jmp .L_write_loop

.L_write_done:
    cmp $0, %r11b
    jne .L_done
    jmp .L_read

.L_done:
    cmp $0, %r13
    je .L_exit_ok
    mov %r13, %rdi
    call sys_close
.L_exit_ok:
    xor %rdi, %rdi
    call sys_exit

.L_fail:
    mov $1, %rdi
    call sys_exit

.L_usage_err:
    mov $2, %rdi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %rdi
    call sys_exit
