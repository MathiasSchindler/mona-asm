# Plan: Coreutils in x86-64 Assembly (syscalls only)

## Overarching philosophy and platform choice

We will target **Linux x86-64** with the **SysV ABI** and **raw syscalls**. This keeps the platform surface minimal, stable, and well-documented, while giving us a clear path toward a self-hosted assembler and linker. The plan starts with the system toolchain (GAS or NASM + ld) to establish behavioral correctness and build confidence, then gradually replaces it with our own tools. The approach prioritizes:

- **Simplicity first:** Minimal binaries that are easy to audit and test.
- **Incremental self-hosting:** Replace one piece at a time (assembler → linker).
- **Stable syscall API:** No libc dependency, predictable behavior.
- **Size-conscious design:** Keep code small without sacrificing maintainability.

This is the cleanest long-term platform because:
- Linux syscall ABI is stable and well-documented.
- ELF64 is predictable and supported by every tool and loader.
- The bootstrap path from “system tools” to “own tools” is straightforward.

## Size-first philosophy (without long-term harm)

We favor approaches that reduce binary size while keeping the project maintainable and extensible:

- **Single entry point per binary (`_start`)** with direct syscalls.
- **Shared assembly include** for syscall wrappers and utilities.
- **Avoid dynamic linking:** static ELF with no libc dependency.
- **Strip symbols** in release builds.
- **Prefer small algorithms** and table-driven logic over heavy branching.
- **Minimize parsing and formatting** to the smallest supported feature set.
- **Consolidate error messages** and reuse them across tools.
- **Use `openat` + `fstat`** to reduce redundant syscalls.

Size optimizations we should **avoid** early (to prevent long-term harm):
- Extreme instruction-level golf that reduces readability.
- Unstructured “macro magic” that obscures correctness.
- Relying on undefined behavior or undocumented kernel quirks.

## Step-by-step implementation plan with tests

## Current status snapshot (Jan 2026)

- Coreutils: Stages 0–9 complete for the current tool set.
- elfbuilder: `as64` + `ld64` exist as dependency-free C tools and can build all current coreutils.
- Stage 9 is done.
- Stage 11–12 are effectively done in C (elfbuilder MVP).
- Stage 13 is in progress (instruction/dir support expanding as needed).
- Stage 14 is partially done for the current tool set (elfbuilder builds all existing tools).

### Stage 0 — Toolchain baseline
**Goal:** establish a known-good build/run path.

**Tasks:**
- Choose syntax: GAS (AT&T) or NASM (Intel) and standardize.
- Create a tiny Makefile: assemble → link → strip.
- Define `_start` as the entry point.

**Test:**
- Build a no-op that exits 0; verify `echo $?` == 0.

---

### Stage 1 — Syscall wrapper macros
**Goal:** reusable syscall interface.

**Tasks:**
- Implement syscall macro and helpers for: `exit`, `write`, `read`, `openat`, `close`, `fstat`, `getdents64`.
- Standardize error convention (negative return in `rax`).

**Test:**
- Print a constant string to stdout.
- Call an invalid syscall and verify error path.

---

### Stage 2 — Minimal runtime utilities
**Goal:** basic string/number helpers.

**Tasks:**
- `strlen`, `streq`, `memcpy`, `utoa`, `itoa`, `parse_int`.

**Implementation notes (important):**
- Implemented in [src/utils.inc](src/utils.inc) using SysV ABI.
- `util_strlen(rdi=ptr) -> rax=len`.
- `util_streq(rdi=ptr1, rsi=ptr2) -> rax=1/0`.
- `util_memcpy(rdi=dst, rsi=src, rdx=len) -> rax=dst`.
- `util_utoa(rdi=value, rsi=buf) -> rax=len` (does **not** NUL-terminate; caller must add `\0`).
- `util_itoa(rdi=value, rsi=buf) -> rax=len` (does **not** NUL-terminate; caller must add `\0`).
- `util_parse_int(rdi=ptr) -> rax=value, rdx=1 on success / 0 on failure` (supports optional leading `-`).

**Test:**
- Unit-style binaries that print expected values and exit 0 only if correct.

---

### Stage 3 — Minimal binaries set (zero I/O)
**Tools:** `true`, `false`

**Implementation notes (important):**
- Implemented as [src/true.s](src/true.s) and [src/false.s](src/false.s).
- Both call `sys_exit` from [src/syscalls.inc](src/syscalls.inc).

**Test:**
- Shell checks for exit codes.

---

### Stage 4 — Simple I/O tools
**Tools:** `echo`, `cat`

**Tasks:**
- `echo`: print args + newline.
- `cat`: read stdin or files, stream to stdout.

**Implementation notes (important):**
- `echo` implemented in [src/echo.s](src/echo.s). It reads `argc/argv` directly from the initial stack, prints args separated by spaces, and always appends a newline.
- `cat` implemented in [src/cat.s](src/cat.s). It uses `openat(AT_FDCWD)` and a 4096-byte buffer. It handles partial writes by looping until all bytes are written.
- Current behavior on open/read/write error: exit status 1 with no error message (size-first choice for Stage 4).

**Test:**
- `make test` compares `echo a b` output.
- `cat` tested via stdin pipe and file input.

---

### Stage 5 — Directory and path
**Tool:** `pwd`

**Tasks:**
- Use `getcwd` or `readlink /proc/self/cwd`.

**Implementation notes (important):**
- Implemented in [src/pwd.s](src/pwd.s) using the `getcwd` syscall (79).
- Prints the returned path and a newline; on error exits 1.

**Test:**
- Compare output to shell `pwd`.

---

### Stage 6 — Metadata and listing
**Tools:** `ls` (simple), `stat` (basic)

**Tasks:**
- `getdents64` parsing; print names; optional `-a`.
- `stat`: print size + mode + mtime.

**Test:**
- `make test` creates a temp dir and asserts `ls` output contains expected filenames.
- `stat` test checks size field and presence of mode/mtime fields.

---

### Stage 7 — Counters
**Tool:** `wc`

**Tasks:**
- Count bytes, lines, words.

**Test:**
- `make test` checks file and stdin output for `a b\nc\n` equals `2 3 6`.

---

### Stage 8 — Option parsing layer
**Goal:** consistent `-` flag parsing.

**Tasks:**
- Minimal short-flag parser with `--` terminator.

**Implementation notes (important):**
- Implemented `util_parse_flags` in [src/utils.inc](src/utils.inc).
- API: `rdi=argc`, `rsi=argv`, `rdx=allowed_mask` → `rax=flags`, `rcx=remaining_argc`, `r8=argv_ptr_first_nonflag`, `rdx=0/1 (ok/invalid)`.
- Supports grouped short flags (e.g., `-lw`), stops at `--`, treats `-` as non-flag.
- On invalid flags: tools print a minimal `usage:` line to stderr and exit 1.
- Flags implemented: `echo -n`, `ls -a`, `wc -l/-w/-c`.

**Test:**
- Invalid flags exit non-zero and print usage.

---

### Stage 9 — Common library extraction
**Goal:** reduce duplication.

**Tasks:**
- Move macros + helpers into shared `.inc`.

**Test:**
- Rebuild all tools and rerun tests.

Status: done.

---

### Stage 10 — Size/strip/packaging
**Goal:** minimal binaries and predictable install.

**Tasks:**
- Strip symbols in release builds.
- Install into local `bin/`.

**Test:**
- All tests pass after stripping and install.

Status: not started.

---

### Stage 11 — Self-hosted assembler (Phase 1)
**Goal:** minimal assembler for a subset of our own code.

**Tasks:**
- Define a tiny assembly syntax subset.
- Build assembler in C first, then port to asm.
- Output flat binary or simple ELF with fixed layout.

**Test:**
- Assemble the Stage 0 no-op and compare behavior.

Status: done in C (elfbuilder/as64).

---

### Stage 12 — Self-hosted linker (Phase 1)
**Goal:** link fixed-layout object fragments.

**Tasks:**
- Define a simple object format (text + data + symbols).
- Resolve symbols and relocate in one pass.

**Test:**
- Link two objects (main + util) and run.

Status: done in C (elfbuilder/ld64).

---

### Stage 13 — Expand assembler coverage
**Goal:** support directives, labels, relocations, sections.

**Tasks:**
- Add `.text`, `.data`, `.bss`, `.global`, `.section`, label scope.

**Test:**
- Assemble/link a mid-complexity tool (e.g., `cat`).

Status: in progress (coverage expanded to build all current tools; continue filling gaps).

---

### Stage 14 — Replace system toolchain
**Goal:** build all tools with custom assembler+linker.

**Tasks:**
- Ensure ELF headers, program headers, and alignment are correct.

**Test:**
- Full test suite on all tools.

Status: in progress (elfbuilder builds all current tools).

---

### Stage 15 — Optimization + hardening
**Goal:** robustness.

**Tasks:**
- Improve error messages and edge case handling.
- Add fuzz tests for assembler input.

**Test:**
- Regression suite plus fuzz results.

Status: not started.

---

## Next coreutils candidates (low-risk order)

1. `du` (bytes only, single file/dir)
2. `chmod` (octal mode, single file)
3. `chown` (numeric uid:gid, single file)
4. `date` (epoch seconds only)
5. `sleep` (integer seconds)

---

## New milestones (Stage 16+)

### Stage 16 — Basic filesystem mutation
**Tools:** `mkdir`, `rmdir`, `rm` (single target, no recursion)

**Implementation notes:**
- `mkdir`: `sys_mkdir` (mode 0777 masked by umask); no flags.
- `rmdir`: `sys_rmdir`; no flags.
- `rm`: `sys_unlink` for files; reject directories (exit 1).

**Test:**
- Create temp dir, `mkdir` then `rmdir`.
- Create file, `rm` succeeds; `rm` on directory fails with exit 1.

Status: done.

### Stage 17 — Timestamp + small output
**Tools:** `touch`, `head`, `tail` (default 10 lines)

**Implementation notes:**
- `touch`: `openat` with `O_CREAT|O_WRONLY` then `utimensat` (or fallback to `utime` syscall if preferred); no flags.
- `head`/`tail`: stdin or file; minimal line counting; no flags.

**Test:**
- `touch` creates file and updates mtime.
- `head`/`tail` of a fixed fixture file matches expected output.

Status: done.

### Stage 18 — Simple file ops
**Tools:** `cp`, `mv`, `ln`

**Implementation notes:**
- `cp`: open/read/write loop; refuse directories.
- `mv`: `rename` only; if cross-device, exit 1.
- `ln`: `link` only; optional `-s` later.

**Test:**
- Copy file contents identical; `mv` rename works in same dir; `ln` creates hard link.

Status: done.

### Stage 19 — Basic metadata + size
**Tools:** `du` (bytes), `chmod` (octal), `chown` (numeric uid:gid)

**Test:**
- `du` on a fixed file equals byte count.
- `chmod` changes mode as expected.
- `chown` works for numeric uid:gid (or exits 1 if not permitted).

Status: not started.

### Stage 20 — Time + sleep
**Tools:** `date` (epoch seconds), `sleep` (integer seconds)

**Test:**
- `date` prints digits only and changes over time.
- `sleep 1` delays approximately one second.

Status: not started.
