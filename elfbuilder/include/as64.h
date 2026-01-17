#ifndef AS64_H
#define AS64_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include "mobj.h"

typedef struct {
    char *data;
    size_t len;
    size_t cap;
} Str;

typedef struct {
    uint8_t *data;
    size_t len;
    size_t cap;
} Buf;

typedef struct {
    char *name;
    uint32_t value;
    uint8_t type;
} Symbol;

typedef struct {
    uint32_t offset;
    uint32_t sym_index;
    int32_t addend;
    uint8_t type;
    uint8_t section;
} Reloc;

typedef struct {
    Symbol *data;
    size_t len;
    size_t cap;
} SymVec;

typedef struct {
    Reloc *data;
    size_t len;
    size_t cap;
} RelocVec;

typedef struct {
    char **data;
    size_t len;
    size_t cap;
} LineVec;

typedef enum {
    SEC_NONE = 0,
    SEC_TEXT,
    SEC_DATA,
    SEC_BSS
} Section;

typedef struct {
    int id;
    int size;
} Reg;

typedef struct {
    int has_base;
    int base_reg;
    int has_index;
    int index_reg;
    int scale;
    int is_rip;
    int32_t disp;
    int has_disp;
    char *sym;
} Mem;

typedef enum {
    OP_NONE = 0,
    OP_REG,
    OP_IMM,
    OP_MEM,
    OP_LABEL
} OperandKind;

typedef struct {
    OperandKind kind;
    Reg reg;
    int64_t imm;
    int imm_is_sym;
    char *sym;
    Mem mem;
} Operand;

void die(const char *msg);
void die_line(const char *msg, const char *line);
void *xmalloc(size_t n);
char *xstrdup(const char *s);

void buf_append(Buf *b, const uint8_t *src, size_t n);
void symvec_push(SymVec *v, Symbol s);
void relocvec_push(RelocVec *v, Reloc r);
void linevec_push(LineVec *v, char *line);

char *trim(char *s);
void strip_comment(char *s);
int starts_with(const char *s, const char *pfx);
char *path_dirname(const char *path);
char *path_join(const char *dir, const char *file);
void read_lines_recursive(const char *path, LineVec *out);
int sym_find(SymVec *syms, const char *name);

uint32_t parse_u32(const char *s, int *ok);
int64_t parse_i64(const char *s, int *ok);
int parse_char_literal(const char *s, int *ok);
int64_t parse_equ_expr(const char *s, SymVec *syms, uint32_t dot, int *ok);

int parse_reg(const char *r, Reg *out);
int split_operands(char *s, char **ops, int max_ops);
int parse_mem(const char *s, Mem *out);
int parse_operand(const char *s, Operand *op);

void emit_u8(Buf *out, uint8_t v);
void emit_ascii(Buf *out, const char *line);
void emit_text_line(const char *line, Buf *out, SymVec *syms, RelocVec *relocs, Section sec);

void pass1(LineVec *lines, SymVec *syms, uint32_t *text_size, uint32_t *data_size, uint32_t *bss_size);
void pass2(LineVec *lines, SymVec *syms, Buf *text, Buf *data, uint32_t *bss_size, RelocVec *relocs);
void write_mobj(const char *path, Buf *text, Buf *data, uint32_t bss_size, SymVec *syms, RelocVec *relocs);

#endif