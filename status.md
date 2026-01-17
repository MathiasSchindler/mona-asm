# Project Status

| Tool | Stage | Status | Capabilities |
| --- | --- | --- | --- |
| exit0 | 0 | done | Exits with status 0 using raw syscalls. |
| utils_test | 2 | done | Internal test binary validating Stage 2 helpers. |
| true | 3 | done | Exits with status 0 (rejects invalid flags). |
| false | 3 | done | Exits with status 1 (rejects invalid flags). |
| echo | 4 | done | Prints arguments separated by spaces and a trailing newline; supports `-n`. |
| cat | 4 | done | Streams stdin or files to stdout (rejects invalid flags). |
| pwd | 5 | done | Prints the current working directory (rejects invalid flags). |
| ls | 6 | done | Lists directory entries, skipping . and ..; supports `-a`. |
| stat | 6 | done | Prints size, mode (masked 0x0fff), and mtime seconds (rejects invalid flags). |
| wc | 7 | done | Prints lines, words, and bytes for stdin or files; supports `-l`, `-w`, `-c`. |
| mkdir | 16 | done | Create a single directory (no flags). |
| rmdir | 16 | done | Remove a single empty directory (no flags). |
| rm | 16 | done | Remove a single file (no recursion). |
| touch | 17 | done | Create file or update mtime (no flags). |
| head | 17 | done | Print first 10 lines (stdin or file). |
| tail | 17 | done | Print last 10 lines (stdin or file). |
| cp | 18 | done | Copy single file to file (no dirs). |
| mv | 18 | done | Rename single file (same filesystem). |
| ln | 18 | done | Create hard link (no -s). |

Stage 9 (common library extraction) is done.
Stage 16–18 tools are done.

## Shared utilities

- [src/utils.inc](src/utils.inc): `util_strlen`, `util_streq`, `util_memcpy`, `util_utoa`, `util_itoa`, `util_parse_int`, `util_parse_flags`.
- [src/syscalls.inc](src/syscalls.inc): syscall wrappers with fixed syscall numbers.
