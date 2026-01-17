.section .bss
.L_buf:
    .space 8192

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov $0, %edi
    lea .L_buf(%rip), %rsi
    mov $8192, %rdx
    call sys_read
    test %rax, %rax
    jle .L_exit
    lea .L_buf(%rip), %rbx
    mov %rbx, %r14
    add %rax, %r14
    mov %rbx, %r15
    mov %rbx, %r12
    xor %r13d, %r13d
    xor %r11d, %r11d

.L_line_loop:
    cmp %r14, %r15
    jae .L_finish
    mov %r15, %r8
.L_find_nl:
    cmp %r14, %r15
    jae .L_line_end
    movb (%r15), %al
    cmp $'\n', %al
    je .L_line_nl
    inc %r15
    jmp .L_find_nl
.L_line_nl:
    inc %r15
.L_line_end:
    mov %r15, %rcx
    sub %r8, %rcx
    mov %ecx, %r10d

    cmp $0, %r11d
    je .L_emit_first

    mov %r12, %rsi
    mov %r8, %rdi
    mov %r13d, %r9d

    test %r9d, %r9d
    je .L_cmp_do
    mov %rsi, %rax
    add %r9, %rax
    movb -1(%rax), %al
    cmp $'\n', %al
    jne .L_cmp_do
    dec %r9d
.L_cmp_do:
    test %r10d, %r10d
    je .L_cmp_loop
    mov %rdi, %rax
    add %r10, %rax
    movb -1(%rax), %al
    cmp $'\n', %al
    jne .L_cmp_loop
    dec %r10d

.L_cmp_loop:
    xor %ebx, %ebx
.L_cmp_byte:
    cmp %r9d, %ebx
    jae .L_cmp_len
    cmp %r10d, %ebx
    jae .L_cmp_len
    movb (%rsi,%rbx,1), %dl
    movb (%rdi,%rbx,1), %cl
    cmp %cl, %dl
    jne .L_emit
    inc %ebx
    jmp .L_cmp_byte
.L_cmp_len:
    cmp %r9d, %r10d
    jne .L_emit
    jmp .L_skip

.L_emit_first:
    mov $1, %r11d
.L_emit:
    mov $1, %edi
    mov %r8, %rsi
    mov %r15, %rdx
    sub %r8, %rdx
    call sys_write
    mov %r8, %r12
    mov %edx, %r13d
    jmp .L_line_loop

.L_skip:
    jmp .L_line_loop

.L_finish:
.L_exit:
    xor %edi, %edi
    call sys_exit
