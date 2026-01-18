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
| du | 19 | done | Print file size in bytes (single file). |
| chmod | 19 | done | Set mode from octal (single file). |
| date | 20 | done | Prints epoch seconds (no flags). |
| seq | 20 | done | Print integer sequences (1 or 2 args). |
| whoami | 20 | done | Prints username from /etc/passwd or numeric UID. |
| yes | 20 | done | Repeats args (or y); supports `-n`. |
| printf | 20 | done | Minimal printf with common specifiers and escapes. |
| sort | 20 | done | Sort stdin lines (buffered). |
| uniq | 20 | done | Collapse consecutive duplicate lines (stdin). |
| cut | 20 | done | Extract field by delimiter; supports `-d` and `-f`. |
| tr | 20 | done | Translate or delete bytes; supports `-d`. |
| od | 20 | done | Print bytes in octal (space-separated). |
| tee | 20 | done | Copy stdin to stdout and files. |
| sleep | 20 | done | Sleep for N seconds (integer). |
| basename | 21 | done | Print final path component. |
| dirname | 21 | done | Print directory portion of a path. |
| uname | 21 | done | Print system name from uname. |
| truncate | 21 | done | Set file size (single file). |
| paste | 21 | done | Merge lines from two files (tab-separated). |
| shell | 0–2 | in progress | Stage 0–2: prompt/read/tokenize/exec and `exit` builtin. |

Stage 9 (common library extraction) is done.
Stage 16–21 tools listed above are done (except `shell`, which is in progress).
elfbuilder: as64/ld64 build all current tools; instruction coverage expanded as needed.

## Shared utilities

- [src/utils.inc](src/utils.inc): `util_strlen`, `util_streq`, `util_memcpy`, `util_utoa`, `util_itoa`, `util_parse_int`, `util_parse_flags`.
- [src/syscalls.inc](src/syscalls.inc): syscall wrappers with fixed syscall numbers.
