#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "as64.h"

void pass1(LineVec *lines, SymVec *syms, uint32_t *text_size, uint32_t *data_size, uint32_t *bss_size) {
    Section sec = SEC_NONE;
    uint32_t tsize = 0;
    uint32_t dsize = 0;
    uint32_t bsize = 0;

    for (size_t i = 0; i < lines->len; i++) {
        char *work = xstrdup(lines->data[i]);
        char *line = trim(work);
        if (!*line) { free(work); continue; }

        char *colon = NULL;
        for (char *p = line; *p; p++) {
            if (*p == ' ' || *p == '\t') break;
            if (*p == ':') { colon = p; break; }
        }
        if (colon) {
            *colon = 0;
            char *name = trim(line);
            if (*name) {
                if (sym_find(syms, name) >= 0) die("duplicate symbol");
                uint32_t value = 0;
                uint8_t type = MOBJ_SYM_UNDEF;
                if (sec == SEC_TEXT) { value = tsize; type = MOBJ_SYM_TEXT; }
                else if (sec == SEC_DATA) { value = dsize; type = MOBJ_SYM_DATA; }
                else if (sec == SEC_BSS) { value = bsize; type = MOBJ_SYM_BSS; }
                else die("label outside section");
                Symbol s = {xstrdup(name), value, type};
                symvec_push(syms, s);
            }
            line = trim(colon + 1);
            if (!*line) { free(work); continue; }
        }

        if (starts_with(line, ".section")) {
            if (strstr(line, ".text")) sec = SEC_TEXT;
            else if (strstr(line, ".data")) sec = SEC_DATA;
            else if (strstr(line, ".bss")) sec = SEC_BSS;
            else sec = SEC_NONE;
            free(work);
            continue;
        }

        if (starts_with(line, ".global")) { free(work); continue; }

        if (starts_with(line, ".equ")) {
            char *p = line + 4;
            p = trim(p);
            char *comma = strchr(p, ',');
            if (!comma) die("invalid .equ");
            *comma = 0;
            char *name = trim(p);
            char *val = trim(comma + 1);
            int ok = 0;
            uint32_t dot = 0;
            if (sec == SEC_TEXT) dot = tsize;
            else if (sec == SEC_DATA) dot = dsize;
            else if (sec == SEC_BSS) dot = bsize;
            int64_t v64 = parse_equ_expr(val, syms, dot, &ok);
            if (!ok || v64 < 0 || v64 > UINT32_MAX) die("invalid .equ value");
            uint32_t v = (uint32_t)v64;
            if (sym_find(syms, name) >= 0) die("duplicate symbol");
            Symbol s = {xstrdup(name), v, MOBJ_SYM_ABS};
            symvec_push(syms, s);
            free(work);
            continue;
        }

        if (starts_with(line, ".ascii")) {
            if (sec != SEC_DATA) die(".ascii only supported in .data");
            Buf tmp = {0};
            emit_ascii(&tmp, line);
            dsize += (uint32_t)tmp.len;
            free(tmp.data);
            free(work);
            continue;
        }

        if (starts_with(line, ".space")) {
            char *p = trim(line + 6);
            int ok = 0;
            uint32_t v = parse_u32(p, &ok);
            if (!ok) die("invalid .space");
            if (sec == SEC_DATA) dsize += v;
            else if (sec == SEC_BSS) bsize += v;
            else die(".space only supported in .data/.bss");
            free(work);
            continue;
        }

        if (sec != SEC_TEXT) { free(work); continue; }

        Buf tmp = {0};
        emit_text_line(line, &tmp, syms, NULL, SEC_TEXT);
        tsize += (uint32_t)tmp.len;
        free(tmp.data);
        free(work);
    }

    *text_size = tsize;
    *data_size = dsize;
    *bss_size = bsize;
}

void pass2(LineVec *lines, SymVec *syms, Buf *text, Buf *data, uint32_t *bss_size, RelocVec *relocs) {
    Section sec = SEC_NONE;
    uint32_t bsize = 0;

    for (size_t i = 0; i < lines->len; i++) {
        char *work = xstrdup(lines->data[i]);
        char *line = trim(work);
        if (!*line) { free(work); continue; }

        char *colon = NULL;
        for (char *p = line; *p; p++) {
            if (*p == ' ' || *p == '\t') break;
            if (*p == ':') { colon = p; break; }
        }
        if (colon) {
            line = trim(colon + 1);
            if (!*line) { free(work); continue; }
        }

        if (starts_with(line, ".section")) {
            if (strstr(line, ".text")) sec = SEC_TEXT;
            else if (strstr(line, ".data")) sec = SEC_DATA;
            else if (strstr(line, ".bss")) sec = SEC_BSS;
            else sec = SEC_NONE;
            free(work);
            continue;
        }

        if (starts_with(line, ".global")) { free(work); continue; }
        if (starts_with(line, ".equ")) { free(work); continue; }

        if (starts_with(line, ".ascii")) {
            if (sec != SEC_DATA) die(".ascii only supported in .data");
            emit_ascii(data, line);
            free(work);
            continue;
        }

        if (starts_with(line, ".space")) {
            char *p = trim(line + 6);
            int ok = 0;
            uint32_t v = parse_u32(p, &ok);
            if (!ok) die("invalid .space");
            if (sec == SEC_DATA) {
                for (uint32_t j = 0; j < v; j++) emit_u8(data, 0);
            } else if (sec == SEC_BSS) {
                bsize += v;
            } else {
                die(".space only supported in .data/.bss");
            }
            free(work);
            continue;
        }

        if (sec == SEC_TEXT) {
            emit_text_line(line, text, syms, relocs, SEC_TEXT);
            free(work);
            continue;
        }

        free(work);
    }

    *bss_size = bsize;
}

void write_mobj(const char *path, Buf *text, Buf *data, uint32_t bss_size, SymVec *syms, RelocVec *relocs) {
    FILE *f = fopen(path, "wb");
    if (!f) {
        fprintf(stderr, "as64: failed to open %s: %s\n", path, strerror(errno));
        exit(1);
    }

    MobjHeader hdr = {0};
    memcpy(hdr.magic, MOBJ_MAGIC, MOBJ_MAGIC_LEN);
    hdr.text_size = (uint32_t)text->len;
    hdr.data_size = (uint32_t)data->len;
    hdr.bss_size = bss_size;
    hdr.sym_count = (uint32_t)syms->len;
    hdr.reloc_count = (uint32_t)relocs->len;

    fwrite(&hdr, sizeof(hdr), 1, f);
    fwrite(text->data, 1, text->len, f);
    fwrite(data->data, 1, data->len, f);

    for (size_t i = 0; i < syms->len; i++) {
        Symbol *s = &syms->data[i];
        MobjSymbolHeader sh = {0};
        sh.name_len = (uint32_t)strlen(s->name);
        sh.value = s->value;
        sh.type = s->type;
        fwrite(&sh, sizeof(sh), 1, f);
        fwrite(s->name, 1, sh.name_len, f);
    }

    for (size_t i = 0; i < relocs->len; i++) {
        MobjReloc r = {0};
        r.offset = relocs->data[i].offset;
        r.sym_index = relocs->data[i].sym_index;
        r.addend = relocs->data[i].addend;
        r.type = relocs->data[i].type;
        r.section = relocs->data[i].section;
        fwrite(&r, sizeof(r), 1, f);
    }

    fclose(f);
}