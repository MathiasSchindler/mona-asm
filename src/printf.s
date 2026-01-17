.section .bss
.L_ch:
    .space 1
.L_numbuf:
    .space 64

.section .data
.L_nl:
    .ascii "\n"
.L_digits_lower:
    .ascii "0123456789abcdef"
.L_digits_upper:
    .ascii "0123456789ABCDEF"

.section .text
.global _start
.include "syscalls.inc"
.include "utils.inc"

_start:
    mov (%rsp), %r15
    lea 8(%rsp), %r14
    cmp $2, %r15
    jl .L_done

    mov 16(%rsp), %rbx
    mov $2, %r12

.L_loop:
    movb (%rbx), %al
    test %al, %al
    je .L_done
    cmp $'%', %al
    je .L_fmt
    cmp $'\\', %al
    je .L_escape

.L_char:
    movb %al, .L_ch(%rip)
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %rbx
    jmp .L_loop

.L_escape:
    inc %rbx
    movb (%rbx), %al
    test %al, %al
    je .L_done
    cmp $'n', %al
    je .L_esc_n
    cmp $'t', %al
    je .L_esc_t
    cmp $'r', %al
    je .L_esc_r
    cmp $'0', %al
    je .L_esc_0
    cmp $'x', %al
    je .L_esc_x
    cmp $'e', %al
    je .L_esc_e
    cmp $'\\', %al
    je .L_esc_bs
    jmp .L_char

.L_esc_n:
    mov $1, %edi
    lea .L_nl(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %rbx
    jmp .L_loop

.L_esc_t:
    movb $'\t', .L_ch(%rip)
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %rbx
    jmp .L_loop

.L_esc_r:
    movb $'\r', .L_ch(%rip)
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %rbx
    jmp .L_loop

.L_esc_e:
    movb $27, .L_ch(%rip)
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %rbx
    jmp .L_loop

.L_esc_0:
    mov %rbx, %rdi
    call .L_parse_octal_escape
    movb %al, .L_ch(%rip)
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    mov %rsi, %rbx
    jmp .L_loop

.L_esc_x:
    mov %rbx, %rdi
    call .L_parse_hex_escape
    movb %al, .L_ch(%rip)
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    mov %rsi, %rbx
    jmp .L_loop

.L_esc_bs:
    movb $'\\', .L_ch(%rip)
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %rbx
    jmp .L_loop

.L_fmt:
    inc %rbx
    movb (%rbx), %al
    test %al, %al
    je .L_done
    cmp $'%', %al
    je .L_char
    cmp $'s', %al
    je .L_fmt_s
    cmp $'d', %al
    je .L_fmt_d
    cmp $'i', %al
    je .L_fmt_d
    cmp $'u', %al
    je .L_fmt_u
    cmp $'x', %al
    je .L_fmt_x
    cmp $'X', %al
    je .L_fmt_X
    cmp $'o', %al
    je .L_fmt_o
    cmp $'c', %al
    je .L_fmt_c
    cmp $'b', %al
    je .L_fmt_b
    jmp .L_char

.L_fmt_s:
    cmp %r15, %r12
    jge .L_fmt_skip
    mov (%r14,%r12,8), %rdi
    mov %rdi, %rsi
    call util_strlen
    mov %rax, %rdx
    mov $1, %edi
    call sys_write
    inc %r12
.L_fmt_skip:
    inc %rbx
    jmp .L_loop

.L_fmt_d:
    cmp %r15, %r12
    jge .L_fmt_skip
    mov (%r14,%r12,8), %rdi
    call util_parse_int
    test %rdx, %rdx
    jne .L_fmt_d_ok
    xor %rax, %rax
.L_fmt_d_ok:
    mov %rax, %rdi
    lea .L_numbuf(%rip), %rsi
    call util_itoa
    mov %rax, %rdx
    mov $1, %edi
    lea .L_numbuf(%rip), %rsi
    call sys_write
    inc %r12
    inc %rbx
    jmp .L_loop

.L_fmt_u:
    cmp %r15, %r12
    jge .L_fmt_skip
    mov (%r14,%r12,8), %rdi
    call .L_parse_uint
    test %rdx, %rdx
    jne .L_fmt_u_ok
    xor %rax, %rax
.L_fmt_u_ok:
    mov %rax, %rdi
    lea .L_numbuf(%rip), %rsi
    mov $10, %rdx
    lea .L_digits_lower(%rip), %r8
    call .L_utoa_base
    mov %rax, %rdx
    mov $1, %edi
    lea .L_numbuf(%rip), %rsi
    call sys_write
    inc %r12
    inc %rbx
    jmp .L_loop

.L_fmt_x:
    cmp %r15, %r12
    jge .L_fmt_skip
    mov (%r14,%r12,8), %rdi
    call .L_parse_uint
    test %rdx, %rdx
    jne .L_fmt_x_ok
    xor %rax, %rax
.L_fmt_x_ok:
    mov %rax, %rdi
    lea .L_numbuf(%rip), %rsi
    mov $16, %rdx
    lea .L_digits_lower(%rip), %r8
    call .L_utoa_base
    mov %rax, %rdx
    mov $1, %edi
    lea .L_numbuf(%rip), %rsi
    call sys_write
    inc %r12
    inc %rbx
    jmp .L_loop

.L_fmt_X:
    cmp %r15, %r12
    jge .L_fmt_skip
    mov (%r14,%r12,8), %rdi
    call .L_parse_uint
    test %rdx, %rdx
    jne .L_fmt_X_ok
    xor %rax, %rax
.L_fmt_X_ok:
    mov %rax, %rdi
    lea .L_numbuf(%rip), %rsi
    mov $16, %rdx
    lea .L_digits_upper(%rip), %r8
    call .L_utoa_base
    mov %rax, %rdx
    mov $1, %edi
    lea .L_numbuf(%rip), %rsi
    call sys_write
    inc %r12
    inc %rbx
    jmp .L_loop

.L_fmt_o:
    cmp %r15, %r12
    jge .L_fmt_skip
    mov (%r14,%r12,8), %rdi
    call .L_parse_uint
    test %rdx, %rdx
    jne .L_fmt_o_ok
    xor %rax, %rax
.L_fmt_o_ok:
    mov %rax, %rdi
    lea .L_numbuf(%rip), %rsi
    mov $8, %rdx
    lea .L_digits_lower(%rip), %r8
    call .L_utoa_base
    mov %rax, %rdx
    mov $1, %edi
    lea .L_numbuf(%rip), %rsi
    call sys_write
    inc %r12
    inc %rbx
    jmp .L_loop

.L_fmt_c:
    cmp %r15, %r12
    jge .L_fmt_skip
    mov (%r14,%r12,8), %rdi
    call util_parse_int
    test %rdx, %rdx
    je .L_fmt_c_str
    movb %al, .L_ch(%rip)
    jmp .L_fmt_c_out
.L_fmt_c_str:
    mov (%r14,%r12,8), %rsi
    movb (%rsi), %al
    movb %al, .L_ch(%rip)
.L_fmt_c_out:
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %r12
    inc %rbx
    jmp .L_loop

.L_fmt_b:
    cmp %r15, %r12
    jge .L_fmt_skip
    mov (%r14,%r12,8), %rdi
    call .L_write_escaped
    inc %r12
    inc %rbx
    jmp .L_loop

.L_done:
    xor %edi, %edi
    call sys_exit

.L_parse_uint:
    xor %rax, %rax
    xor %rdx, %rdx
    mov %rdi, %rsi
    movb (%rsi), %cl
    cmp $'0', %cl
    jb .L_parse_uint_fail
    cmp $'9', %cl
    ja .L_parse_uint_fail
.L_parse_uint_loop:
    movb (%rsi), %cl
    cmp $'0', %cl
    jb .L_parse_uint_ok
    cmp $'9', %cl
    ja .L_parse_uint_ok
    imul $10, %rax, %rax
    movzbq %cl, %r9
    sub $'0', %r9
    add %r9, %rax
    inc %rsi
    jmp .L_parse_uint_loop
.L_parse_uint_ok:
    mov $1, %rdx
    ret
.L_parse_uint_fail:
    xor %rax, %rax
    xor %rdx, %rdx
    ret

.L_utoa_base:
    mov %rsi, %r9
    mov %rsi, %r10
    mov %rdi, %rax
    mov %rdx, %rcx
    test %rax, %rax
    jne .L_utoa_base_loop
    movb $'0', (%r10)
    mov $1, %rax
    ret
.L_utoa_base_loop:
    xor %rdx, %rdx
    div %rcx
    movzbq (%r8,%rdx,1), %r11
    mov %r11b, (%r10)
    inc %r10
    test %rax, %rax
    jne .L_utoa_base_loop
    mov %r10, %r13
    dec %r13
.L_utoa_base_rev:
    cmp %r9, %r13
    jbe .L_utoa_base_done
    movb (%r9), %dl
    movb (%r13), %al
    movb %al, (%r9)
    movb %dl, (%r13)
    inc %r9
    dec %r13
    jmp .L_utoa_base_rev
.L_utoa_base_done:
    mov %r10, %rax
    sub %rsi, %rax
    ret

.L_write_escaped:
    mov %rdi, %r8
.L_write_esc_loop:
    movb (%r8), %al
    test %al, %al
    je .L_write_esc_done
    cmp $'\\', %al
    je .L_write_esc_escape
    movb %al, .L_ch(%rip)
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %r8
    jmp .L_write_esc_loop
.L_write_esc_escape:
    inc %r8
    movb (%r8), %al
    test %al, %al
    je .L_write_esc_done
    cmp $'n', %al
    je .L_write_esc_n
    cmp $'t', %al
    je .L_write_esc_t
    cmp $'r', %al
    je .L_write_esc_r
    cmp $'0', %al
    je .L_write_esc_0
    cmp $'x', %al
    je .L_write_esc_x
    cmp $'e', %al
    je .L_write_esc_e
    cmp $'\\', %al
    je .L_write_esc_bs
    jmp .L_write_esc_char
.L_write_esc_n:
    movb $'\n', .L_ch(%rip)
    jmp .L_write_esc_out
.L_write_esc_t:
    movb $'\t', .L_ch(%rip)
    jmp .L_write_esc_out
.L_write_esc_r:
    movb $'\r', .L_ch(%rip)
    jmp .L_write_esc_out
.L_write_esc_e:
    movb $27, .L_ch(%rip)
    jmp .L_write_esc_out
.L_write_esc_bs:
    movb $'\\', .L_ch(%rip)
    jmp .L_write_esc_out
.L_write_esc_0:
    mov %r8, %rdi
    call .L_parse_octal_escape
    movb %al, .L_ch(%rip)
    mov %rsi, %r8
    jmp .L_write_esc_out_noskip
.L_write_esc_x:
    mov %r8, %rdi
    call .L_parse_hex_escape
    movb %al, .L_ch(%rip)
    mov %rsi, %r8
    jmp .L_write_esc_out_noskip
.L_write_esc_char:
    movb %al, .L_ch(%rip)
.L_write_esc_out:
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    inc %r8
    jmp .L_write_esc_loop
.L_write_esc_out_noskip:
    mov $1, %edi
    lea .L_ch(%rip), %rsi
    mov $1, %rdx
    call sys_write
    jmp .L_write_esc_loop
.L_write_esc_done:
    ret

.L_parse_octal_escape:
    lea 1(%rdi), %r8
    xor %rax, %rax
    xor %rcx, %rcx
.L_parse_octal_loop:
    cmp $3, %rcx
    je .L_parse_octal_done
    movb (%r8), %dl
    cmp $'0', %dl
    jb .L_parse_octal_done
    cmp $'7', %dl
    ja .L_parse_octal_done
    imul $8, %rax, %rax
    movzbq %dl, %r9
    sub $'0', %r9
    add %r9, %rax
    inc %r8
    inc %rcx
    jmp .L_parse_octal_loop
.L_parse_octal_done:
    mov %r8, %rsi
    ret

.L_parse_hex_escape:
    lea 1(%rdi), %r8
    xor %rax, %rax
    xor %rcx, %rcx
.L_parse_hex_loop:
    cmp $2, %rcx
    je .L_parse_hex_done
    movb (%r8), %dl
    cmp $'0', %dl
    jb .L_parse_hex_done
    cmp $'9', %dl
    jbe .L_parse_hex_digit
    cmp $'a', %dl
    jb .L_parse_hex_upper
    cmp $'f', %dl
    ja .L_parse_hex_done
    sub $'a', %dl
    add $10, %dl
    jmp .L_parse_hex_add
.L_parse_hex_upper:
    cmp $'A', %dl
    jb .L_parse_hex_done
    cmp $'F', %dl
    ja .L_parse_hex_done
    sub $'A', %dl
    add $10, %dl
    jmp .L_parse_hex_add
.L_parse_hex_digit:
    sub $'0', %dl
.L_parse_hex_add:
    imul $16, %rax, %rax
    movzbq %dl, %r9
    add %r9, %rax
    inc %r8
    inc %rcx
    jmp .L_parse_hex_loop
.L_parse_hex_done:
    mov %r8, %rsi
    ret
