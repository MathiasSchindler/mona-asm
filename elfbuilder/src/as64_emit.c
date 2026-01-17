#include <stdlib.h>
#include <string.h>

#include "as64.h"

void emit_u8(Buf *out, uint8_t v) {
    buf_append(out, &v, 1);
}

static void emit_u32(Buf *out, uint32_t v) {
    buf_append(out, (uint8_t *)&v, 4);
}

static void emit_u64(Buf *out, uint64_t v) {
    buf_append(out, (uint8_t *)&v, 8);
}

static void emit_i32(Buf *out, int32_t v) {
    buf_append(out, (uint8_t *)&v, 4);
}

static int reg_force_rex8(const Reg *r) {
    return r->size == 8 && r->id >= 4;
}

static void check_imm8(int64_t v) {
    if (v < -128 || v > 255) die("imm8 out of range");
}

static void check_imm8s(int64_t v) {
    if (v < -128 || v > 127) die("imm8 out of range");
}

static void check_imm32(int64_t v) {
    if (v < INT32_MIN || v > UINT32_MAX) die("imm32 out of range");
}

static void emit_rex(Buf *out, int w, int r, int x, int b, int force) {
    uint8_t rex = 0x40 | (w ? 8 : 0) | (r ? 4 : 0) | (x ? 2 : 0) | (b ? 1 : 0);
    if (force || rex != 0x40) emit_u8(out, rex);
}

static int scale_bits(int scale) {
    switch (scale) {
        case 1: return 0;
        case 2: return 1;
        case 4: return 2;
        case 8: return 3;
        default: return 0;
    }
}

static size_t emit_modrm_mem_only(Buf *out, int reg_field, const Mem *m, int *disp_size) {
    size_t disp_offset = (size_t)-1;
    *disp_size = 0;

    if (m->is_rip) {
        uint8_t modrm = (uint8_t)(0x00 | ((reg_field & 7) << 3) | 0x05);
        emit_u8(out, modrm);
        disp_offset = out->len;
        emit_i32(out, 0);
        *disp_size = 4;
        return disp_offset;
    }

    if (!m->has_base) die("memory operand missing base register");

    int base = m->base_reg & 7;
    int index = m->has_index ? (m->index_reg & 7) : 4;
    int need_sib = m->has_index || base == 4;

    int32_t disp = m->has_disp ? m->disp : 0;
    int mod = 0;
    if (disp == 0 && base != 5) {
        mod = 0;
    } else if (disp >= -128 && disp <= 127) {
        mod = 1;
        *disp_size = 1;
    } else {
        mod = 2;
        *disp_size = 4;
    }
    if (base == 5 && disp == 0) {
        mod = 1;
        *disp_size = 1;
        disp = 0;
    }

    uint8_t modrm = (uint8_t)((mod << 6) | ((reg_field & 7) << 3) | (need_sib ? 4 : base));
    emit_u8(out, modrm);
    if (need_sib) {
        uint8_t sib = (uint8_t)((scale_bits(m->scale) << 6) | ((index & 7) << 3) | base);
        emit_u8(out, sib);
    }
    if (*disp_size == 1) {
        emit_u8(out, (uint8_t)disp);
    } else if (*disp_size == 4) {
        disp_offset = out->len;
        emit_i32(out, disp);
    }

    return disp_offset;
}

static void emit_syscall(Buf *out) {
    uint8_t op[] = {0x0F, 0x05};
    buf_append(out, op, sizeof(op));
}

static void emit_ret(Buf *out) {
    uint8_t op = 0xC3;
    buf_append(out, &op, 1);
}

void emit_ascii(Buf *out, const char *line) {
    const char *q1 = strchr(line, '"');
    if (!q1) die("invalid .ascii");
    q1++;
    const char *q2 = strrchr(q1, '"');
    if (!q2) die("invalid .ascii");

    for (const char *p = q1; p < q2; p++) {
        if (*p == '\\') {
            p++;
            if (p >= q2) die("invalid .ascii escape");
            switch (*p) {
                case 'n': emit_u8(out, '\n'); break;
                case 'r': emit_u8(out, '\r'); break;
                case 't': emit_u8(out, '\t'); break;
                case '0': emit_u8(out, '\0'); break;
                case '\\': emit_u8(out, '\\'); break;
                case '"': emit_u8(out, '"'); break;
                default: die("invalid .ascii escape");
            }
        } else {
            emit_u8(out, (uint8_t)*p);
        }
    }
}

static void add_reloc(RelocVec *relocs, uint32_t offset, uint32_t sym_index, int32_t addend, Section sec) {
    if (!relocs) return;
    Reloc r = {0};
    r.offset = offset;
    r.sym_index = sym_index;
    r.addend = addend;
    r.type = MOBJ_RELOC_REL32;
    r.section = (sec == SEC_DATA) ? MOBJ_SEC_DATA : MOBJ_SEC_TEXT;
    relocvec_push(relocs, r);
}

static void emit_op_reg_rm(Buf *out, uint8_t opcode, const Reg *reg, const Operand *rm, int w, RelocVec *relocs, SymVec *syms, Section sec, int force_rex) {
    if (rm->kind == OP_REG) {
        int rex_r = (reg->id >> 3) & 1;
        int rex_b = (rm->reg.id >> 3) & 1;
        int force = force_rex || reg_force_rex8(reg) || reg_force_rex8(&rm->reg);
        emit_rex(out, w, rex_r, 0, rex_b, force);
        emit_u8(out, opcode);
        emit_u8(out, (uint8_t)(0xC0 | ((reg->id & 7) << 3) | (rm->reg.id & 7)));
        return;
    }

    if (rm->kind != OP_MEM) die("expected memory operand");
    if (rm->mem.sym && !rm->mem.is_rip) die("symbol memory requires %rip");
    int rex_r = (reg->id >> 3) & 1;
    int rex_x = rm->mem.has_index ? ((rm->mem.index_reg >> 3) & 1) : 0;
    int rex_b = rm->mem.has_base ? ((rm->mem.base_reg >> 3) & 1) : 0;
    int force = force_rex || reg_force_rex8(reg);
    emit_rex(out, w, rex_r, rex_x, rex_b, force);
    emit_u8(out, opcode);
    int disp_size = 0;
    size_t disp_off = emit_modrm_mem_only(out, reg->id, &rm->mem, &disp_size);
    if (rm->mem.sym) {
        if (relocs) {
            int idx = sym_find(syms, rm->mem.sym);
            if (idx < 0) die("unknown symbol in memory operand");
            add_reloc(relocs, (uint32_t)disp_off, (uint32_t)idx, rm->mem.has_disp ? rm->mem.disp : 0, sec);
        }
    }
}

static void emit_op_digit_rm(Buf *out, uint8_t opcode, int digit, const Operand *rm, int w, RelocVec *relocs, SymVec *syms, Section sec, int force_rex) {
    if (rm->kind == OP_REG) {
        int rex_b = (rm->reg.id >> 3) & 1;
        int force = force_rex || reg_force_rex8(&rm->reg);
        emit_rex(out, w, 0, 0, rex_b, force);
        emit_u8(out, opcode);
        emit_u8(out, (uint8_t)(0xC0 | ((digit & 7) << 3) | (rm->reg.id & 7)));
        return;
    }

    if (rm->kind != OP_MEM) die("expected memory operand");
    if (rm->mem.sym && !rm->mem.is_rip) die("symbol memory requires %rip");
    int rex_x = rm->mem.has_index ? ((rm->mem.index_reg >> 3) & 1) : 0;
    int rex_b = rm->mem.has_base ? ((rm->mem.base_reg >> 3) & 1) : 0;
    emit_rex(out, w, 0, rex_x, rex_b, force_rex);
    emit_u8(out, opcode);
    int disp_size = 0;
    size_t disp_off = emit_modrm_mem_only(out, digit, &rm->mem, &disp_size);
    if (rm->mem.sym) {
        if (relocs) {
            int idx = sym_find(syms, rm->mem.sym);
            if (idx < 0) die("unknown symbol in memory operand");
            add_reloc(relocs, (uint32_t)disp_off, (uint32_t)idx, rm->mem.has_disp ? rm->mem.disp : 0, sec);
        }
    }
}

void emit_text_line(const char *line, Buf *out, SymVec *syms, RelocVec *relocs, Section sec) {
    char *work = xstrdup(line);
    char *p = trim(work);
    if (!*p) { free(work); return; }

    char *sp = strpbrk(p, " \t");
    char *mn = p;
    char *ops_str = NULL;
    if (sp) {
        *sp = 0;
        ops_str = trim(sp + 1);
    }

    if (strcmp(mn, "syscall") == 0) {
        emit_syscall(out);
        free(work);
        return;
    }
    if (strcmp(mn, "ret") == 0) {
        emit_ret(out);
        free(work);
        return;
    }

    if (strcmp(mn, "call") == 0 || strcmp(mn, "jmp") == 0 || mn[0] == 'j') {
        uint8_t op1 = 0, op2 = 0;
        uint8_t short_op = 0;
        int is_jcc = 0;
        if (strcmp(mn, "call") == 0) {
            op1 = 0xE8;
        } else if (strcmp(mn, "jmp") == 0) {
            op1 = 0xE9;
            short_op = 0xEB;
        } else {
            is_jcc = 1;
            op1 = 0x0F;
            if (strcmp(mn, "je") == 0) { op2 = 0x84; short_op = 0x74; }
            else if (strcmp(mn, "jne") == 0) { op2 = 0x85; short_op = 0x75; }
            else if (strcmp(mn, "jl") == 0) { op2 = 0x8C; short_op = 0x7C; }
            else if (strcmp(mn, "jge") == 0) { op2 = 0x8D; short_op = 0x7D; }
            else if (strcmp(mn, "jle") == 0) { op2 = 0x8E; short_op = 0x7E; }
            else if (strcmp(mn, "jb") == 0) { op2 = 0x82; short_op = 0x72; }
            else if (strcmp(mn, "ja") == 0) { op2 = 0x87; short_op = 0x77; }
            else if (strcmp(mn, "jbe") == 0) { op2 = 0x86; short_op = 0x76; }
            else if (strcmp(mn, "jae") == 0) { op2 = 0x83; short_op = 0x73; }
            else if (strcmp(mn, "js") == 0) { op2 = 0x88; short_op = 0x78; }
            else die("unsupported jump");
        }

        if (!ops_str || !*ops_str) die("missing branch target");

        int idx = sym_find(syms, ops_str);
        int can_rel8 = 0;
        int32_t rel8 = 0;
        if (idx >= 0 && syms->data[idx].type == MOBJ_SYM_TEXT && (sec == SEC_TEXT)) {
            size_t cur = out->len;
            size_t next = cur + (is_jcc ? 2 : (strcmp(mn, "jmp") == 0 ? 2 : 5));
            int32_t disp = (int32_t)syms->data[idx].value - (int32_t)next;
            if (disp >= -128 && disp <= 127 && (is_jcc || strcmp(mn, "jmp") == 0)) {
                can_rel8 = 1;
                rel8 = disp;
            }
        }

        if (can_rel8) {
            emit_u8(out, short_op);
            emit_u8(out, (uint8_t)rel8);
            free(work);
            return;
        }

        if (is_jcc) {
            emit_u8(out, op1);
            emit_u8(out, op2);
        } else {
            emit_u8(out, op1);
        }

        uint32_t disp_off = (uint32_t)out->len;
        if (idx >= 0 && syms->data[idx].type == MOBJ_SYM_TEXT && (sec == SEC_TEXT)) {
            size_t next = out->len + 4;
            int32_t disp = (int32_t)syms->data[idx].value - (int32_t)next;
            emit_i32(out, disp);
        } else {
            emit_u32(out, 0);
            if (relocs) {
                if (idx < 0) die("unknown branch target");
                add_reloc(relocs, disp_off, (uint32_t)idx, 0, sec);
            }
        }
        free(work);
        return;
    }

    char *ops[3] = {0};
    int op_count = ops_str ? split_operands(ops_str, ops, 3) : 0;

    Operand o1 = {0}, o2 = {0}, o3 = {0};
    if (op_count >= 1 && !parse_operand(ops[0], &o1)) die("invalid operand");
    if (op_count >= 2 && !parse_operand(ops[1], &o2)) die("invalid operand");
    if (op_count >= 3 && !parse_operand(ops[2], &o3)) die("invalid operand");

    if (strcmp(mn, "mov") == 0 || strcmp(mn, "movb") == 0) {
        int size = 0;
        if (strcmp(mn, "movb") == 0) size = 8;
        if (o2.kind == OP_REG) size = o2.reg.size;
        if (o1.kind == OP_REG) size = o1.reg.size;
        if (size == 0) die("unable to infer mov size");

        if (o1.kind == OP_IMM) {
            if (o1.imm_is_sym) {
                int idx = sym_find(syms, o1.sym);
                if (idx < 0) die("unknown immediate symbol");
                if (syms->data[idx].type != MOBJ_SYM_ABS) die("only ABS immediate supported");
                o1.imm = syms->data[idx].value;
            }
            if (o2.kind == OP_REG) {
                if (size == 8) {
                    check_imm8(o1.imm);
                    int rex_b = (o2.reg.id >> 3) & 1;
                    int force = reg_force_rex8(&o2.reg);
                    emit_rex(out, 0, 0, 0, rex_b, force);
                    emit_u8(out, (uint8_t)(0xB0 + (o2.reg.id & 7)));
                    emit_u8(out, (uint8_t)o1.imm);
                    free(work);
                    return;
                }
                if (size == 32) {
                    check_imm32(o1.imm);
                    int rex_b = (o2.reg.id >> 3) & 1;
                    emit_rex(out, 0, 0, 0, rex_b, 0);
                    emit_u8(out, (uint8_t)(0xB8 + (o2.reg.id & 7)));
                    emit_u32(out, (uint32_t)o1.imm);
                    free(work);
                    return;
                }
                if (size == 64) {
                    int rex_b = (o2.reg.id >> 3) & 1;
                    if (o1.imm >= 0 && o1.imm <= UINT32_MAX) {
                        emit_rex(out, 0, 0, 0, rex_b, 0);
                        emit_u8(out, (uint8_t)(0xB8 + (o2.reg.id & 7)));
                        emit_u32(out, (uint32_t)o1.imm);
                        free(work);
                        return;
                    }
                    if (o1.imm >= INT32_MIN && o1.imm <= INT32_MAX) {
                        emit_op_digit_rm(out, 0xC7, 0, &o2, 1, relocs, syms, sec, 0);
                        emit_u32(out, (uint32_t)o1.imm);
                        free(work);
                        return;
                    }
                    emit_rex(out, 1, 0, 0, rex_b, 0);
                    emit_u8(out, (uint8_t)(0xB8 + (o2.reg.id & 7)));
                    emit_u64(out, (uint64_t)o1.imm);
                    free(work);
                    return;
                }
            }
            if (size == 8) {
                check_imm8(o1.imm);
                emit_op_digit_rm(out, 0xC6, 0, &o2, 0, relocs, syms, sec, 0);
                emit_u8(out, (uint8_t)o1.imm);
            } else {
                check_imm32(o1.imm);
                int w = (size == 64);
                emit_op_digit_rm(out, 0xC7, 0, &o2, w, relocs, syms, sec, 0);
                emit_u32(out, (uint32_t)o1.imm);
            }
            free(work);
            return;
        }

        if (o1.kind == OP_REG && (o2.kind == OP_REG || o2.kind == OP_MEM)) {
            uint8_t op = (size == 8) ? 0x88 : 0x89;
            emit_op_reg_rm(out, op, &o1.reg, &o2, size == 64, relocs, syms, sec, 0);
            free(work);
            return;
        }
        if (o1.kind == OP_MEM && o2.kind == OP_REG) {
            uint8_t op = (size == 8) ? 0x8A : 0x8B;
            emit_op_reg_rm(out, op, &o2.reg, &o1, size == 64, relocs, syms, sec, 0);
            free(work);
            return;
        }
    }

    if (strcmp(mn, "movzbq") == 0) {
        if (o2.kind != OP_REG || o2.reg.size != 64) die("movzbq expects reg64 dest");
        if (o1.kind != OP_REG && o1.kind != OP_MEM) die("movzbq expects reg/mem source");
        int rex_r = (o2.reg.id >> 3) & 1;
        int rex_x = (o1.kind == OP_MEM && o1.mem.has_index) ? ((o1.mem.index_reg >> 3) & 1) : 0;
        int rex_b = (o1.kind == OP_MEM && o1.mem.has_base) ? ((o1.mem.base_reg >> 3) & 1) : ((o1.kind == OP_REG) ? ((o1.reg.id >> 3) & 1) : 0);
        int force = (o1.kind == OP_REG) ? reg_force_rex8(&o1.reg) : 0;
        emit_rex(out, 1, rex_r, rex_x, rex_b, force);
        emit_u8(out, 0x0F);
        emit_u8(out, 0xB6);
        if (o1.kind == OP_REG) {
            emit_u8(out, (uint8_t)(0xC0 | ((o2.reg.id & 7) << 3) | (o1.reg.id & 7)));
        } else {
            int disp_size = 0;
            size_t disp_off = emit_modrm_mem_only(out, o2.reg.id, &o1.mem, &disp_size);
            if (o1.mem.sym && relocs) {
                int idx = sym_find(syms, o1.mem.sym);
                if (idx < 0) die("unknown symbol in memory operand");
                add_reloc(relocs, (uint32_t)disp_off, (uint32_t)idx, o1.mem.has_disp ? o1.mem.disp : 0, sec);
            }
        }
        free(work);
        return;
    }

    if (strcmp(mn, "movzwq") == 0) {
        if (o2.kind != OP_REG || o2.reg.size != 64) die("movzwq expects reg64 dest");
        if (o1.kind != OP_MEM) die("movzwq expects mem16 source");
        int rex_r = (o2.reg.id >> 3) & 1;
        int rex_x = o1.mem.has_index ? ((o1.mem.index_reg >> 3) & 1) : 0;
        int rex_b = o1.mem.has_base ? ((o1.mem.base_reg >> 3) & 1) : 0;
        emit_rex(out, 1, rex_r, rex_x, rex_b, 0);
        emit_u8(out, 0x0F);
        emit_u8(out, 0xB7);
        int disp_size = 0;
        size_t disp_off = emit_modrm_mem_only(out, o2.reg.id, &o1.mem, &disp_size);
        if (o1.mem.sym && relocs) {
            int idx = sym_find(syms, o1.mem.sym);
            if (idx < 0) die("unknown symbol in memory operand");
            add_reloc(relocs, (uint32_t)disp_off, (uint32_t)idx, o1.mem.has_disp ? o1.mem.disp : 0, sec);
        }
        free(work);
        return;
    }

    if (strcmp(mn, "lea") == 0) {
        if (o2.kind != OP_REG) die("lea expects reg dest");
        emit_op_reg_rm(out, 0x8D, &o2.reg, &o1, 1, relocs, syms, sec, 0);
        free(work);
        return;
    }

    if (strcmp(mn, "xor") == 0) {
        if (o1.kind != OP_REG || o2.kind != OP_REG) die("xor expects reg, reg");
        if (o1.reg.id != o2.reg.id) die("xor only supports reg, same reg");
        emit_op_reg_rm(out, 0x31, &o1.reg, &o2, o1.reg.size == 64, relocs, syms, sec, 0);
        free(work);
        return;
    }

    if (strcmp(mn, "cmpb") == 0) {
        if (o1.kind == OP_IMM && (o2.kind == OP_REG || o2.kind == OP_MEM)) {
            check_imm8(o1.imm);
            emit_op_digit_rm(out, 0x80, 7, &o2, 0, relocs, syms, sec, 0);
            emit_u8(out, (uint8_t)o1.imm);
            free(work);
            return;
        }
        if (o1.kind == OP_REG && (o2.kind == OP_REG || o2.kind == OP_MEM)) {
            emit_op_reg_rm(out, 0x38, &o1.reg, &o2, 0, relocs, syms, sec, 0);
            free(work);
            return;
        }
        if (o1.kind == OP_MEM && o2.kind == OP_REG) {
            emit_op_reg_rm(out, 0x3A, &o2.reg, &o1, 0, relocs, syms, sec, 0);
            free(work);
            return;
        }
    }

    if (strcmp(mn, "cmp") == 0) {
        if (o1.kind == OP_IMM && o2.kind == OP_REG) {
            if (o1.imm == 0) {
                uint8_t op = (o2.reg.size == 8) ? 0x84 : 0x85;
                emit_op_reg_rm(out, op, &o2.reg, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                free(work);
                return;
            }
            if (o2.reg.size == 8) {
                check_imm8(o1.imm);
                if (o2.reg.id == 0) {
                    emit_u8(out, 0x3C);
                    emit_u8(out, (uint8_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0x80, 7, &o2, 0, relocs, syms, sec, 0);
                    emit_u8(out, (uint8_t)o1.imm);
                }
            } else if (o1.imm >= -128 && o1.imm <= 127) {
                check_imm8s(o1.imm);
                emit_op_digit_rm(out, 0x83, 7, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                emit_u8(out, (uint8_t)o1.imm);
            } else {
                check_imm32(o1.imm);
                if (o2.reg.id == 0) {
                    if (o2.reg.size == 64) emit_rex(out, 1, 0, 0, 0, 0);
                    emit_u8(out, 0x3D);
                    emit_u32(out, (uint32_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0x81, 7, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                    emit_u32(out, (uint32_t)o1.imm);
                }
            }
            free(work);
            return;
        }
        if (o1.kind == OP_IMM && o2.kind == OP_MEM) {
            if (o1.imm >= -128 && o1.imm <= 127) {
                check_imm8s(o1.imm);
                emit_op_digit_rm(out, 0x83, 7, &o2, 0, relocs, syms, sec, 0);
                emit_u8(out, (uint8_t)o1.imm);
            } else {
                check_imm32(o1.imm);
                emit_op_digit_rm(out, 0x81, 7, &o2, 0, relocs, syms, sec, 0);
                emit_u32(out, (uint32_t)o1.imm);
            }
            free(work);
            return;
        }
        if (o1.kind == OP_REG && o2.kind == OP_REG) {
            emit_op_reg_rm(out, 0x39, &o1.reg, &o2, o1.reg.size == 64, relocs, syms, sec, 0);
            free(work);
            return;
        }
    }

    if (strcmp(mn, "test") == 0) {
        if (o1.kind == OP_IMM && o2.kind == OP_REG) {
            if (o2.reg.size == 8) {
                check_imm8(o1.imm);
                if (o2.reg.id == 0) {
                    emit_u8(out, 0xA8);
                    emit_u8(out, (uint8_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0xF6, 0, &o2, 0, relocs, syms, sec, 0);
                    emit_u8(out, (uint8_t)o1.imm);
                }
            } else {
                emit_op_digit_rm(out, 0xF7, 0, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                if (o2.reg.id == 0) {
                    if (o2.reg.size == 64) emit_rex(out, 1, 0, 0, 0, 0);
                    emit_u8(out, 0xA9);
                    emit_u32(out, (uint32_t)o1.imm);
                } else {
                    emit_u32(out, (uint32_t)o1.imm);
                }
            }
            free(work);
            return;
        }
        if (o1.kind == OP_IMM && o2.kind == OP_MEM) {
            check_imm32(o1.imm);
            emit_op_digit_rm(out, 0xF7, 0, &o2, 0, relocs, syms, sec, 0);
            emit_u32(out, (uint32_t)o1.imm);
            free(work);
            return;
        }
        if (o1.kind == OP_REG && o2.kind == OP_REG) {
            uint8_t op = (o1.reg.size == 8) ? 0x84 : 0x85;
            emit_op_reg_rm(out, op, &o1.reg, &o2, o1.reg.size == 64, relocs, syms, sec, 0);
            free(work);
            return;
        }
    }

    if (strcmp(mn, "add") == 0) {
        if (o1.kind == OP_IMM && o2.kind == OP_REG) {
            if (o2.reg.size == 8) {
                check_imm8(o1.imm);
                if (o2.reg.id == 0) {
                    emit_u8(out, 0x04);
                    emit_u8(out, (uint8_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0x80, 0, &o2, 0, relocs, syms, sec, 0);
                    emit_u8(out, (uint8_t)o1.imm);
                }
            } else if (o1.imm >= -128 && o1.imm <= 127) {
                check_imm8s(o1.imm);
                emit_op_digit_rm(out, 0x83, 0, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                emit_u8(out, (uint8_t)o1.imm);
            } else {
                check_imm32(o1.imm);
                if (o2.reg.id == 0) {
                    if (o2.reg.size == 64) emit_rex(out, 1, 0, 0, 0, 0);
                    emit_u8(out, 0x05);
                    emit_u32(out, (uint32_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0x81, 0, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                    emit_u32(out, (uint32_t)o1.imm);
                }
            }
            free(work);
            return;
        }
        if (o1.kind == OP_REG && o2.kind == OP_REG) {
            emit_op_reg_rm(out, 0x01, &o1.reg, &o2, o1.reg.size == 64, relocs, syms, sec, 0);
            free(work);
            return;
        }
    }

    if (strcmp(mn, "sub") == 0) {
        if (o1.kind == OP_REG && o2.kind == OP_REG) {
            emit_op_reg_rm(out, 0x29, &o1.reg, &o2, o1.reg.size == 64, relocs, syms, sec, 0);
            free(work);
            return;
        }
        if (o1.kind == OP_IMM && o2.kind == OP_REG) {
            if (o2.reg.size == 8) {
                check_imm8(o1.imm);
                if (o2.reg.id == 0) {
                    emit_u8(out, 0x2C);
                    emit_u8(out, (uint8_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0x80, 5, &o2, 0, relocs, syms, sec, 0);
                    emit_u8(out, (uint8_t)o1.imm);
                }
            } else if (o1.imm >= -128 && o1.imm <= 127) {
                check_imm8s(o1.imm);
                emit_op_digit_rm(out, 0x83, 5, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                emit_u8(out, (uint8_t)o1.imm);
            } else {
                check_imm32(o1.imm);
                if (o2.reg.id == 0) {
                    if (o2.reg.size == 64) emit_rex(out, 1, 0, 0, 0, 0);
                    emit_u8(out, 0x2D);
                    emit_u32(out, (uint32_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0x81, 5, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                    emit_u32(out, (uint32_t)o1.imm);
                }
            }
            free(work);
            return;
        }
    }

    if (strcmp(mn, "and") == 0) {
        if (o1.kind == OP_IMM && o2.kind == OP_REG) {
            if (o2.reg.size == 8) {
                check_imm8(o1.imm);
                emit_op_digit_rm(out, 0x80, 4, &o2, 0, relocs, syms, sec, 0);
                emit_u8(out, (uint8_t)o1.imm);
            } else if (o1.imm >= -128 && o1.imm <= 127) {
                check_imm8s(o1.imm);
                emit_op_digit_rm(out, 0x83, 4, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                emit_u8(out, (uint8_t)o1.imm);
            } else {
                check_imm32(o1.imm);
                if (o2.reg.id == 0) {
                    if (o2.reg.size == 64) emit_rex(out, 1, 0, 0, 0, 0);
                    emit_u8(out, 0x25);
                    emit_u32(out, (uint32_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0x81, 4, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                    emit_u32(out, (uint32_t)o1.imm);
                }
            }
            free(work);
            return;
        }
    }

    if (strcmp(mn, "or") == 0) {
        if (o1.kind == OP_REG && o2.kind == OP_REG) {
            emit_op_reg_rm(out, 0x09, &o1.reg, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
            free(work);
            return;
        }
        if (o1.kind == OP_IMM && o2.kind == OP_REG) {
            if (o2.reg.size == 8) {
                check_imm8(o1.imm);
                if (o2.reg.id == 0) {
                    emit_u8(out, 0x0C);
                    emit_u8(out, (uint8_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0x80, 1, &o2, 0, relocs, syms, sec, 0);
                    emit_u8(out, (uint8_t)o1.imm);
                }
            } else if (o1.imm >= -128 && o1.imm <= 127) {
                check_imm8s(o1.imm);
                emit_op_digit_rm(out, 0x83, 1, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                emit_u8(out, (uint8_t)o1.imm);
            } else {
                check_imm32(o1.imm);
                if (o2.reg.id == 0) {
                    if (o2.reg.size == 64) emit_rex(out, 1, 0, 0, 0, 0);
                    emit_u8(out, 0x0D);
                    emit_u32(out, (uint32_t)o1.imm);
                } else {
                    emit_op_digit_rm(out, 0x81, 1, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
                    emit_u32(out, (uint32_t)o1.imm);
                }
            }
            free(work);
            return;
        }
    }

    if (strcmp(mn, "inc") == 0 || strcmp(mn, "dec") == 0) {
        if (o1.kind != OP_REG) die("inc/dec expects reg");
        int digit = (strcmp(mn, "inc") == 0) ? 0 : 1;
        emit_op_digit_rm(out, 0xFF, digit, &o1, o1.reg.size == 64, relocs, syms, sec, 0);
        free(work);
        return;
    }

    if (strcmp(mn, "neg") == 0) {
        if (o1.kind != OP_REG) die("neg expects reg");
        emit_op_digit_rm(out, 0xF7, 3, &o1, 1, relocs, syms, sec, 0);
        free(work);
        return;
    }

    if (strcmp(mn, "imul") == 0) {
        if (o1.kind == OP_IMM && o2.kind == OP_REG && o3.kind == OP_REG) {
            int rex_r = (o3.reg.id >> 3) & 1;
            int rex_b = (o2.reg.id >> 3) & 1;
            emit_rex(out, 1, rex_r, 0, rex_b, 0);
            emit_u8(out, 0x69);
            emit_u8(out, (uint8_t)(0xC0 | ((o3.reg.id & 7) << 3) | (o2.reg.id & 7)));
            emit_u32(out, (uint32_t)o1.imm);
            free(work);
            return;
        }
    }

    if (strcmp(mn, "shl") == 0) {
        if (o1.kind == OP_REG && o1.reg.size == 8 && o1.reg.id == 1 && o2.kind == OP_REG) {
            uint8_t op = (o2.reg.size == 8) ? 0xD2 : 0xD3;
            emit_op_digit_rm(out, op, 4, &o2, o2.reg.size == 64, relocs, syms, sec, 0);
            free(work);
            return;
        }
    }

    if (strcmp(mn, "div") == 0) {
        if (o1.kind != OP_REG) die("div expects reg");
        emit_op_digit_rm(out, 0xF7, 6, &o1, 1, relocs, syms, sec, 0);
        free(work);
        return;
    }

    if (strcmp(mn, "push") == 0 || strcmp(mn, "pop") == 0) {
        if (o1.kind != OP_REG) die("push/pop expects reg");
        int rex_b = (o1.reg.id >> 3) & 1;
        if (rex_b) emit_rex(out, 0, 0, 0, rex_b, 0);
        uint8_t base = (strcmp(mn, "push") == 0) ? 0x50 : 0x58;
        emit_u8(out, (uint8_t)(base + (o1.reg.id & 7)));
        free(work);
        return;
    }

    die_line("unsupported instruction", line);
}