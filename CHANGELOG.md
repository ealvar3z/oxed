# oxed — development journal

> **Method:** Type every command and source line yourself. Run the compiler.
> Record the **actual** diagnostic before adding the smallest missing contract.
> The seed repository has no editor implementation by design.

This is both a setup walkthrough and a chronological lab notebook. Commands
below are intended for an interactive shell and are not claimed to have been
executed on your machine. Never mark an expected result as an observed result.

## 2026-11-18 — 000. Bootstrap archive seed (included)

**Shipped:** `README.md`, `SPEC.md`, `CHANGELOG.md`, `.gitignore`, Git metadata,
and a single documentation-only commit. No `.ml`, `.mli`, `dune`, or
`dune-project` file is shipped.

**Decision:** Call the project `oxed`. Use a local Git clone of the extracted
archive rather than claiming the ZIP is itself a Git remote.

**Status:** documentation prepared; compiler and dependency verification remain
to be performed by the developer.

---

## 001. From ZIP to your own working clone

Open a terminal in the directory containing `bootstrap-oxed.zip` and **type**:

```sh
unzip bootstrap-oxed.zip
git -C bootstrap-oxed status --short --branch
git -C bootstrap-oxed log --oneline -1
git clone ./bootstrap-oxed oxed
cd oxed
git status --short --branch
git log --oneline -1
```

The extracted `bootstrap-oxed/` directory is the local source repository.
The newly cloned `oxed/` directory is where you work. `origin` points to the
local extracted repository; it does **not** point to GitHub.

Tell Git who you are **using your own identity** (replace the quoted examples):

```sh
git config user.name 'YOUR NAME'
git config user.email 'YOUR EMAIL'
git config --local --list
```

If you would rather start a new history, do so deliberately later; this
archive's Git history is useful for recording your starting point.

**Journal — fill in after running:**

```text
Date/time:
Host / operating system / architecture:
First `git log --oneline -1`:
`git status --short --branch`:
Notes:
```

---

## 002. Inspect or install host prerequisites

Primary walkthrough: **macOS with Homebrew**. Execute the appropriate branch
for your own machine; do not execute all branches.

### macOS

```sh
uname -s
uname -m
xcode-select -p
brew --version
git --version
unzip -v
opam --version
```

If Command Line Tools are missing, run `xcode-select --install` and complete
its installer before continuing. If Homebrew is missing, follow the official
Homebrew instructions at <https://brew.sh/>; do not blindly run an unfamiliar
network installation script.

Install missing dependencies (Homebrew will report ones already installed):

```sh
brew install opam autoconf pkg-config
```

### Arch Linux alternative

```sh
sudo pacman -Syu --needed git unzip opam base-devel m4 autoconf pkgconf
```

### Ubuntu 24.04 alternative

```sh
sudo apt update
sudo apt install git unzip opam build-essential m4 autoconf pkg-config
```

**Journal:** record host/architecture, tool versions, and any failed command.
Do not substitute a different compiler silently.

---

## 003. Install and select the OxCaml compiler

Initialize opam only if it has not been initialized on this computer:

```sh
opam init
eval "$(opam env)"
opam update --all
opam switch list
```

For a **new** dedicated switch, the opam registry currently recommends:

```sh
opam switch create oxcaml oxcaml-compiler --repos ox=git+https://github.com/oxcaml/opam-repository.git,default
eval "$(opam env --switch=oxcaml)"
opam switch show
ocamlc -version
ocamlopt -version
opam list --installed --short
```

If the switch already exists, **do not recreate it**. Inspect it and activate
it instead:

```sh
opam switch list
eval "$(opam env --switch=oxcaml)"
opam switch show
ocamlc -version
```

The OxCaml project website also documents a version-named switch
`5.2.0+ox`. These are alternative installation paths; use **one** and record
which one your compiler actually installed. See:

- <https://opam.ocaml.org/packages/oxcaml/>
- <https://oxcaml.org/get-oxcaml/>
- <https://github.com/oxcaml/opam-repository>

If you already use an OxCaml switch other than `oxcaml`, replace only the
switch name in subsequent `opam env` commands. Do not change the compiler
family.

**Journal — fill in:**

```text
Switch name:
`ocamlc -version`:
`ocamlopt -version`:
Repository / compiler package:
Install or solver errors:
```

---

## 004. Install core development libraries

After activating the OxCaml switch:

```sh
opam install dune ocamlfind base core core_unix zed lambda-term lwt
opam install utop
opam list --installed --short
ocamlfind query zed
ocamlfind query lambda-term
dune --version
```

`lambda-term` depends on `zed` and provides terminal abstractions. Package
availability and compiler compatibility must still be verified locally.
Do **not** install Tree-sitter or `lsp` yet: syntax and language services are
future milestones. Optional developer tooling after the core works:

```sh
opam install ocamlformat merlin ocaml-lsp-server
```

The `ocaml-lsp-server` executable helps with **your source editing**; it is
not the same thing as the future `oxed` LSP client.

**Journal:** write down the installed package versions and any solver/build
failure verbatim. If Lambda-term cannot build under OxCaml, stop here and
investigate the constraint; do not switch to upstream OCaml to hide it.

---

## 005. Type the Dune project files

Inside your working `oxed/` directory, create and edit two files:

```sh
vim dune-project
```

Type the entire file:

```lisp
(lang dune 3.0)
(name oxed)
```

Then:

```sh
vim dune
```

Type:

```lisp
(executable
 (name main)
 (libraries core core_unix zed lambda-term lwt.unix))
```

For now Dune builds `main.exe`. Naming the eventual installed command `oxed`
is a separate packaging decision; do not let packaging obscure the first
compiler error. Confirm the files yourself:

```sh
cat dune-project
cat dune
git status --short
```

**Journal:** record what you entered. Do not commit a source file you have not
personally reviewed.

---

## 006. Type the end-state `main.ml` (do not simplify it)

```sh
vim main.ml
```

Transcribe this **whole** program. It intentionally references modules that
do not yet exist:

```ocaml
open Core
open Lwt.Syntax

let rec loop app =
  let* event = App.next_event app in
  let* () = App.dispatch app event in
  let* () = App.render app in
  if App.running app then loop app
  else Lwt.return_unit

let run files =
  let* terminal = Terminal.open_ () in
  Lwt.finalize
    (fun () ->
      let* workspace = Workspace.open_files files in
      let editor = Editor.create workspace in
      let commands = Ed.create editor in
      let syntax = Syntax.create editor in
      let* languages = Language.start editor in
      Lwt.finalize
        (fun () ->
          let app =
            App.create
              ~terminal
              ~editor
              ~commands
              ~syntax
              ~languages
          in
          let* () = App.render app in
          loop app)
        (fun () -> Language.stop languages))
    (fun () -> Terminal.close terminal)

let () =
  let files =
    Sys.get_argv ()
    |> Array.to_list
    |> List.tl_exn
  in
  Lwt_main.run (run files)
```

**Architecture check:** This is a lifecycle specification, not a claim that
`App`, `Workspace`, or other modules are already implemented. Keep it stable
while constructing its dependencies. If later evidence requires a change,
record the reason before revising the main.

---

## 007. Invoke the first compiler error

```sh
dune build
```

**Expected if the libraries and build setup resolve:** the compiler reaches
an unresolved `App` module (often `Error: Unbound module App`). The line,
message, and error ordering depend on the actual toolchain. A Dune package or
syntax error is also useful evidence and must be resolved before proceeding.

Record, in your own words:

```text
Date/time:
Command: dune build
Exit status: (type what the shell reports)
FIRST exact error:
Hypothesis:
Smallest proposed change:
```

After inspecting the error, make the first meaningful commit yourself:

```sh
git add dune-project dune main.ml CHANGELOG.md
git diff --cached --stat
git diff --cached
git commit -m '001: specify oxed entry point'
```

Do **not** claim the program builds yet. The initial failure establishes the
next task; documenting it is a valid development milestone.

---

## 008. Add the first typed contract

The following `App` signature is an initial contract derived from `main.ml`.
It will intentionally reveal **more** missing modules and types. Type it by
hand only after you have examined the preceding diagnostic:

```sh
vim app.mli
```

```ocaml
type t
type event

val create :
  terminal:Terminal.t ->
  editor:Editor.t ->
  commands:Ed.t ->
  syntax:Syntax.t ->
  languages:Language.t ->
  t

val next_event : t -> event Lwt.t
val dispatch : t -> event -> unit Lwt.t
val render : t -> unit Lwt.t
val running : t -> bool
```

Compile again:

```sh
dune build
```

Read the **actual** first diagnostic. Do not invent all dependent modules at
once. `app.mli` also eventually needs an `app.ml` implementation; a signature
alone is not a completed module.

**Journal:** exact error; which type it demands; why the proposed signature
captures the desired contract; the next single file to add.

---

## 009. Add a typed, intentionally failing placeholder

When a module's type contract is ready, you may introduce a development-only
placeholder:

```sh
vim todo.ml
```

```ocaml
let undefined name = failwith ("TODO: " ^ name)
```

An **example** of a future function implementation is:

```ocaml
let render (_ : t) : unit Lwt.t =
  Todo.undefined "App.render"
```

This example is **not** a complete `app.ml`: defining `t`, `event`, the other
`App` functions, and their dependent types remains necessary. Unlike a bare
`assert false`, the exception carries the name of the unimplemented feature.

When a module compiles, replace placeholders with working behavior plus tests.
A successful build with reachable `Todo.undefined` calls is incomplete.

---

## 010. Continue the compiler-driven loop

For every subsequent missing module:

```sh
dune build
git status --short
git diff
git add CHANGELOG.md
```

Then add only the required `.mli` and `.ml`, re-run the build, verify the
changes, and commit with a meaningful message. Example once you have genuinely
implemented and tested a module:

```sh
git add app.mli app.ml CHANGELOG.md
git diff --cached
git commit -m '002: establish application event contract'
```

Adjust the files and message to match **what you actually completed**. Avoid
blindly running the example before `app.ml` exists.

### Journal-entry template (copy within this Markdown file as you progress)

```text
## YYYY-MM-DD — NNN. Topic
Goal:
Command:
Actual error / observation:
Why it occurred:
Smallest change made:
Test or reproduction:
Build result:
Git commit:
Open question / next compilation error:
```

### Quality gates

1. **Type gate:** modules and signatures agree; `dune build` succeeds.
2. **Runtime gate:** no reachable `Todo.undefined`, terminal cleanup works.
3. **Behavior gate:** editor edit/save/reopen tests and commands pass.
4. **Integration gate:** mouse, syntax, and LSP remain consistent with text.

---

## 011. Later, not today: syntax and LSP packages

Only after the core is functioning, check and install the parser and protocol
libraries in your **same** OxCaml switch:

```sh
opam show tree-sitter
opam show lsp
opam install tree-sitter lsp
```

Actual package build success does not establish that a specific OCaml grammar,
C binding, or LSP transport is correctly implemented. Verify interfaces in
the installed package and write dedicated tests. The usual position mismatch
is important: Tree-sitter UTF-8 byte offsets versus LSP UTF-16 positions.

---

## 012. First milestone acceptance checklist

- [ ] Unzipped the archive and locally cloned its real Git history.
- [ ] Set your own Git author identity.
- [ ] Selected an OxCaml (not ordinary OCaml) opam switch.
- [ ] Installed and queried Core, Zed, Lambda-term, and Lwt.
- [ ] Manually typed `dune-project`, `dune`, and the complete `main.ml`.
- [ ] Ran `dune build` and recorded its exact first result.
- [ ] Committed your entry-point specification and journal entry.
- [ ] Started `App.mli` only after reviewing the first compiler diagnostic.

**Exit criterion:** you own the source because you wrote it. The journal
explains not just **what** was done, but **what the compiler demanded and why**.

## Bootstrap — OxCaml compiler failure

### Attempt

    opam switch create oxcaml oxcaml-compiler \
      --repos ox=git+https://github.com/oxcaml/opam-repository.git,default

### Environment

- Platform: macOS ARM64
- opam: 2.6.1
- Compiler: oxcaml-compiler.5.4.0-ox9
- Bootstrap Dune: 3.23.1

### Failure

    ./_boot/dune.exe install ...
    Segmentation fault: 11
    exit-code: 139

### Hypothesis

The Dune bootstrap executable crashes during installation.
The underlying cause has not yet been established.

### Investigation

1. Preserve the partially installed switch.
2. Inspect the generated Dune executable.
3. Execute dune.exe --version.
4. Capture the LLDB backtrace if it crashes.
5. Verify macOS and compiler toolchain versions.

### Resolution

Pending investigation.

### Investigation 003 — Invalid reproduction

Observed:
    dune: option '--root': no .../rune-3.23.1 directory

Cause:
    Typographical error: rune instead of dune.

Exit status:
    1

Conclusion:
    Argument validation failed before installation.
    Original SIGSEGV remains unresolved.

Next:
    Repeat with the correct --root directory.

### Investigation 004 — Native runtime crash

Environment:
    macOS 26.7.1
    ARM64
    Apple Clang 21.0.0
    OxCaml 5.4.0-ox9
    Dune 3.23.1

Reproduction:
    dune.exe install --root ... --prefix ... dune

Observed:
    EXC_BAD_ACCESS (code=1, address=0x0)
    frame #0: 0x0000000000000000
    frame #1: caml_unix_pipe at pipe_unix.c:27

Analysis:
    The Unix runtime may be calling pipe2() through
    a missing weak-linked symbol.

Hypothesis:
    macOS 27 SDK used on macOS 26.

Next experiment:
    xcrun --sdk macosx --show-sdk-version
    xcrun --sdk macosx --show-sdk-path
    nm -m "$dune" | grep -E '_(pipe2|dup3)'

Resolution:
    Pending verification.

## Fri Nov 20 00:02:13 EST 2026
```
; dune build
File "main.ml", line 5, characters 17-20:
5 |     let* event = App.next_event app in
                     ^^^
Error: Unbound module App
```

## Fri Nov 20 00:06:57 EST 2026
```
; dune build
File "dune", lines 1-3, characters 0-80:
1 | (executable
2 |   (name main)
3 |   (libraries core core_unix zed lambda-term lwt.unix))
Error: Some modules don't have an implementation.
You need to add the following field to this stanza:

  (modules_without_implementation app)
```

## Fri Nov 20 00:13:12 EST 2026
```
; dune build
File "app.mli", line 5, characters 13-21:
5 |     terminal:Terminal.t ->
                 ^^^^^^^^
Error: Unbound module Terminal
```

## 2026-11-20 — 007. Asynchronous language services

### Observation

    Error: This expression has type Language.t
           but an expression was expected of type 'a Lwt.t

### Cause

    Language.start returned a concrete value.
    The let* operator expects an Lwt computation.

### Resolution

    Changed Language.start:

    From:
        Editor.t -> t

    To:
        Editor.t -> t Lwt.t

    Language.stop:
        t -> unit Lwt.t

### Principle

    A value and a computation producing that value
    are different types.

    Lwt.bind sequences asynchronous computations.

### Verification

    dune build

### Result

    Pending compilation.

## 2026-11-20 — 008. Partial function application

### Observation

    This expression has type
      (unit -> unit Lwt.t) -> unit Lwt.t

    but an expression was expected of type
      'a Lwt.t

### Cause

    Lwt.finalize was partially applied.

### Resolution

    Restore both cleanup functions:

        Language.stop languages
        Terminal.close terminal

### Principle

    OCaml functions are curried.

    Applying fewer arguments than required
    produces another function.

    A function returning a computation is
    not itself that computation.

### Verification

    dune build

### Result

    Pending compilation.

## 2026-11-20 — 009. Language service lifecycle

### Observation

    Error: Unbound value Language.stop

### Cause

    Language.stop is referenced by main.ml,
    but is absent from the exposed interface.

### Resolution

    Declare in language.mli:

        val stop : t -> unit Lwt.t

### Principle

    Resource acquisition and release should
    have explicit lifecycle contracts.

    Lwt.finalize guarantees that the cleanup
    callback runs when the protected computation
    completes or raises an exception.

### Verification

    dune build

### Result

    Pending compilation.

## 2026-11-20 — 010. From interfaces to implementations

### Observation

    Error: No implementations provided for:
        Syntax Terminal Workspace Language
        Ed App Editor

### Cause

    The interfaces type-check, but no native
    implementations exist for these modules.

### Resolution

    Created workspace.ml.

    Declared an abstract type t.

    Introduced a temporary failing implementation
    for Workspace.open_files.

    Removed workspace from
    modules_without_implementation.

### Principle

    An interface establishes a contract.
    An implementation satisfies that contract.
    A linker requires executable definitions.

### Verification

    dune build

### Result

    Pending compilation.

## 2026-11-20 — 012. Application coordinator

### Goal

Complete the implementation skeleton and link
our first OxCaml executable.

### Changes

Created app.ml.

Defined:
    event
    t
    create
    next_event
    dispatch
    render
    running

Implemented:
    App.create
    App.running

Deferred:
    App.next_event
    App.dispatch
    App.render

Removed modules_without_implementation
from dune.

### Verification

    dune build

### Result

    Pending compilation.

## 2026-11-20 — 013. Unused variant constructor

### Observation

    Error (warning 37 [unused-constructor]):
    unused constructor Pending.

### Cause

    Pending was declared but never used.
    Dune treats this warning as an error.

### Resolution

    Replaced:
        type event = Pending

    With:
        type event = unit

### Principle

    OCaml distinguishes product types (records),
    sum types (variants), and the unit type.

    Abstract signatures can hide the concrete
    representation chosen by an implementation.

### Verification

    dune build

### Result

    Pending compilation.

## 2026-11-20 — 014. Structural bootstrap

### Accomplished

- Established the OxCaml development environment.
- Diagnosed the macOS SDK compatibility problem.
- Created the Dune project.
- Defined the application lifecycle in main.ml.
- Established seven module interfaces.
- Introduced intentionally incomplete implementations.
- Constructed the application state and event loop contracts.

### Architecture

    Main
      App
        Terminal
        Workspace
        Editor
        Ed
        Syntax
        Language

### Verification

    dune build

### Result

    Record actual compiler result here.

### Commit

    bootstrap: establish oxed application skeleton

### Next milestone

    Implement Terminal using Lambda-term.
    Replace Terminal.open_ and Terminal.close
    with working resource management.

## 2026-11-20 — 017. Terminal compilation successful

### Observation

    dune build

    Exit status: 0

### Correction

    Lazy.Force -> Lazy.force

### Accomplished

    Terminal.open_ and Terminal.close now compile
    against Lambda-term.

### Remaining verification

    1. Acquire the terminal.
    2. Enter raw mode.
    3. Restore the original terminal mode.
    4. Verify that repeated close calls are safe.

### Next

    Isolated terminal lifecycle smoke test.

## 2026-11-20 — 020. Terminal lifecycle verified

### Experiment

    dune build test/terminal_smoke.exe

### Normal execution

    Terminal.open_ ()
    Terminal.close ()

Result: PASS

### Exceptional execution

    Lwt.fail Injected
    Lwt.finalize executes Terminal.close

Result: PASS

### Repeated cleanup

    Terminal.close terminal
    Terminal.close terminal

Result: PASS

### Conclusion

Terminal acquisition and restoration have passed
their first runtime tests.

Milestone 002: COMPLETE.

### Next

Milestone 003 — Keyboard event handling.
