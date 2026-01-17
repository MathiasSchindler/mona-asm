# elfbuilder

Minimal x86-64 assembler + static ELF linker (no external libs).

Status: MVP extended to cover the full instruction set needed by ../src (text/data/bss, RIP-relative addressing, and common integer ops).

## Build

```
make
```

## Usage (MVP)

Assemble to a custom object and then link:

```
./build/as64 ../src/true.s -o ./build/true.mobj
./build/ld64 ./build/true.mobj -o ./build/true
```

Run:

```
./build/true

## Test target

```
make test
```
```

## Supported assembly (current)

- Directives: `.section .text`, `.global`, `.equ`, `.include`
- Labels: `name:`
- Instructions: `mov $imm32, %rax|%rdi`, `xor %rax|%rdi, %rax|%rdi`, `call label`, `syscall`, `ret`

Unsupported lines will produce a hard error so you can extend as needed.

## Notes

- The assembler emits a custom `*.mobj` format (text + symbols + relocations).
- The linker only supports a single input object for now.
- No `.data`/`.bss` handling yet.
