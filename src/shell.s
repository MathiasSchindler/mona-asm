.section .bss
.L_buf:
    .space 256
.L_argv:
    .space 256

.section .data
.L_prompt:
    .ascii "> "
.L_nl:
    .ascii "\n"
.L_exit_str:
    .ascii "exit\0"

.section .text
.global _start

_start:
.L_loop:
    mov $1, %edi
    lea .L_prompt(%rip), %rsi
    mov $2, %rdx
    call sys_write

    mov $0, %edi
    lea .L_buf(%rip), %rsi
    mov $256, %rdx
    call sys_read
    test %rax, %rax
    jle .L_exit

    mov %rax, %rcx
    lea .L_buf(%rip), %rbx

    cmp $0, %rcx
    je .L_loop

    lea -1(%rbx,%rcx,1), %r8
    movb (%r8), %al
    cmp $'\n', %al
    jne .L_check_empty
    movb $0, (%r8)
    dec %rcx

.L_check_empty:
    test %rcx, %rcx
    je .L_loop

    lea .L_argv(%rip), %rdi
    mov %rbx, %rsi
    call .L_tokenize
    test %r9d, %r9d
    je .L_loop

    mov .L_argv(%rip), %rdi
    lea .L_exit_str(%rip), %rsi
    call util_streq
    cmp $1, %rax
    je .L_exit

    call .L_spawn

    jmp .L_loop

.L_exit:
    xor %edi, %edi
    call sys_exit

.L_tokenize:
    xor %r9d, %r9d
    xor %r10d, %r10d
.L_tok_loop:
    movb (%rsi), %al
    test %al, %al
    je .L_tok_done
    cmp $' ', %al
    je .L_tok_sep
    cmp $'\t', %al
    je .L_tok_sep
    test %r10b, %r10b
    jne .L_tok_next
    mov %rsi, (%rdi)
    add $8, %rdi
    inc %r9d
    mov $1, %r10b
    jmp .L_tok_next
.L_tok_sep:
    movb $0, (%rsi)
    xor %r10d, %r10d
.L_tok_next:
    inc %rsi
    jmp .L_tok_loop
.L_tok_done:
    movq $0, (%rdi)
    ret

.L_spawn:
    call sys_fork
    test %rax, %rax
    js .L_spawn_fail
    cmp $0, %rax
    je .L_child

    mov %rax, %rdi
    xor %rsi, %rsi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_wait4
    ret

.L_child:
    lea .L_argv(%rip), %rsi
    mov (%rsi), %rdi
    xor %rdx, %rdx
    call sys_execve
    mov $1, %edi
    call sys_exit

.L_spawn_fail:
    mov $1, %edi
    call sys_exit

.include "syscalls.inc"
.include "utils.inc"
