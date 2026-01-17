.section .bss
.L_inbuf:
    .space 4096
.L_outbuf:
    .space 4096

.section .data
.L_usage_str:
    .ascii "usage: tr [-d] SET1 [SET2]\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %rdi
    cmp $3, %rdi
    je .L_argc3
    jmp .L_usage

.L_argc3:
    mov 16(%rsp), %r12
    mov 24(%rsp), %r13

    mov %r12, %rdi
    call .L_is_dash_d
    cmp $1, %rax
    jne .L_translate_setup

    mov $1, %r15d
    mov %r13, %r12
    jmp .L_process

.L_translate_setup:
    xor %r15d, %r15d
    mov %r13, %rdi
    call util_strlen
    test %rax, %rax
    je .L_usage
    mov %rax, %r14
    mov %r13, %rsi
    add %r14, %rsi
    dec %rsi
    movb (%rsi), %r9b

.L_process:
.L_read:
    mov $0, %edi
    lea .L_inbuf(%rip), %rsi
    mov $4096, %rdx
    call sys_read
    test %rax, %rax
    jle .L_exit

    mov %rax, %rcx
    lea .L_inbuf(%rip), %rsi
    lea .L_outbuf(%rip), %rdi
    xor %r8d, %r8d

.L_byte_loop:
    test %rcx, %rcx
    je .L_write
    movb (%rsi), %al
    test %r15d, %r15d
    jne .L_check_delete

    mov %r12, %rbx
    xor %r10d, %r10d
.L_scan_set1:
    movb (%rbx), %dl
    test %dl, %dl
    je .L_no_match
    cmp %dl, %al
    je .L_match
    inc %rbx
    inc %r10d
    jmp .L_scan_set1

.L_match:
    mov %r10, %r11
    cmp %r14, %r11
    jb .L_use_index
    mov %r9b, %al
    jmp .L_store

.L_use_index:
    mov %r13, %rbx
    add %r11, %rbx
    movb (%rbx), %al
    jmp .L_store

.L_no_match:
.L_store:
    movb %al, (%rdi)
    inc %rdi
    inc %r8
    jmp .L_next

.L_check_delete:
    mov %r12, %rbx
.L_scan_del:
    movb (%rbx), %dl
    test %dl, %dl
    je .L_keep
    cmp %dl, %al
    je .L_skip
    inc %rbx
    jmp .L_scan_del

.L_skip:
    jmp .L_next

.L_keep:
    movb %al, (%rdi)
    inc %rdi
    inc %r8

.L_next:
    inc %rsi
    dec %rcx
    jmp .L_byte_loop

.L_write:
    mov $1, %edi
    lea .L_outbuf(%rip), %rsi
    mov %r8, %rdx
    call sys_write
    jmp .L_read

.L_exit:
    xor %edi, %edi
    call sys_exit

.L_usage:
    mov $2, %edi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %edi
    call sys_exit

.L_is_dash_d:
    movb (%rdi), %al
    cmp $'-', %al
    jne .L_is_no
    movb 1(%rdi), %al
    cmp $'d', %al
    jne .L_is_no
    movb 2(%rdi), %al
    cmp $0, %al
    jne .L_is_no
    mov $1, %rax
    ret
.L_is_no:
    xor %rax, %rax
    ret
