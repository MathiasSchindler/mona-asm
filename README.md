# mona-asm

Minimal coreutils-style tools in x86-64 assembly (Linux syscalls only), plus a tiny assembler/linker toolchain to bootstrap the project.

## What this is
- A growing set of tiny utilities implemented in x86-64 assembly.
- A self-contained assembler/linker (elfbuilder) that can build the current tool set without external dependencies.
- A size-conscious, syscall-only codebase intended for learning, bootstrapping, and experimentation.

## Goals
- **Small and auditable binaries** using raw Linux syscalls.
- **Incremental self-hosting:** replace the system toolchain with the project’s own assembler/linker.
- **Clear progression:** each tool is simple first, then extended as needed.

## Project layout
- [src](src): assembly sources for tools and shared .inc files.
- [build](build): build artifacts from the system toolchain.
- [elfbuilder](elfbuilder): minimal assembler (as64) and linker (ld64).
- [plan.md](plan.md): roadmap and staged implementation plan.
- [status.md](status.md): current tool status and capabilities.

## Supported platform
- **Linux x86-64** (SysV ABI)
- Uses **raw syscalls** only (no libc).

## Build (system toolchain)
- make

## Test
- make test

## Build with elfbuilder
- cd elfbuilder
- make
- make test

## Limitations (intentional and current)
- Linux-only, x86-64 only.
- Syscall-only; no libc and no dynamic linking.
- Utilities are minimal and do not aim to be feature-complete GNU coreutils.
- Some tools only handle stdin or a single file; many options are intentionally omitted.
- elfbuilder is a minimal assembler/linker focused on this codebase, not general-purpose assembly.
- No robust error reporting; many tools simply exit with status 1 on error.

## Licensing and attribution
This project is released under **CC0**.

Most of the code has been authored with the help of **GPT-5.2-Codex**.

