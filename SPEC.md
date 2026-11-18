# oxed — executable specification

Status: **DESIGN / unimplemented**  
Date: **2026-11-18**

## Purpose

Make an `ed`-first, OxCaml terminal editor in which keyboard, mouse, `ed`
commands, and LSP workspace edits converge upon the same text-edit operations.
The interface is intentionally small. Command composition is foundational;
visual affordances augment it instead of replacing it.

## Dependency direction

```text
main.ml
  └── App                   event routing, lifecycle, rendering
      ├── Terminal          Lambda-term I/O and mouse
      ├── Editor            Zed buffer, cursor, selection, undo
      │   └── Workspace     files and active buffers
      ├── Ed                range-addressed command interpreter
      ├── Syntax            Tree-sitter and syntax overlays
      └── Language          LSP clients and language actions
```

The diagram shows conceptual dependencies, **not existing compiled modules**.
The specific contracts will be established while making `main.ml` compile.

## End-state `main.ml`

The canonical, manually typed end-state entry point is in `CHANGELOG.md`, step
006. It starts terminal, workspace, editor, commands, syntax, and language
services; it renders and dispatches until exit; and it finalizes the language
servers and terminal on shutdown.

## Design invariants

1. The Zed-backed editor owns authoritative text and cursor state.
2. `Ed` consumes addresses and commands, emits typed edit intents, and does not
   mutate an independent text copy.
3. Terminal input, mouse actions, and LSP edits use the same transaction path.
4. File I/O handles UTF-8 boundaries explicitly and must not corrupt buffers.
5. Terminal restore runs even on exceptions and failed editor initialization.
6. Tree-sitter is an incrementally updated, derived syntax view.
7. LSP responses are versioned and stale responses cannot overwrite fresh state.
8. Position conversions between Unicode scalar/columns, UTF-8 byte offsets,
   and LSP UTF-16 offsets have round-trip tests.
9. `Todo.undefined` is a development marker only, not a completed feature.
10. Typed module signatures should be the smallest contracts demanded by the
    end-state main, expanding as concrete behavior emerges.

## `ed` semantics

Begin with classic addresses (`.`, `$`, numeric, marks, search, ranges) and
commands (`p`, `a`, `i`, `c`, `d`, `s`, `g`, `w`, `q`, `u`). An optional `@`
selection address is an **oxed extension**, never to be confused with POSIX
`ed`. Decide precise semantics and error behavior by tests.

## Library roles

- OxCaml compiler / `Base`, `Core`, `Core_unix`: language and application code.
- Zed (`zed` opam library): Unicode ropes, editing, cursors and change events.
- Lambda-term (`lambda-term`): terminal display, keyboard and mouse events.
- Lwt: async/event-loop boundary (not a claim that OxCaml itself requires Lwt).
- Tree-sitter: later parser binding, incremental trees and syntax highlighting.
- `lsp`: later protocol types; subprocess transport must still be implemented.

The OCaml `zed` library is **not** the Rust Zed editor.

## Milestones and acceptance

| ID | Deliverable | Evidence |
|----|-------------|----------|
| 000 | Git-backed manual journal seed | `git log` succeeds after local clone |
| 001 | Toolchain | OxCaml switch selected, packages resolved |
| 002 | Compile-first application skeleton | `main.ml` typed, first own-module error observed |
| 003 | Typed interfaces | compiler traverses `App`, `Terminal`, etc. |
| 004 | Basic editor | open/edit/save/reopen, terminal restored |
| 005 | `ed` grammar | address-command tests and undo invariants |
| 006 | Interactive terminal | scroll, cursor, mouse, resize |
| 007 | Tree-sitter | incremental parse tests, highlights |
| 008 | LSP | document sync, diagnostics, go-to-definition |
| 009 | Hardening | crashes, partial writes, multibuffer tests |

## Decisions still open

- Exact `App` event type and multiplexing strategy.
- File encoding and buffer storage conversions.
- Tree-sitter language grammars and their FFI compatibility under OxCaml.
- LSP process transport and notification scheduling.
- How to reconcile `ed`'s line-oriented commands with character selections.
- Whether OxCaml-specific extensions offer measurable advantages over ordinary
  OCaml code in critical paths.

Keep decisions in the journal with dates and the compiler or test evidence that
motivated them.
