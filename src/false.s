.section .text
.global _start

.equ SYS_exit, 60

_start:
    mov $1, %edi
    mov $SYS_exit, %eax
    syscall
