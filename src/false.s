.section .text
.global _start

.equ SYS_exit, 60

_start:
    xor %edi, %edi
    inc %edi
    mov $SYS_exit, %eax
    syscall
