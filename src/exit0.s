.section .text
.global _start
.include "syscalls.inc"

_start:
    xor %rdi, %rdi
    call sys_exit
