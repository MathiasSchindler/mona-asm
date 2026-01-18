.section .bss
.L_buf:
    .space 8192
.L_line_ptrs:
    .space 4096
.L_line_lens:
    .space 2048

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    xor %edi, %edi
    lea .L_buf(%rip), %rsi
    mov $8192, %rdx
    call sys_read
    test %rax, %rax
    jle .L_exit
    lea .L_buf(%rip), %rbx
    mov %rbx, %r14
    add %rax, %r14
    mov %rbx, %r15
    lea .L_line_ptrs(%rip), %r8
    lea .L_line_lens(%rip), %r9
    xor %r12d, %r12d

.L_parse_loop:
    cmp %r14, %r15
    jae .L_sort
    mov %r15, %r13
.L_find_nl:
    cmp %r14, %r15
    jae .L_line_end
    movb (%r15), %al
    cmp $'\n', %al
    je .L_line_nl
    inc %r15
    jmp .L_find_nl
.L_line_nl:
    inc %r15
.L_line_end:
    mov %r12, %rax
    shl $3, %rax
    mov %r13, (%r8,%rax,1)
    mov %r15, %rcx
    sub %r13, %rcx
    mov %r12, %rax
    shl $2, %rax
    mov %ecx, (%r9,%rax,1)
    inc %r12
    jmp .L_parse_loop

.L_sort:
    xor %r10d, %r10d
.L_outer:
    cmp %r12, %r10
    jae .L_write
    mov %r10, %r11
    inc %r11
.L_inner:
    cmp %r12, %r11
    jae .L_outer_next

    mov %r10, %rax
    shl $3, %rax
    mov (%r8,%rax,1), %rsi
    mov %r10, %rax
    shl $2, %rax
    mov (%r9,%rax,1), %edx

    mov %r11, %rax
    shl $3, %rax
    mov (%r8,%rax,1), %rdi
    mov %r11, %rax
    shl $2, %rax
    mov (%r9,%rax,1), %ecx

    mov %edx, %r13d
    mov %ecx, %r14d

    test %r13d, %r13d
    je .L_cmp_do
    mov %rsi, %rax
    add %r13, %rax
    movb -1(%rax), %al
    cmp $'\n', %al
    jne .L_cmp_do
    dec %r13d
.L_cmp_do:
    test %r14d, %r14d
    je .L_cmp_loop
    mov %rdi, %rax
    add %r14, %rax
    movb -1(%rax), %al
    cmp $'\n', %al
    jne .L_cmp_loop
    dec %r14d

.L_cmp_loop:
    xor %r15d, %r15d
    mov %r13d, %eax
    cmp %r14d, %eax
    jbe .L_cmp_min_b
    mov %r14d, %eax
.L_cmp_min_b:
    mov %eax, %r15d
    xor %eax, %eax
    xor %ebx, %ebx
.L_cmp_byte:
    cmp %r15d, %ebx
    jae .L_cmp_len
    movb (%rsi,%rbx,1), %al
    movb (%rdi,%rbx,1), %dl
    cmp %dl, %al
    jb .L_cmp_less
    ja .L_cmp_greater
    inc %ebx
    jmp .L_cmp_byte
.L_cmp_len:
    cmp %r13d, %r14d
    jb .L_cmp_less
    ja .L_cmp_greater
    jmp .L_cmp_equal
.L_cmp_less:
    jmp .L_inner_next
.L_cmp_greater:
    mov %r10, %rax
    shl $3, %rax
    mov (%r8,%rax,1), %rdi
    mov %r11, %rcx
    shl $3, %rcx
    mov (%r8,%rcx,1), %rsi
    mov %rsi, (%r8,%rax,1)
    mov %rdi, (%r8,%rcx,1)

    mov %r10, %rax
    shl $2, %rax
    mov (%r9,%rax,1), %edx
    mov %r11, %rcx
    shl $2, %rcx
    mov (%r9,%rcx,1), %esi
    mov %esi, (%r9,%rax,1)
    mov %edx, (%r9,%rcx,1)

    jmp .L_inner_next
.L_cmp_equal:
    jmp .L_inner_next

.L_inner_next:
    inc %r11
    jmp .L_inner
.L_outer_next:
    inc %r10
    jmp .L_outer

.L_write:
    xor %r10d, %r10d
.L_write_loop:
    cmp %r12, %r10
    jae .L_exit
    mov %r10, %rax
    shl $3, %rax
    mov (%r8,%rax,1), %rsi
    mov %r10, %rax
    shl $2, %rax
    mov (%r9,%rax,1), %edx
    mov $1, %edi
    call sys_write
    inc %r10
    jmp .L_write_loop

.L_exit:
    xor %edi, %edi
    call sys_exit
