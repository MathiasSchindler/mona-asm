.section .bss
.L_buf:
    .space 4096
.L_numbuf:
    .space 32

.section .data
.L_space:
    .ascii " "
.L_nl:
    .ascii "\n"
.L_usage_str:
    .ascii "usage: wc [-lwc] [FILE...]\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    xor %r12, %r12
    xor %r13, %r13
    xor %r14, %r14

    mov (%rsp), %rdi
    lea 8(%rsp), %rsi
    mov $0x400804, %rdx
    call util_parse_flags
    test %rdx, %rdx
    jne .L_usage
    mov %rax, %rbp
    mov %rcx, %r15
    mov %r8, %rbx

    cmp $0, %r15
    je .L_wc_stdin

.L_wc_files:
    mov (%rbx), %rsi
    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail
    push %rax
    mov %rax, %rdi
    call .L_wc_fd
    pop %rdi
    call sys_close

    add $8, %rbx
    dec %r15
    jne .L_wc_files

    jmp .L_print

.L_wc_stdin:
    xor %rdi, %rdi
    call .L_wc_fd

.L_print:
    test %rbp, %rbp
    jne .L_wc_print_sel
    mov $0x400804, %rbp

.L_wc_print_sel:
    xor %r10d, %r10d

    test $0x800, %rbp
    je .L_wc_skip_lines
    cmp $0, %r10d
    je .L_wc_lines
    mov $1, %rdi
    lea .L_space(%rip), %rsi
    mov $1, %rdx
    call sys_write
.L_wc_lines:
    mov %r13, %rdi
    lea .L_numbuf(%rip), %rsi
    call util_utoa
    mov %rax, %rdx
    mov $1, %rdi
    lea .L_numbuf(%rip), %rsi
    call sys_write
    inc %r10d
.L_wc_skip_lines:

    test $0x400000, %rbp
    je .L_wc_skip_words
    cmp $0, %r10d
    je .L_wc_words
    mov $1, %rdi
    lea .L_space(%rip), %rsi
    mov $1, %rdx
    call sys_write
.L_wc_words:
    mov %r14, %rdi
    lea .L_numbuf(%rip), %rsi
    call util_utoa
    mov %rax, %rdx
    mov $1, %rdi
    lea .L_numbuf(%rip), %rsi
    call sys_write
    inc %r10d
.L_wc_skip_words:

    test $0x4, %rbp
    je .L_wc_skip_bytes
    cmp $0, %r10d
    je .L_wc_bytes
    mov $1, %rdi
    lea .L_space(%rip), %rsi
    mov $1, %rdx
    call sys_write
.L_wc_bytes:
    mov %r12, %rdi
    lea .L_numbuf(%rip), %rsi
    call util_utoa
    mov %rax, %rdx
    mov $1, %rdi
    lea .L_numbuf(%rip), %rsi
    call sys_write
    inc %r10d
.L_wc_skip_bytes:

    mov $1, %rdi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write

    xor %rdi, %rdi
    call sys_exit

.L_wc_fd:
    push %rbx
    mov %rdi, %rbx
    xor %r10d, %r10d

.L_read:
    lea .L_buf(%rip), %rsi
    mov $4096, %rdx
    mov %rbx, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail
    cmp $0, %rax
    je .L_eof

    mov %rax, %r8
    lea .L_buf(%rip), %r9
    xor %r11, %r11

.L_byte:
    cmp %r11, %r8
    je .L_read

    movb (%r9,%r11,1), %al
    inc %r12

    cmp $'\n', %al
    jne .L_not_nl
    inc %r13
.L_not_nl:
    cmp $' ', %al
    je .L_space_char
    cmp $'\n', %al
    je .L_space_char
    cmp $'\t', %al
    je .L_space_char
    cmp $'\r', %al
    je .L_space_char
    cmp $'\v', %al
    je .L_space_char
    cmp $'\f', %al
    je .L_space_char

    cmp $0, %r10b
    jne .L_next_byte
    mov $1, %r10b
    jmp .L_next_byte

.L_space_char:
    cmp $0, %r10b
    je .L_next_byte
    inc %r14
    xor %r10d, %r10d

.L_next_byte:
    inc %r11
    jmp .L_byte

.L_eof:
    cmp $0, %r10b
    je .L_wc_done
    inc %r14

.L_wc_done:
    pop %rbx
    ret

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
