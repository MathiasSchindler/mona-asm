#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include "mobj.h"

typedef struct {
    char *name;
    uint32_t value;
    uint8_t type;
} Symbol;

typedef struct {
    Symbol *data;
    size_t len;
} SymVec;

typedef struct {
    uint8_t *data;
    size_t len;
} Buf;

typedef struct {
    uint32_t offset;
    uint32_t sym_index;
    int32_t addend;
    uint8_t type;
    uint8_t section;
} Reloc;

typedef struct {
    Reloc *data;
    size_t len;
} RelocVec;

static void die(const char *msg) {
    fprintf(stderr, "ld64: %s\n", msg);
    exit(1);
}

static void *xmalloc(size_t n) {
    void *p = malloc(n);
    if (!p) die("out of memory");
    return p;
}

static Symbol *read_symbols(FILE *f, uint32_t count) {
    Symbol *syms = xmalloc(sizeof(Symbol) * count);
    for (uint32_t i = 0; i < count; i++) {
        MobjSymbolHeader sh;
        if (fread(&sh, sizeof(sh), 1, f) != 1) die("bad symbol header");
        char *name = xmalloc(sh.name_len + 1);
        if (fread(name, 1, sh.name_len, f) != sh.name_len) die("bad symbol name");
        name[sh.name_len] = 0;
        syms[i].name = name;
        syms[i].value = sh.value;
        syms[i].type = sh.type;
    }
    return syms;
}

static Reloc *read_relocs(FILE *f, uint32_t count) {
    Reloc *rels = xmalloc(sizeof(Reloc) * count);
    for (uint32_t i = 0; i < count; i++) {
        MobjReloc r;
        if (fread(&r, sizeof(r), 1, f) != 1) die("bad reloc");
        rels[i].offset = r.offset;
        rels[i].sym_index = r.sym_index;
        rels[i].addend = r.addend;
        rels[i].type = r.type;
        rels[i].section = r.section;
    }
    return rels;
}

static int sym_find(Symbol *syms, size_t count, const char *name) {
    for (size_t i = 0; i < count; i++) {
        if (strcmp(syms[i].name, name) == 0) return (int)i;
    }
    return -1;
}

static void apply_relocs(Buf *text, Buf *data, uint64_t base, uint64_t text_off, uint64_t data_off, SymVec *syms, RelocVec *rels) {
    for (size_t i = 0; i < rels->len; i++) {
        Reloc *r = &rels->data[i];
        if (r->sym_index >= syms->len) die("reloc sym out of range");
        Symbol *s = &syms->data[r->sym_index];
        if (s->type == MOBJ_SYM_UNDEF) die("undefined symbol");
        if (r->type != MOBJ_RELOC_REL32) die("unsupported reloc type");
        uint64_t sym_addr = 0;
        if (s->type == MOBJ_SYM_TEXT) sym_addr = base + text_off + s->value;
        else if (s->type == MOBJ_SYM_DATA) sym_addr = base + data_off + s->value;
        else if (s->type == MOBJ_SYM_BSS) sym_addr = base + data_off + data->len + s->value;
        else if (s->type == MOBJ_SYM_ABS) sym_addr = s->value;

        uint64_t place = 0;
        if (r->section == MOBJ_SEC_TEXT) {
            if (r->offset + 4 > text->len) die("reloc out of range");
            place = base + text_off + r->offset + 4;
            int32_t rel = (int32_t)(sym_addr + r->addend - place);
            memcpy(text->data + r->offset, &rel, 4);
        } else if (r->section == MOBJ_SEC_DATA) {
            if (r->offset + 4 > data->len) die("reloc out of range");
            place = base + data_off + r->offset + 4;
            int32_t rel = (int32_t)(sym_addr + r->addend - place);
            memcpy(data->data + r->offset, &rel, 4);
        } else {
            die("unknown reloc section");
        }
    }
}

typedef struct {
    unsigned char e_ident[16];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint64_t e_entry;
    uint64_t e_phoff;
    uint64_t e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_phnum;
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
} Elf64_Ehdr;

typedef struct {
    uint32_t p_type;
    uint32_t p_flags;
    uint64_t p_offset;
    uint64_t p_vaddr;
    uint64_t p_paddr;
    uint64_t p_filesz;
    uint64_t p_memsz;
    uint64_t p_align;
} Elf64_Phdr;

static void write_elf(const char *path, Buf *text, Buf *data, uint32_t bss_size, uint64_t entry_off, int tiny) {
    FILE *f = fopen(path, "wb");
    if (!f) {
        fprintf(stderr, "ld64: failed to open %s: %s\n", path, strerror(errno));
        exit(1);
    }

    const uint64_t base = tiny ? 0x10000 : 0x400000;
    const uint64_t hdr_size = sizeof(Elf64_Ehdr) + sizeof(Elf64_Phdr);
    const uint64_t text_off = hdr_size;
    const uint64_t data_off = text_off + text->len;
    const uint64_t entry = base + text_off + entry_off;

    Elf64_Ehdr eh = {0};
    eh.e_ident[0] = 0x7f;
    eh.e_ident[1] = 'E';
    eh.e_ident[2] = 'L';
    eh.e_ident[3] = 'F';
    eh.e_ident[4] = 2; 
    eh.e_ident[5] = 1; 
    eh.e_ident[6] = 1; 
    eh.e_type = 2; 
    eh.e_machine = 62; 
    eh.e_version = 1;
    eh.e_entry = entry;
    eh.e_phoff = sizeof(Elf64_Ehdr);
    eh.e_ehsize = sizeof(Elf64_Ehdr);
    eh.e_phentsize = sizeof(Elf64_Phdr);
    eh.e_phnum = 1;
    eh.e_shoff = 0;
    eh.e_shentsize = 0;
    eh.e_shnum = 0;
    eh.e_shstrndx = 0;

    Elf64_Phdr ph = {0};
    ph.p_type = 1; 
    if (data->len == 0 && bss_size == 0) ph.p_flags = 5; 
    else ph.p_flags = 7; 
    ph.p_offset = 0;
    ph.p_vaddr = base;
    ph.p_paddr = base;
    ph.p_filesz = data_off + data->len;
    ph.p_memsz = ph.p_filesz + bss_size;
    ph.p_align = 1;

    fwrite(&eh, sizeof(eh), 1, f);
    fwrite(&ph, sizeof(ph), 1, f);
    fwrite(text->data, 1, text->len, f);
    fwrite(data->data, 1, data->len, f);
    fclose(f);
    if (chmod(path, 0755) != 0) {
        fprintf(stderr, "ld64: chmod failed for %s: %s\n", path, strerror(errno));
        exit(1);
    }
}

int main(int argc, char **argv) {
    if (argc < 2) die("usage: ld64 <input.mobj> -o <output>");

    const char *in_path = argv[1];
    const char *out_path = NULL;
    int tiny = 0;
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            out_path = argv[i + 1];
            i++;
            continue;
        }
        if (strcmp(argv[i], "--tiny-elf") == 0) {
            tiny = 1;
            continue;
        }
    }
    if (!out_path) die("missing -o output");

    FILE *f = fopen(in_path, "rb");
    if (!f) {
        fprintf(stderr, "ld64: failed to open %s: %s\n", in_path, strerror(errno));
        return 1;
    }

    MobjHeader hdr;
    if (fread(&hdr, sizeof(hdr), 1, f) != 1) die("bad header");
    if (memcmp(hdr.magic, MOBJ_MAGIC, MOBJ_MAGIC_LEN) != 0) die("bad magic");

    Buf text = {0};
    text.len = hdr.text_size;
    text.data = xmalloc(text.len);
    if (fread(text.data, 1, text.len, f) != text.len) die("bad text");

    Buf data = {0};
    data.len = hdr.data_size;
    data.data = xmalloc(data.len ? data.len : 1);
    if (data.len && fread(data.data, 1, data.len, f) != data.len) die("bad data");

    SymVec syms = {0};
    syms.len = hdr.sym_count;
    syms.data = read_symbols(f, hdr.sym_count);

    RelocVec rels = {0};
    rels.len = hdr.reloc_count;
    rels.data = read_relocs(f, hdr.reloc_count);

    fclose(f);

    int entry_idx = sym_find(syms.data, syms.len, "_start");
    if (entry_idx < 0) die("missing _start");

    const uint64_t base = 0x400000;
    const uint64_t hdr_size = sizeof(Elf64_Ehdr) + sizeof(Elf64_Phdr);
    const uint64_t text_off = hdr_size;
    const uint64_t data_off = text_off + text.len;

    apply_relocs(&text, &data, base, text_off, data_off, &syms, &rels);

    write_elf(out_path, &text, &data, hdr.bss_size, syms.data[entry_idx].value, tiny);
    return 0;
}
