.section .text

.equ SYS_exit, 60
.equ SYS_write, 1
.equ SYS_read, 0
.equ SYS_openat, 257
.equ SYS_close, 3
.equ SYS_fstat, 5
.equ SYS_getdents64, 217
.equ SYS_mkdir, 83
.equ SYS_rmdir, 84
.equ SYS_unlink, 87

.global sys_exit
.global sys_write
.global sys_read
.global sys_openat
.global sys_close
.global sys_fstat
.global sys_getdents64
.global sys_mkdir
.global sys_rmdir
.global sys_unlink

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

sys_mkdir:
    mov $SYS_mkdir, %rax
    syscall
    ret

sys_rmdir:
    mov $SYS_rmdir, %rax
    syscall
    ret

sys_unlink:
    mov $SYS_unlink, %rax
    syscall
    ret
