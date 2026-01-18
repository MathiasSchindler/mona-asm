.section .bss
.L_timespec:
    .space 16
.L_numbuf:
    .space 32

.section .data
.L_nl:
    .ascii "\n"

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    xor %edi, %edi
    lea .L_timespec(%rip), %rsi
    call sys_clock_gettime
    test %rax, %rax
    js .L_fail

    lea .L_timespec(%rip), %rbx
    mov (%rbx), %rdi
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

.L_fail:
    mov $1, %edi
    call sys_exit
