.section .bss
.L_buf:
    .space 8192
.L_numbuf:
    .space 32

.section .data
.L_nl:
    .ascii "\n"
.L_passwd_path:
    .ascii "/etc/passwd\0"

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    call sys_getuid
    mov %rax, %r12

    mov $-100, %rdi
    lea .L_passwd_path(%rip), %rsi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fallback
    mov %rax, %r13

    mov %r13, %rdi
    lea .L_buf(%rip), %rsi
    mov $8192, %rdx
    call sys_read
    mov %rax, %r14
    mov %r13, %rdi
    call sys_close
    test %r14, %r14
    jle .L_fallback

    lea .L_buf(%rip), %r15
    lea .L_buf(%rip), %rbx
    add %r14, %rbx

.L_line_loop:
    cmp %r15, %rbx
    jbe .L_fallback

    mov %r15, %r8
.L_name_scan:
    cmp %r15, %rbx
    jbe .L_fallback
    movb (%r15), %al
    cmp $'\n', %al
    je .L_next_line
    cmp $':', %al
    je .L_name_done
    inc %r15
    jmp .L_name_scan
.L_name_done:
    mov %r15, %r9
    inc %r15

.L_pass_scan:
    cmp %r15, %rbx
    jbe .L_fallback
    movb (%r15), %al
    cmp $'\n', %al
    je .L_next_line
    cmp $':', %al
    je .L_uid_start
    inc %r15
    jmp .L_pass_scan
.L_uid_start:
    inc %r15
    mov %r15, %r10

.L_uid_scan:
    cmp %r15, %rbx
    jbe .L_fallback
    movb (%r15), %al
    cmp $'\n', %al
    je .L_uid_parse
    cmp $':', %al
    je .L_uid_parse
    inc %r15
    jmp .L_uid_scan

.L_uid_parse:
    mov %r10, %r11
    xor %rax, %rax
    mov $1, %rcx
.L_uid_digits:
    cmp %r15, %r11
    je .L_uid_done
    movb (%r11), %dl
    cmp $'0', %dl
    jb .L_uid_bad
    cmp $'9', %dl
    ja .L_uid_bad
    imul $10, %rax, %rax
    movzbq %dl, %rsi
    sub $'0', %rsi
    add %rsi, %rax
    inc %r11
    jmp .L_uid_digits
.L_uid_bad:
    xor %rcx, %rcx
.L_uid_done:
    test %rcx, %rcx
    je .L_skip_line
    cmp %r12, %rax
    jne .L_skip_line

    mov %r8, %rsi
    mov %r9, %rdx
    sub %r8, %rdx
    mov $1, %edi
    call sys_write

    mov $1, %edi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write

    xor %edi, %edi
    call sys_exit

.L_skip_line:
    cmp %r15, %rbx
    jbe .L_fallback
    movb (%r15), %al
    cmp $'\n', %al
    je .L_next_line
    inc %r15
    jmp .L_skip_line

.L_next_line:
    inc %r15
    jmp .L_line_loop

.L_fallback:
    mov %r12, %rdi
    lea .L_numbuf(%rip), %rsi
    call util_utoa
    mov %rax, %rdx
    mov $1, %edi
    lea .L_numbuf(%rip), %rsi
    call sys_write

    mov $1, %edi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write

    xor %edi, %edi
    call sys_exit
