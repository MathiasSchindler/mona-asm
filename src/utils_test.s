.section .data
str_hello:
    .ascii "hello\0"
str_hello2:
    .ascii "hello\0"
str_world:
    .ascii "world\0"
str_zero:
    .ascii "0\0"
str_12345:
    .ascii "12345\0"
str_neg42:
    .ascii "-42\0"
str_99:
    .ascii "99\0"
str_neg7:
    .ascii "-7\0"
str_bad:
    .ascii "abc\0"

buf1:
    .space 32
numbuf:
    .space 32

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    lea str_hello(%rip), %rdi
    call util_strlen
    cmp $5, %rax
    jne .L_fail

    lea str_hello(%rip), %rdi
    lea str_hello2(%rip), %rsi
    call util_streq
    cmp $1, %rax
    jne .L_fail

    lea str_hello(%rip), %rdi
    lea str_world(%rip), %rsi
    call util_streq
    test %rax, %rax
    jne .L_fail

    lea buf1(%rip), %rdi
    lea str_hello(%rip), %rsi
    mov $6, %rdx
    call util_memcpy
    lea buf1(%rip), %rdi
    lea str_hello(%rip), %rsi
    call util_streq
    cmp $1, %rax
    jne .L_fail

    lea numbuf(%rip), %rsi
    mov %rsi, %rbx
    xor %edi, %edi
    call util_utoa
    movb $0, (%rbx,%rax,1)
    mov %rbx, %rdi
    lea str_zero(%rip), %rsi
    call util_streq
    cmp $1, %rax
    jne .L_fail

    lea numbuf(%rip), %rsi
    mov %rsi, %rbx
    mov $12345, %rdi
    call util_utoa
    movb $0, (%rbx,%rax,1)
    mov %rbx, %rdi
    lea str_12345(%rip), %rsi
    call util_streq
    cmp $1, %rax
    jne .L_fail

    lea numbuf(%rip), %rsi
    mov %rsi, %rbx
    mov $-42, %rdi
    call util_itoa
    movb $0, (%rbx,%rax,1)
    mov %rbx, %rdi
    lea str_neg42(%rip), %rsi
    call util_streq
    cmp $1, %rax
    jne .L_fail

    lea str_99(%rip), %rdi
    call util_parse_int
    cmp $1, %rdx
    jne .L_fail
    cmp $99, %rax
    jne .L_fail

    lea str_neg7(%rip), %rdi
    call util_parse_int
    cmp $1, %rdx
    jne .L_fail
    cmp $-7, %rax
    jne .L_fail

    lea str_bad(%rip), %rdi
    call util_parse_int
    test %rdx, %rdx
    jne .L_fail

    xor %rdi, %rdi
    call sys_exit

.L_fail:
    mov $1, %rdi
    call sys_exit
