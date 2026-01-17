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

## Shared utilities

- [src/utils.inc](src/utils.inc): `util_strlen`, `util_streq`, `util_memcpy`, `util_utoa`, `util_itoa`, `util_parse_int`, `util_parse_flags`.
- [src/syscalls.inc](src/syscalls.inc): syscall wrappers with fixed syscall numbers.
