#include <string.h>

#include "as64.h"

int main(int argc, char **argv) {
    if (argc < 2) die("usage: as64 <input.s> -o <output.mobj>");

    const char *in_path = argv[1];
    const char *out_path = NULL;
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            out_path = argv[i + 1];
            i++;
        }
    }
    if (!out_path) die("missing -o output.mobj");

    LineVec lines = {0};
    read_lines_recursive(in_path, &lines);

    SymVec syms = {0};
    uint32_t text_size = 0, data_size = 0, bss_size = 0;
    pass1(&lines, &syms, &text_size, &data_size, &bss_size);

    Buf text = {0};
    Buf data = {0};
    RelocVec relocs = {0};
    pass2(&lines, &syms, &text, &data, &bss_size, &relocs);

    write_mobj(out_path, &text, &data, bss_size, &syms, &relocs);
    return 0;
}
