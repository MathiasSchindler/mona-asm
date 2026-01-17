.section .bss
.L_buf:
    .space 4096
.L_ring:
    .space 65536
.L_nl_pos:
    .space 80

.section .data
.L_usage_str:
    .ascii "usage: tail [FILE]\n"
.equ L_usage_len, . - .L_usage_str

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

.equ SEEK_SET, 0
.equ SEEK_END, 2
.equ RING_SIZE, 65536
.equ RING_MASK, 65535

_start:
    mov (%rsp), %rdi
    lea 8(%rsp), %rsi
    xor %rdx, %rdx
    call util_parse_flags
    test %rdx, %rdx
    jne .L_usage_err

    cmp $0, %rcx
    je .L_tail_stdin
    cmp $1, %rcx
    jne .L_usage_err

    mov (%r8), %rsi
    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_fail
    mov %rax, %r13

    xor %rsi, %rsi
    mov $SEEK_END, %rdx
    mov %r13, %rdi
    call sys_lseek
    test %rax, %rax
    js .L_tail_stream
    mov %rax, %r15
    mov %r15, %r14
    xor %r12, %r12
    xor %r10, %r10
    mov $10, %r8

    cmp $0, %r15
    je .L_scan_blocks
    mov %r13, %rdi
    mov %r15, %rsi
    dec %rsi
    mov $SEEK_SET, %rdx
    call sys_lseek
    test %rax, %rax
    js .L_fail
    lea .L_buf(%rip), %rsi
    mov $1, %rdx
    mov %r13, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail
    cmp $0, %rax
    je .L_scan_blocks
    movb .L_buf(%rip), %al
    cmp $'\n', %al
    jne .L_scan_blocks
    mov $11, %r8

.L_scan_blocks:
    cmp $0, %r14
    je .L_found_start
    cmp $10, %r12
    jge .L_found_start

    mov $4096, %rbx
    cmp %rbx, %r14
    jbe .L_block_small
    jmp .L_block_ok

.L_block_small:
    mov %r14, %rbx

.L_block_ok:
    sub %rbx, %r14
    mov %r13, %rdi
    mov %r14, %rsi
    mov $SEEK_SET, %rdx
    call sys_lseek
    test %rax, %rax
    js .L_fail

    lea .L_buf(%rip), %rsi
    mov %rbx, %rdx
    mov %r13, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail
    cmp $0, %rax
    je .L_found_start

    mov %rax, %rbx
    dec %rbx
    lea .L_buf(%rip), %r9

.L_scan_back:
    movb (%r9,%rbx,1), %al
    cmp $'\n', %al
    jne .L_scan_back_next
    inc %r12
    cmp %r8, %r12
    jne .L_scan_back_next
    lea 1(%rbx), %r10
    add %r14, %r10
    jmp .L_found_start

.L_scan_back_next:
    cmp $0, %rbx
    je .L_scan_blocks
    dec %rbx
    jmp .L_scan_back

.L_found_start:
    cmp %r8, %r12
    jl .L_start_zero
    jmp .L_start_set

.L_start_zero:
    xor %r10, %r10

.L_start_set:
    mov %r13, %rdi
    mov %r10, %rsi
    mov $SEEK_SET, %rdx
    call sys_lseek
    test %rax, %rax
    js .L_fail

.L_tail_read:
    lea .L_buf(%rip), %rsi
    mov $4096, %rdx
    mov %r13, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail
    cmp $0, %rax
    je .L_tail_done

    mov %rax, %r8
    lea .L_buf(%rip), %rsi
    mov %r8, %rdx

.L_tail_write:
    mov $1, %rdi
    call sys_write
    test %rax, %rax
    js .L_fail
    cmp %rax, %rdx
    je .L_tail_read
    sub %rax, %rdx
    add %rax, %rsi
    jmp .L_tail_write

.L_tail_done:
    mov %r13, %rdi
    call sys_close
    xor %rdi, %rdi
    call sys_exit

.L_tail_stdin:
    xor %r13, %r13
    jmp .L_tail_stream

.L_tail_stream:
    xor %r14, %r14
    xor %r15, %r15

.L_stream_read:
    lea .L_buf(%rip), %rsi
    mov $4096, %rdx
    mov %r13, %rdi
    call sys_read
    test %rax, %rax
    js .L_fail
    cmp $0, %rax
    je .L_stream_done

    mov %rax, %rbx
    xor %rcx, %rcx
    lea .L_buf(%rip), %r9
    lea .L_ring(%rip), %r8
    lea .L_nl_pos(%rip), %rsi

.L_stream_loop:
    cmp %rcx, %rbx
    je .L_stream_read
    movb (%r9,%rcx,1), %al
    mov %r15, %r10
    and $RING_MASK, %r10
    movb %al, (%r8,%r10,1)
    inc %r15
    cmp $'\n', %al
    jne .L_stream_next
    mov %r14, %r11
    and $9, %r11
    mov %r15, %r10
    dec %r10
    mov %r10, (%rsi,%r11,8)
    inc %r14

.L_stream_next:
    inc %rcx
    jmp .L_stream_loop

.L_stream_done:
    cmp $10, %r14
    jb .L_stream_start_zero
    mov %r14, %r11
    sub $10, %r11
    and $9, %r11
    mov (%rsi,%r11,8), %r12
    inc %r12
    jmp .L_stream_have_start

.L_stream_start_zero:
    xor %r12, %r12

.L_stream_have_start:
    mov %r15, %r10
    sub $RING_SIZE, %r10
    cmp %r12, %r10
    jle .L_stream_ok
    mov %r10, %r12

.L_stream_ok:
    mov %r15, %r10
    sub %r12, %r10
    cmp $0, %r10
    je .L_tail_done

    mov %r12, %r11
    and $RING_MASK, %r11
    mov %r10, %r8
    mov $RING_SIZE, %r9
    sub %r11, %r9
    cmp %r9, %r8
    jbe .L_stream_one

    lea (%r8,%r11,1), %rsi
    mov %r9, %rdx
.L_stream_write1:
    mov $1, %rdi
    call sys_write
    test %rax, %rax
    js .L_fail
    cmp %rax, %rdx
    je .L_stream_write2
    sub %rax, %rdx
    add %rax, %rsi
    jmp .L_stream_write1

.L_stream_write2:
    mov %r10, %rdx
    sub %r9, %rdx
    lea (%r8), %rsi
.L_stream_write2_loop:
    mov $1, %rdi
    call sys_write
    test %rax, %rax
    js .L_fail
    cmp %rax, %rdx
    je .L_tail_done
    sub %rax, %rdx
    add %rax, %rsi
    jmp .L_stream_write2_loop

.L_stream_one:
    lea (%r8,%r11,1), %rsi
    mov %r8, %rdx
.L_stream_write_one:
    mov $1, %rdi
    call sys_write
    test %rax, %rax
    js .L_fail
    cmp %rax, %rdx
    je .L_tail_done
    sub %rax, %rdx
    add %rax, %rsi
    jmp .L_stream_write_one

.L_fail:
    mov $1, %rdi
    call sys_exit

.L_usage_err:
    mov $2, %rdi
    lea .L_usage_str(%rip), %rsi
    mov $L_usage_len, %rdx
    call sys_write
    mov $1, %rdi
    call sys_exit
