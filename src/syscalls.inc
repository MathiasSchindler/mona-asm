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
.equ SYS_utimensat, 280
.equ SYS_lseek, 8
.equ SYS_rename, 82
.equ SYS_link, 86
.equ SYS_chmod, 90
.equ SYS_chown, 92
.equ SYS_clock_gettime, 228
.equ SYS_getuid, 102
.equ SYS_nanosleep, 35
.equ SYS_uname, 63
.equ SYS_fork, 57
.equ SYS_execve, 59
.equ SYS_wait4, 61
.equ SYS_ftruncate, 77
.equ SYS_pipe, 22
.equ SYS_dup2, 33

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
.global sys_utimensat
.global sys_lseek
.global sys_rename
.global sys_link
.global sys_chmod
.global sys_chown
.global sys_clock_gettime
.global sys_getuid
.global sys_nanosleep
.global sys_uname
.global sys_fork
.global sys_execve
.global sys_wait4
.global sys_ftruncate
.global sys_pipe
.global sys_dup2

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

sys_utimensat:
    mov $SYS_utimensat, %rax
    syscall
    ret

sys_lseek:
    mov $SYS_lseek, %rax
    syscall
    ret

sys_rename:
    mov $SYS_rename, %rax
    syscall
    ret

sys_link:
    mov $SYS_link, %rax
    syscall
    ret

sys_chmod:
    mov $SYS_chmod, %rax
    syscall
    ret

sys_chown:
    mov $SYS_chown, %rax
    syscall
    ret

sys_clock_gettime:
    mov $SYS_clock_gettime, %rax
    syscall
    ret

sys_getuid:
    mov $SYS_getuid, %rax
    syscall
    ret

sys_nanosleep:
    mov $SYS_nanosleep, %rax
    syscall
    ret

sys_uname:
    mov $SYS_uname, %rax
    syscall
    ret

sys_fork:
    mov $SYS_fork, %rax
    syscall
    ret

sys_execve:
    mov $SYS_execve, %rax
    syscall
    ret

sys_wait4:
    mov $SYS_wait4, %rax
    syscall
    ret

sys_ftruncate:
    mov $SYS_ftruncate, %rax
    syscall
    ret

sys_pipe:
    mov $SYS_pipe, %rax
    syscall
    ret

sys_dup2:
    mov $SYS_dup2, %rax
    syscall
    ret
