#ifndef MOBJ_H
#define MOBJ_H

#include <stdint.h>

#define MOBJ_MAGIC "MOBJ64\0"
#define MOBJ_MAGIC_LEN 7

enum {
    MOBJ_SYM_UNDEF = 0,
    MOBJ_SYM_TEXT  = 1,
    MOBJ_SYM_DATA  = 2,
    MOBJ_SYM_BSS   = 3,
    MOBJ_SYM_ABS   = 4
};

enum {
    MOBJ_SEC_TEXT = 1,
    MOBJ_SEC_DATA = 2
};

enum {
    MOBJ_RELOC_REL32 = 1
};

typedef struct {
    char magic[MOBJ_MAGIC_LEN];
    uint32_t text_size;
    uint32_t data_size;
    uint32_t bss_size;
    uint32_t sym_count;
    uint32_t reloc_count;
} MobjHeader;

typedef struct {
    uint32_t name_len;
    uint32_t value;
    uint8_t type;
} MobjSymbolHeader;

typedef struct {
    uint32_t offset;
    uint32_t sym_index;
    int32_t addend;
    uint8_t type;
    uint8_t section;
} MobjReloc;

#endif
