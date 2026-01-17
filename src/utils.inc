.section .text

.global util_strlen
.global util_streq
.global util_memcpy
.global util_utoa
.global util_itoa
.global util_parse_int
.global util_parse_flags

util_strlen:
    xor %rax, %rax
.L_util_strlen_loop:
    movb (%rdi,%rax,1), %cl
    test %cl, %cl
    je .L_util_strlen_done
    inc %rax
    jmp .L_util_strlen_loop
.L_util_strlen_done:
    ret

util_streq:
.L_util_streq_loop:
    movb (%rdi), %cl
    movb (%rsi), %dl
    cmp %cl, %dl
    jne .L_util_streq_not_equal
    test %cl, %cl
    je .L_util_streq_equal
    inc %rdi
    inc %rsi
    jmp .L_util_streq_loop
.L_util_streq_equal:
    mov $1, %rax
    ret
.L_util_streq_not_equal:
    xor %rax, %rax
    ret

util_memcpy:
    mov %rdi, %rax
    test %rdx, %rdx
    je .L_util_memcpy_done
    mov %rdx, %rcx
.L_util_memcpy_loop:
    movb (%rsi), %dl
    movb %dl, (%rdi)
    inc %rsi
    inc %rdi
    dec %rcx
    jne .L_util_memcpy_loop
.L_util_memcpy_done:
    ret

util_utoa:
    push %rbx
    mov %rsi, %rbx
    mov %rsi, %rcx
    mov %rdi, %rax
    test %rax, %rax
    jne .L_util_utoa_loop
    movb $'0', (%rcx)
    mov $1, %rax
    pop %rbx
    ret
.L_util_utoa_loop:
    xor %rdx, %rdx
    mov $10, %r8
    div %r8
    add $'0', %dl
    mov %dl, (%rcx)
    inc %rcx
    test %rax, %rax
    jne .L_util_utoa_loop
    mov %rcx, %r9
    dec %r9
.L_util_utoa_rev:
    cmp %rbx, %r9
    jbe .L_util_utoa_done
    movb (%rbx), %dl
    movb (%r9), %al
    movb %al, (%rbx)
    movb %dl, (%r9)
    inc %rbx
    dec %r9
    jmp .L_util_utoa_rev
.L_util_utoa_done:
    mov %rcx, %rax
    sub %rsi, %rax
    pop %rbx
    ret

util_itoa:
    cmp $0, %rdi
    jge .L_util_itoa_pos
    movb $'-', (%rsi)
    neg %rdi
    lea 1(%rsi), %rsi
    call util_utoa
    inc %rax
    ret
.L_util_itoa_pos:
    call util_utoa
    ret

util_parse_int:
    xor %rax, %rax
    xor %rdx, %rdx
    mov %rdi, %rsi
    movb (%rsi), %cl
    xor %r8d, %r8d
    cmp $'-', %cl
    jne .L_util_parse_digits
    mov $1, %r8b
    inc %rsi
.L_util_parse_digits:
    movb (%rsi), %cl
    cmp $'0', %cl
    jb .L_util_parse_fail
    cmp $'9', %cl
    ja .L_util_parse_fail
.L_util_parse_loop:
    movb (%rsi), %cl
    cmp $'0', %cl
    jb .L_util_parse_end
    cmp $'9', %cl
    ja .L_util_parse_end
    imul $10, %rax, %rax
    movzbq %cl, %r9
    sub $'0', %r9
    add %r9, %rax
    inc %rsi
    jmp .L_util_parse_loop
.L_util_parse_end:
    cmp $1, %r8b
    jne .L_util_parse_ok
    neg %rax
.L_util_parse_ok:
    mov $1, %rdx
    ret
.L_util_parse_fail:
    xor %rax, %rax
    xor %rdx, %rdx
    ret

util_parse_flags:
    push %r12
    push %r13
    xor %rax, %rax
    mov %rdx, %r11
    xor %rdx, %rdx
    mov $1, %r12
    mov %rdi, %r13

.L_util_pf_arg_loop:
    cmp %r13, %r12
    jge .L_util_pf_done
    mov (%rsi,%r12,8), %r8
    movb (%r8), %cl
    cmp $'-', %cl
    jne .L_util_pf_done
    movb 1(%r8), %cl
    cmp $0, %cl
    je .L_util_pf_done
    cmp $'-', %cl
    jne .L_util_pf_parse_group
    cmpb $0, 2(%r8)
    je .L_util_pf_terminator
    jmp .L_util_pf_invalid

.L_util_pf_parse_group:
    lea 1(%r8), %r9
.L_util_pf_char_loop:
    movb (%r9), %cl
    test %cl, %cl
    je .L_util_pf_next_arg
    cmp $'a', %cl
    jb .L_util_pf_invalid
    cmp $'z', %cl
    ja .L_util_pf_invalid
    sub $'a', %cl
    mov $1, %r10
    shl %cl, %r10
    test %r10, %r11
    je .L_util_pf_invalid
    or %r10, %rax
    inc %r9
    jmp .L_util_pf_char_loop

.L_util_pf_next_arg:
    inc %r12
    jmp .L_util_pf_arg_loop

.L_util_pf_terminator:
    inc %r12
    jmp .L_util_pf_done

.L_util_pf_invalid:
    mov $1, %rdx

.L_util_pf_done:
    mov %r13, %rcx
    sub %r12, %rcx
    lea (%rsi,%r12,8), %r8
    pop %r13
    pop %r12
    ret
