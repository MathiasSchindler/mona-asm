.section .bss
.L_buf:
    .space 256
.L_argv:
    .space 256
.L_cmdv:
    .space 256
.L_pipefds:
    .space 8
.L_inptr:
    .space 8
.L_outptr:
    .space 8
.L_append:
    .space 4
.L_pipeflag:
    .space 4
.L_childcount:
    .space 4

.section .data
.L_prompt:
    .ascii "> "
.L_nl:
    .ascii "\n"
.L_exit_str:
    .ascii "exit\0"
.L_pipe_str:
    .ascii "|\0"
.L_in_str:
    .ascii "<\0"
.L_out_str:
    .ascii ">\0"
.L_app_str:
    .ascii ">>\0"

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

    call .L_exec_line

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
    cmp $'|', %al
    je .L_tok_op
    cmp $'<', %al
    je .L_tok_op
    cmp $'>', %al
    je .L_tok_gt
    test %r10b, %r10b
    jne .L_tok_next
    mov %rsi, (%rdi)
    add $8, %rdi
    inc %r9d
    mov $1, %r10b
    jmp .L_tok_next
.L_tok_gt:
    test %r10b, %r10b
    je .L_tok_gt_set
    movb $0, (%rsi)
    xor %r10d, %r10d
.L_tok_gt_set:
    movb 1(%rsi), %al
    cmp $'>', %al
    jne .L_tok_gt_single
    mov %rsi, (%rdi)
    add $8, %rdi
    inc %r9d
    movb $0, 2(%rsi)
    add $2, %rsi
    jmp .L_tok_loop
.L_tok_gt_single:
    mov %rsi, (%rdi)
    add $8, %rdi
    inc %r9d
    movb $0, 1(%rsi)
    add $1, %rsi
    jmp .L_tok_loop
.L_tok_op:
    test %r10b, %r10b
    je .L_tok_op_set
    movb $0, (%rsi)
    xor %r10d, %r10d
.L_tok_op_set:
    mov %rsi, (%rdi)
    add $8, %rdi
    inc %r9d
    movb $0, 1(%rsi)
    add $1, %rsi
    jmp .L_tok_loop
.L_tok_sep:
    movb $0, (%rsi)
    xor %r10d, %r10d
.L_tok_next:
    inc %rsi
    jmp .L_tok_loop
.L_tok_done:
    movq $0, (%rdi)
    ret

.L_exec_line:
    lea .L_argv(%rip), %rbx
    xor %r8d, %r8d
    xor %r13d, %r13d
    mov $-1, %r14d
    movq $0, .L_inptr(%rip)
    movq $0, .L_outptr(%rip)
    movl $0, .L_append(%rip)
    movl $0, .L_childcount(%rip)
    lea .L_cmdv(%rip), %r15

.L_parse_loop:
    cmp %r9d, %r8d
    je .L_cmd_end
    mov (%rbx,%r8,8), %rdi

    lea .L_pipe_str(%rip), %rsi
    call util_streq
    cmp $1, %rax
    je .L_cmd_end_pipe

    mov (%rbx,%r8,8), %rdi
    lea .L_in_str(%rip), %rsi
    call util_streq
    cmp $1, %rax
    je .L_redir_in

    mov (%rbx,%r8,8), %rdi
    lea .L_app_str(%rip), %rsi
    call util_streq
    cmp $1, %rax
    je .L_redir_app

    mov (%rbx,%r8,8), %rdi
    lea .L_out_str(%rip), %rsi
    call util_streq
    cmp $1, %rax
    je .L_redir_out

    mov (%rbx,%r8,8), %rax
    mov %rax, (%r15)
    add $8, %r15
    inc %r13d
    inc %r8d
    jmp .L_parse_loop

.L_redir_in:
    inc %r8d
    cmp %r9d, %r8d
    je .L_cmd_end
    mov (%rbx,%r8,8), %rax
    mov %rax, .L_inptr(%rip)
    inc %r8d
    jmp .L_parse_loop

.L_redir_out:
    inc %r8d
    cmp %r9d, %r8d
    je .L_cmd_end
    mov (%rbx,%r8,8), %rax
    mov %rax, .L_outptr(%rip)
    movl $0, .L_append(%rip)
    inc %r8d
    jmp .L_parse_loop

.L_redir_app:
    inc %r8d
    cmp %r9d, %r8d
    je .L_cmd_end
    mov (%rbx,%r8,8), %rax
    mov %rax, .L_outptr(%rip)
    movl $1, .L_append(%rip)
    inc %r8d
    jmp .L_parse_loop

.L_cmd_end_pipe:
    movl $1, .L_pipeflag(%rip)
    jmp .L_cmd_finish

.L_cmd_end:
    movl $0, .L_pipeflag(%rip)

.L_cmd_finish:
    cmp $0, %r13d
    je .L_after_cmd
    movq $0, (%r15)

    mov .L_pipeflag(%rip), %ecx
    cmp $0, %ecx
    je .L_no_pipe
    lea .L_pipefds(%rip), %rdi
    mov %rdi, %rsi
    call sys_pipe
    test %rax, %rax
    js .L_exec_fail
    mov (%rsi), %r11d
    mov 4(%rsi), %r10d
    jmp .L_spawn_cmd

.L_no_pipe:
    mov $-1, %r10d
    mov $-1, %r11d

.L_spawn_cmd:
    lea .L_cmdv(%rip), %rdi
    mov %r14d, %esi
    mov %r10d, %edx
    call .L_spawn
    mov .L_childcount(%rip), %eax
    inc %eax
    mov %eax, .L_childcount(%rip)

    cmp $-1, %r14d
    je .L_skip_close_in
    mov %r14d, %edi
    call sys_close
.L_skip_close_in:
    cmp $-1, %r10d
    je .L_skip_close_out
    mov %r10d, %edi
    call sys_close
.L_skip_close_out:

    mov %r11d, %r14d
    lea .L_cmdv(%rip), %r15
    xor %r13d, %r13d
    movq $0, .L_inptr(%rip)
    movq $0, .L_outptr(%rip)
    movl $0, .L_append(%rip)

.L_after_cmd:
    mov .L_pipeflag(%rip), %ecx
    cmp $0, %ecx
    je .L_wait_all
    inc %r8d
    jmp .L_parse_loop

.L_wait_all:
    mov .L_childcount(%rip), %r12d
    test %r12d, %r12d
    je .L_exec_done
.L_wait_loop:
    mov $-1, %edi
    xor %rsi, %rsi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_wait4
    dec %r12d
    jne .L_wait_loop
.L_exec_done:
    ret

.L_exec_fail:
    mov $1, %edi
    call sys_exit

.L_spawn:
    mov %rdi, %rbx
    mov %esi, %r12d
    mov %edx, %r13d
    call sys_fork
    test %rax, %rax
    js .L_spawn_fail
    cmp $0, %rax
    jne .L_spawn_parent

.L_child:
    mov %rbx, %rsi
    mov (%rbx), %rdi
    mov .L_inptr(%rip), %r8
    mov .L_outptr(%rip), %r9

    cmp $-1, %r12d
    je .L_child_in_file
    mov %r12d, %edi
    mov $0, %esi
    call sys_dup2
    mov %r12d, %edi
    call sys_close

.L_child_in_file:
    test %r8, %r8
    je .L_child_out
    mov %r8, %rsi
    mov $-100, %rdi
    xor %rdx, %rdx
    xor %r10, %r10
    call sys_openat
    test %rax, %rax
    js .L_spawn_fail
    mov %rax, %rdi
    mov $0, %rsi
    call sys_dup2
    mov %rax, %rdi
    call sys_close

.L_child_out:
    cmp $-1, %r13d
    je .L_child_out_file
    mov %r13d, %edi
    mov $1, %esi
    call sys_dup2
    mov %r13d, %edi
    call sys_close

.L_child_out_file:
    test %r9, %r9
    je .L_child_exec
    mov %r9, %rsi
    mov $-100, %rdi
    mov $577, %rdx
    mov .L_append(%rip), %ecx
    test %ecx, %ecx
    je .L_child_out_trunc
    mov $1089, %rdx
.L_child_out_trunc:
    mov $0666, %r10
    call sys_openat
    test %rax, %rax
    js .L_spawn_fail
    mov %rax, %rdi
    mov $1, %rsi
    call sys_dup2
    mov %rax, %rdi
    call sys_close

.L_child_exec:
    xor %rdx, %rdx
    call sys_execve
    mov $1, %edi
    call sys_exit

.L_spawn_parent:
    ret

.L_spawn_fail:
    mov $1, %edi
    call sys_exit

.include "syscalls.inc"
.include "utils.inc"
