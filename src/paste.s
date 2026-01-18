.section .bss
.L_buf1:
    .space 8192
.L_buf2:
    .space 8192
.L_len2:
    .space 8
.L_ptr2:
    .space 8

.section .data
.L_usage_str:
    .ascii "usage: paste <file1> <file2>\n"
.equ L_usage_len, . - .L_usage_str
.L_tab:
    .ascii "\t"
.L_nl:
    .ascii "\n"

.section .text
.global _start
.include "syscalls.inc"

_start:
    mov (%rsp), %rdi
    cmp $3, %rdi
    jne .L_usage

    mov 16(%rsp), %rsi
    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail
    mov %rax, %r12

    mov 24(%rsp), %rsi
    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail_close1
    mov %rax, %r13

    lea .L_buf1(%rip), %rsi
    mov $8192, %rdx
    mov %r12, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail_close2
    mov %rax, %r14

    lea .L_buf2(%rip), %rsi
    mov $8192, %rdx
    mov %r13, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail_close2
    mov %rax, %r15

    lea .L_buf1(%rip), %r8
    lea .L_buf2(%rip), %r9
    mov %r8, %rbx
    mov %r9, %r15
    add %r14, %r8
    add %r15, %r9

.L_loop:
    cmp %r8, %rbx
    jae .L_done
    cmp %r9, %r15
    jae .L_done

    mov %rbx, %r14
    mov %rbx, %rax
.L_scan1:
    cmp %r8, %rax
    jae .L_line1_end
    movb (%rax), %dl
    cmp $'\n', %dl
    je .L_line1_nl
    inc %rax
    jmp .L_scan1
.L_line1_nl:
    mov %rax, %rcx
    sub %rbx, %rcx
    lea 1(%rax), %rbx
    jmp .L_line1_done
.L_line1_end:
    mov %r8, %rcx
    sub %rbx, %rcx
    mov %r8, %rbx
.L_line1_done:
    mov %rcx, %r10

    lea .L_ptr2(%rip), %r11
    mov %r15, (%r11)
    mov %r15, %rax
.L_scan2:
    cmp %r9, %rax
    jae .L_line2_end
    movb (%rax), %dl
    cmp $'\n', %dl
    je .L_line2_nl
    inc %rax
    jmp .L_scan2
.L_line2_nl:
    mov %rax, %rcx
    sub %r15, %rcx
    lea 1(%rax), %r15
    jmp .L_line2_done
.L_line2_end:
    mov %r9, %rcx
    sub %r15, %rcx
    mov %r9, %r15
.L_line2_done:
    lea .L_len2(%rip), %rdx
    mov %rcx, (%rdx)

    mov $1, %edi
    mov %r14, %rsi
    mov %r10, %rdx
    call .L_write_all

    mov $1, %edi
    lea .L_tab(%rip), %rsi
    mov $1, %rdx
    call .L_write_all

    mov $1, %edi
    mov .L_ptr2(%rip), %rsi
    mov .L_len2(%rip), %rdx
    call .L_write_all

    mov $1, %edi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call .L_write_all

    jmp .L_loop

.L_done:
    mov %r12, %rdi
    call sys_close
    mov %r13, %rdi
    call sys_close
    xor %edi, %edi
    call sys_exit

.L_fail_close2:
    mov %r13, %rdi
    call sys_close
.L_fail_close1:
    mov %r12, %rdi
    call sys_close
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
.L_wloop:
    mov %r12, %rsi
    mov %r13, %rdx
    call sys_write
    test %rax, %rax
    js .L_fail
    cmp %rax, %r13
    je .L_wdone
    sub %rax, %r13
    add %rax, %r12
    jmp .L_wloop
.L_wdone:
    pop %r13
    pop %r12
    ret
