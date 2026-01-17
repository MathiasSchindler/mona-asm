#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "as64.h"

void die(const char *msg) {
    fprintf(stderr, "as64: %s\n", msg);
    exit(1);
}

void die_line(const char *msg, const char *line) {
    fprintf(stderr, "as64: %s: %s\n", msg, line);
    exit(1);
}

void *xmalloc(size_t n) {
    void *p = malloc(n);
    if (!p) die("out of memory");
    return p;
}

char *xstrdup(const char *s) {
    size_t n = strlen(s);
    char *p = xmalloc(n + 1);
    memcpy(p, s, n + 1);
    return p;
}

void buf_append(Buf *b, const uint8_t *src, size_t n) {
    while (b->len + n > b->cap) {
        b->cap = b->cap ? b->cap * 2 : 64;
        b->data = realloc(b->data, b->cap);
        if (!b->data) die("out of memory");
    }
    memcpy(b->data + b->len, src, n);
    b->len += n;
}

void symvec_push(SymVec *v, Symbol s) {
    if (v->len + 1 > v->cap) {
        v->cap = v->cap ? v->cap * 2 : 32;
        v->data = realloc(v->data, v->cap * sizeof(Symbol));
        if (!v->data) die("out of memory");
    }
    v->data[v->len++] = s;
}

void relocvec_push(RelocVec *v, Reloc r) {
    if (v->len + 1 > v->cap) {
        v->cap = v->cap ? v->cap * 2 : 32;
        v->data = realloc(v->data, v->cap * sizeof(Reloc));
        if (!v->data) die("out of memory");
    }
    v->data[v->len++] = r;
}

void linevec_push(LineVec *v, char *line) {
    if (v->len + 1 > v->cap) {
        v->cap = v->cap ? v->cap * 2 : 128;
        v->data = realloc(v->data, v->cap * sizeof(char *));
        if (!v->data) die("out of memory");
    }
    v->data[v->len++] = line;
}

char *trim(char *s) {
    while (*s == ' ' || *s == '\t' || *s == '\n' || *s == '\r') s++;
    size_t n = strlen(s);
    while (n && (s[n - 1] == ' ' || s[n - 1] == '\t' || s[n - 1] == '\n' || s[n - 1] == '\r')) {
        s[--n] = 0;
    }
    return s;
}

void strip_comment(char *s) {
    for (; *s; s++) {
        if (*s == '#') { *s = 0; return; }
    }
}

int starts_with(const char *s, const char *pfx) {
    return strncmp(s, pfx, strlen(pfx)) == 0;
}

char *path_dirname(const char *path) {
    const char *slash = strrchr(path, '/');
    if (!slash) return xstrdup(".");
    size_t len = (size_t)(slash - path);
    char *out = xmalloc(len + 1);
    memcpy(out, path, len);
    out[len] = 0;
    return out;
}

char *path_join(const char *dir, const char *file) {
    size_t dlen = strlen(dir);
    size_t flen = strlen(file);
    char *out = xmalloc(dlen + flen + 2);
    memcpy(out, dir, dlen);
    out[dlen] = '/';
    memcpy(out + dlen + 1, file, flen + 1);
    return out;
}

void read_lines_recursive(const char *path, LineVec *out) {
    FILE *f = fopen(path, "r");
    if (!f) {
        fprintf(stderr, "as64: failed to open %s: %s\n", path, strerror(errno));
        exit(1);
    }

    char *dir = path_dirname(path);
    char buf[4096];
    while (fgets(buf, sizeof(buf), f)) {
        char *line = xstrdup(buf);
        strip_comment(line);
        char *t = trim(line);
        if (starts_with(t, ".include")) {
            char *q = strchr(t, '"');
            if (!q) die("invalid .include");
            q++;
            char *q2 = strchr(q, '"');
            if (!q2) die("invalid .include");
            *q2 = 0;
            char *inc_path = path_join(dir, q);
            read_lines_recursive(inc_path, out);
            free(inc_path);
            free(line);
            continue;
        }
        linevec_push(out, line);
    }
    free(dir);
    fclose(f);
}

int sym_find(SymVec *syms, const char *name) {
    for (size_t i = 0; i < syms->len; i++) {
        if (strcmp(syms->data[i].name, name) == 0) return (int)i;
    }
    return -1;
}

uint32_t parse_u32(const char *s, int *ok) {
    *ok = 1;
    if (starts_with(s, "0x") || starts_with(s, "0X")) {
        char *end = NULL;
        unsigned long v = strtoul(s, &end, 16);
        if (!end || *end) { *ok = 0; return 0; }
        return (uint32_t)v;
    }
    char *end = NULL;
    unsigned long v = strtoul(s, &end, 10);
    if (!end || *end) { *ok = 0; return 0; }
    return (uint32_t)v;
}

int64_t parse_i64(const char *s, int *ok) {
    *ok = 1;
    if (starts_with(s, "0x") || starts_with(s, "0X")) {
        char *end = NULL;
        long long v = strtoll(s, &end, 16);
        if (!end || *end) { *ok = 0; return 0; }
        return v;
    }
    char *end = NULL;
    long long v = strtoll(s, &end, 10);
    if (!end || *end) { *ok = 0; return 0; }
    return v;
}

int parse_char_literal(const char *s, int *ok) {
    *ok = 0;
    size_t n = strlen(s);
    if (n < 2 || s[0] != '\'' || s[n - 1] != '\'') return 0;
    if (n == 3) {
        *ok = 1;
        return (unsigned char)s[1];
    }
    if (n == 4 && s[1] == '\\') {
        *ok = 1;
        switch (s[2]) {
            case 'n': return '\n';
            case 'r': return '\r';
            case 't': return '\t';
            case '0': return '\0';
            case '\\': return '\\';
            case '\'': return '\'';
            default: *ok = 0; return 0;
        }
    }
    return 0;
}

int64_t parse_equ_expr(const char *s, SymVec *syms, uint32_t dot, int *ok) {
    *ok = 1;
    const char *p = s;
    int64_t value = 0;
    int have_value = 0;
    int sign = 1;

    for (;;) {
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '\0') break;

        if (*p == '+') { sign = 1; p++; continue; }
        if (*p == '-') { sign = -1; p++; continue; }

        int64_t term = 0;
        if (*p == '.' && (p[1] == '\0' || p[1] == ' ' || p[1] == '\t' || p[1] == '+' || p[1] == '-')) {
            term = (int64_t)dot;
            p++;
        } else if (*p == '\'' ) {
            char lit_buf[8] = {0};
            size_t i = 0;
            while (*p && i + 1 < sizeof(lit_buf)) {
                lit_buf[i++] = *p++;
                if (lit_buf[i - 1] == '\'' && i > 1) break;
            }
            lit_buf[i] = 0;
            int lit_ok = 0;
            int ch = parse_char_literal(lit_buf, &lit_ok);
            if (!lit_ok) { *ok = 0; return 0; }
            term = ch;
        } else if ((*p >= '0' && *p <= '9') || (*p == '0' && (p[1] == 'x' || p[1] == 'X'))) {
            char num_buf[64] = {0};
            size_t i = 0;
            while (*p && *p != ' ' && *p != '\t' && *p != '+' && *p != '-') {
                if (i + 1 >= sizeof(num_buf)) { *ok = 0; return 0; }
                num_buf[i++] = *p++;
            }
            num_buf[i] = 0;
            int num_ok = 0;
            int64_t v = parse_i64(num_buf, &num_ok);
            if (!num_ok) { *ok = 0; return 0; }
            term = v;
        } else {
            char sym_buf[128] = {0};
            size_t i = 0;
            while (*p && *p != ' ' && *p != '\t' && *p != '+' && *p != '-') {
                if (i + 1 >= sizeof(sym_buf)) { *ok = 0; return 0; }
                sym_buf[i++] = *p++;
            }
            sym_buf[i] = 0;
            int idx = sym_find(syms, sym_buf);
            if (idx < 0) { *ok = 0; return 0; }
            term = syms->data[idx].value;
        }

        if (!have_value) {
            value = sign * term;
            have_value = 1;
        } else {
            value += sign * term;
        }
        sign = 1;
    }

    if (!have_value) { *ok = 0; return 0; }
    return value;
}

int parse_reg(const char *r, Reg *out) {
    if (!r || r[0] != '%') return 0;

    struct { const char *name; int id; int size; } table[] = {
        {"%rax", 0, 64}, {"%rcx", 1, 64}, {"%rdx", 2, 64}, {"%rbx", 3, 64},
        {"%rsp", 4, 64}, {"%rbp", 5, 64}, {"%rsi", 6, 64}, {"%rdi", 7, 64},
        {"%r8", 8, 64}, {"%r9", 9, 64}, {"%r10", 10, 64}, {"%r11", 11, 64},
        {"%r12", 12, 64}, {"%r13", 13, 64}, {"%r14", 14, 64}, {"%r15", 15, 64},

        {"%eax", 0, 32}, {"%ecx", 1, 32}, {"%edx", 2, 32}, {"%ebx", 3, 32},
        {"%esp", 4, 32}, {"%ebp", 5, 32}, {"%esi", 6, 32}, {"%edi", 7, 32},
        {"%r8d", 8, 32}, {"%r9d", 9, 32}, {"%r10d", 10, 32}, {"%r11d", 11, 32},
        {"%r12d", 12, 32}, {"%r13d", 13, 32}, {"%r14d", 14, 32}, {"%r15d", 15, 32},

        {"%al", 0, 8}, {"%cl", 1, 8}, {"%dl", 2, 8}, {"%bl", 3, 8},
        {"%spl", 4, 8}, {"%bpl", 5, 8}, {"%sil", 6, 8}, {"%dil", 7, 8},
        {"%r8b", 8, 8}, {"%r9b", 9, 8}, {"%r10b", 10, 8}, {"%r11b", 11, 8},
        {"%r12b", 12, 8}, {"%r13b", 13, 8}, {"%r14b", 14, 8}, {"%r15b", 15, 8},
    };

    for (size_t i = 0; i < sizeof(table) / sizeof(table[0]); i++) {
        if (strcmp(r, table[i].name) == 0) {
            out->id = table[i].id;
            out->size = table[i].size;
            return 1;
        }
    }
    return 0;
}

int split_operands(char *s, char **ops, int max_ops) {
    int depth = 0;
    int count = 0;
    char *start = s;
    for (char *p = s; ; p++) {
        char c = *p;
        if (c == '(') depth++;
        else if (c == ')') depth--;
        if ((c == ',' && depth == 0) || c == '\0') {
            if (count < max_ops) {
                if (c == ',') *p = '\0';
                ops[count++] = trim(start);
            }
            start = p + 1;
        }
        if (c == '\0') break;
    }
    return count;
}

int parse_mem(const char *s, Mem *out) {
    const char *lparen = strchr(s, '(');
    const char *rparen = strchr(s, ')');
    if (!lparen || !rparen || rparen < lparen) return 0;

    memset(out, 0, sizeof(*out));
    out->scale = 1;

    char disp_buf[128] = {0};
    size_t disp_len = (size_t)(lparen - s);
    if (disp_len >= sizeof(disp_buf)) return 0;
    memcpy(disp_buf, s, disp_len);
    char *disp = trim(disp_buf);
    if (*disp) {
        int ok = 0;
        int ch = parse_char_literal(disp, &ok);
        if (ok) {
            out->disp = ch;
            out->has_disp = 1;
        } else {
            int ok2 = 0;
            int64_t v = parse_i64(disp, &ok2);
            if (ok2) {
                out->disp = (int32_t)v;
                out->has_disp = 1;
            } else {
                out->sym = xstrdup(disp);
            }
        }
    }

    char inside_buf[128] = {0};
    size_t inside_len = (size_t)(rparen - lparen - 1);
    if (inside_len >= sizeof(inside_buf)) return 0;
    memcpy(inside_buf, lparen + 1, inside_len);
    char *inside = inside_buf;

    char *parts[3] = {0};
    int part_count = split_operands(inside, parts, 3);
    if (part_count >= 1 && parts[0] && *parts[0]) {
        if (strcmp(parts[0], "%rip") == 0) {
            out->is_rip = 1;
        } else {
            Reg r;
            if (!parse_reg(parts[0], &r)) return 0;
            out->has_base = 1;
            out->base_reg = r.id;
        }
    }
    if (part_count >= 2 && parts[1] && *parts[1]) {
        Reg r;
        if (!parse_reg(parts[1], &r)) return 0;
        out->has_index = 1;
        out->index_reg = r.id;
    }
    if (part_count >= 3 && parts[2] && *parts[2]) {
        int ok = 0;
        int64_t v = parse_i64(parts[2], &ok);
        if (!ok) return 0;
        out->scale = (int)v;
    }

    return 1;
}

int parse_operand(const char *s, Operand *op) {
    memset(op, 0, sizeof(*op));
    if (!s || !*s) return 0;

    if (s[0] == '$') {
        const char *val = s + 1;
        int ok = 0;
        int ch = parse_char_literal(val, &ok);
        if (ok) {
            op->kind = OP_IMM;
            op->imm = ch;
            return 1;
        }
        int ok2 = 0;
        int64_t v = parse_i64(val, &ok2);
        if (ok2) {
            op->kind = OP_IMM;
            op->imm = v;
            return 1;
        }
        op->kind = OP_IMM;
        op->imm_is_sym = 1;
        op->sym = xstrdup(val);
        return 1;
    }

    Reg r;
    if (parse_reg(s, &r)) {
        op->kind = OP_REG;
        op->reg = r;
        return 1;
    }

    if (strchr(s, '(')) {
        op->kind = OP_MEM;
        if (!parse_mem(s, &op->mem)) return 0;
        return 1;
    }

    op->kind = OP_LABEL;
    op->sym = xstrdup(s);
    return 1;
}