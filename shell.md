# Shell in x86-64 Assembly — Implementation Plan

## Goals
- Build a minimal but extensible shell in pure assembly using raw Linux syscalls.
- Start small (interactive loop, exec) while keeping a clean path to advanced features (quoting, pipes, redirection, job control).
- Emphasize correctness and a clear architecture over premature size golfing.

## Guiding principles
- **Layered design:** tokenizer → parser → executor → builtins.
- **Small, testable primitives:** each phase should be independently validated.
- **Future-proof representation:** AST for commands and pipelines, even if initial executor is simple.
- **Syscall-only:** no libc; all I/O and process control through syscalls.

## Stage 0 — Baseline infrastructure
**Deliverables**
- Minimal REPL loop: print prompt, read line, trim newline, ignore empty lines.
- Fixed-size input buffer with graceful overflow handling (truncate or error).

**Key syscalls**
- `read`, `write`, `exit`

**Notes**
- Define shared utilities: `strlen`, `memcpy`, `streq`, `parse_int`, `split` helpers.

## Stage 1 — Tokenizer v1 (space-delimited)
**Deliverables**
- Tokenize input by spaces and tabs only.
- Support simple words (no quoting, no escapes).

**Data model**
- Token array with type `WORD` only.

**Tests**
- `echo hello world` → tokens: `echo`, `hello`, `world`.

## Stage 2 — Executor v1 (single command)
**Deliverables**
- Fork/exec a single command with argv.
- Wait for child and return status.

**Key syscalls**
- `fork`, `execve`, `wait4`

**Notes**
- Provide a minimal PATH resolver later; for now require absolute/relative paths.

## Stage 3 — Builtins v1
**Deliverables**
- Builtins: `cd`, `exit`.

**Notes**
- `cd` uses `chdir`, `exit` uses `exit` syscall.

## Stage 4 — Tokenizer v2 (quoting + escapes)
**Deliverables**
- Implement single quotes `'...'` (literal)
- Implement double quotes `"..."` with escapes: `\`, `\"`, `\n`, `\t`
- Backslash escapes outside quotes

**Data model**
- Tokens carry raw bytes after unescaping.

**Tests**
- `echo "a b"` → single token `a b`
- `echo 'a b'` → single token `a b`

## Stage 5 — Parser v1 (simple commands)
**Deliverables**
- Parse command + argv from tokens.
- Preserve structure even if executor is still linear.

**Data model**
- AST node `Command { argv[], redirs[] }`.

## Stage 6 — Redirection v1
**Deliverables**
- Handle `>` and `<` for stdout/stdin.
- Support `>>` append.

**Key syscalls**
- `openat`, `dup2`, `close`

**Notes**
- Add redirection nodes to AST and apply before `execve`.

## Stage 7 — Pipelines v1
**Deliverables**
- Parse and execute `cmd1 | cmd2 | cmd3`.
- Connect stdout → stdin via `pipe`.

**Key syscalls**
- `pipe`, `dup2`, `close`, `fork`, `execve`, `wait4`

**Notes**
- Execute pipeline as a chain of forked children.

## Stage 8 — Tokenizer v3 (operators + precedence)
**Deliverables**
- Tokenize operators: `|`, `>`, `>>`, `<`, `;`.
- Preserve operator tokens for parser.

## Stage 9 — Parser v2 (compound lists)
**Deliverables**
- Parse lists separated by `;`.
- Execute sequentially.

**Data model**
- AST: `List { pipeline[] }`.

## Stage 10 — PATH resolution
**Deliverables**
- Implement PATH search for commands without `/`.
- Read `PATH` from environment.

**Key syscalls**
- `execve` with constructed candidate paths.

## Stage 11 — Builtins v2
**Deliverables**
- `pwd`, `export`, `unset`, `env`.
- Simple variable assignment parsing (`NAME=value`).

## Stage 12 — Job control v1 (optional later)
**Deliverables**
- Background execution with `&`.
- Track PIDs and print job status.

**Key syscalls**
- `setpgid`, `tcsetpgrp`, `wait4`, `kill`

## Stage 13 — Advanced expansions (long-term)
**Deliverables**
- `$VAR` environment expansion.
- `$?` last status.
- Simple `~` expansion.

## Stage 14 — Robustness + testing
**Deliverables**
- Error messages with line context.
- Fuzz tests for tokenizer and parser.
- Deterministic regression tests for redirection/pipes.

## Data structures (planned)
- **Token**: type, start pointer, length, flags (quoted, escaped).
- **Command**: argv array, redirection list.
- **Pipeline**: list of commands.
- **List**: list of pipelines.

## Minimal syscall set
- `read`, `write`, `exit`
- `fork`, `execve`, `wait4`
- `pipe`, `dup2`, `close`
- `openat`, `chdir`, `getcwd`
- `setpgid`, `tcsetpgrp`, `kill` (for job control)

## Notes on keeping future features in mind
- Use an AST even for the minimal shell to avoid rewrites when adding pipes and redirection.
- Keep tokenizer state machine extensible for new operators and quote rules.
- Treat redirections as first-class nodes in the command structure.
- Define clear error handling paths for each phase (tokenize, parse, exec).
