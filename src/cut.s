.section .bss
.L_buf:
    .space 8192
.L_numbuf:
    .space 32

.section .data
.L_usage_str:
    .ascii "usage: cut [-d <delim>] -f <field>\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %r15
    lea 8(%rsp), %r14
    movb $'\t', %r12b
    xor %r13d, %r13d
    mov $1, %r10

.L_arg_loop:
    cmp %r15, %r10
    jae .L_args_done
    mov (%r14,%r10,8), %rdi
    lea .L_opt_d(%rip), %rsi
    call util_streq
    cmp $1, %rax
    jne .L_check_f
    inc %r10
    cmp %r15, %r10
    jae .L_usage
    mov (%r14,%r10,8), %rdi
    movb (%rdi), %r12b
    inc %r10
    jmp .L_arg_loop
.L_check_f:
    mov (%r14,%r10,8), %rdi
    lea .L_opt_f(%rip), %rsi
    call util_streq
    cmp $1, %rax
    jne .L_usage
    inc %r10
    cmp %r15, %r10
    jae .L_usage
    mov (%r14,%r10,8), %rdi
    call util_parse_int
    test %rdx, %rdx
    je .L_usage
    mov %eax, %r13d
    inc %r10
    jmp .L_arg_loop

.L_args_done:
    test %r13d, %r13d
    jle .L_usage

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

.L_line_loop:
    cmp %r14, %r15
    jae .L_exit
    mov %r15, %r8
    mov %r13d, %r9d
    mov %r8, %r11
    mov $1, %r10d

.L_field_scan:
    cmp %r14, %r15
    jae .L_emit_line
    movb (%r15), %al
    cmp $'\n', %al
    je .L_line_end
    cmp %r12b, %al
    je .L_delim
    inc %r15
    jmp .L_field_scan

.L_delim:
    cmp %r10d, %r9d
    jne .L_delim_next
    mov %r11, %rsi
    mov %r15, %rdx
    sub %r11, %rdx
    mov $1, %edi
    call sys_write
.L_skip_to_nl:
    cmp %r14, %r15
    jae .L_exit
    movb (%r15), %al
    cmp $'\n', %al
    je .L_emit_nl
    inc %r15
    jmp .L_skip_to_nl
.L_delim_next:
    inc %r10d
    lea 1(%r15), %r11
    inc %r15
    jmp .L_field_scan

.L_line_end:
    cmp %r10d, %r9d
    jne .L_emit_nl
    mov %r11, %rsi
    mov %r15, %rdx
    sub %r11, %rdx
    mov $1, %edi
    call sys_write
    jmp .L_emit_nl

.L_emit_line:
    cmp %r10d, %r9d
    jne .L_emit_nl
    mov %r11, %rsi
    mov %r15, %rdx
    sub %r11, %rdx
    mov $1, %edi
    call sys_write

.L_emit_nl:
    cmp %r14, %r15
    jae .L_exit
    movb (%r15), %al
    cmp $'\n', %al
    jne .L_line_loop
    mov $1, %edi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %r15
    jmp .L_line_loop

.L_usage:
    mov $2, %edi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %edi
    call sys_exit

.L_exit:
    xor %edi, %edi
    call sys_exit

.section .data
.L_nl:
    .ascii "\n"
.L_opt_d:
    .ascii "-d\0"
.L_opt_f:
    .ascii "-f\0"
