.section .text

.equ SYS_exit, 60
.equ SYS_write, 1
.equ SYS_read, 0
.equ SYS_openat, 257
.equ SYS_close, 3
.equ SYS_fstat, 5
.equ SYS_getdents64, 217

.global sys_exit
.global sys_write
.global sys_read
.global sys_openat
.global sys_close
.global sys_fstat
.global sys_getdents64

sys_exit:
    mov $SYS_exit, %rax
    syscall
    ret

sys_write:
    mov $SYS_write, %rax
    syscall
    ret

sys_read:
    mov $SYS_read, %rax
    syscall
    ret

sys_openat:
    mov $SYS_openat, %rax
    syscall
    ret

sys_close:
    mov $SYS_close, %rax
    syscall
    ret

sys_fstat:
    mov $SYS_fstat, %rax
    syscall
    ret

sys_getdents64:
    mov $SYS_getdents64, %rax
    syscall
    ret
