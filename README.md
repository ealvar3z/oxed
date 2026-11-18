# oxed

*A deliberately unfinished, compiler-driven OxCaml editor.*

The goal is a modern, terminal-native `ed` with a Zed-powered Unicode editing
core, a Lambda-term interface, mouse interaction, Tree-sitter syntax analysis,
and LSP integration. The architecture is specified up front; implementations
arrive one compiler diagnostic at a time.

**This ZIP is a Git repository, not a hosted Git URL.** Extract it, then clone
its directory locally:

```sh
unzip bootstrap-oxed.zip
git clone ./bootstrap-oxed oxed
cd oxed
git log --oneline -1
```

The archive includes a real `.git` directory and an initial documentation
commit. You can push your own working clone later if you choose. No GitHub
remote is configured.

## A repository designed for deliberate typing

There is **no `main.ml`, `dune`, `dune-project`, or working editor source** in
the seed. That is intentional. You said you want to type every word yourself,
so the journal gives the exact contents to transcribe rather than supplying an
already-working implementation. Type the source by hand in your preferred
editor and record the observations. Do not paste the error messages in the
journal unless you actually received them.

Start at **[CHANGELOG.md](CHANGELOG.md)**, step 001. It covers host tools, opam,
OxCaml, package installation, project files, the end-state `main.ml`, the first
intentional compile failure, and the next interface. [SPEC.md](SPEC.md) freezes
the design and the milestones.

## What the first build means

Once you have typed `main.ml`, `dune build` should fail because the editor's
own modules do not exist. This is success for the first stage: the compiler has
accepted the environment and reached our missing architecture. The errors you
actually see are the source of truth; version and package failures take priority
if they occur first.

A passing build will eventually mean only **type/link completeness**. Working
editing behavior is a separate milestone and must be demonstrated by tests and
interactive use. Temporary `Todo.undefined` functions may compile but will
raise when invoked.

## Rules

- Preserve the end-state `main.ml` while developing its dependencies.
- Prefer real `.mli` contracts and typed placeholders, never `Obj.magic`.
- Preserve the user's own Git author identity in subsequent commits.
- Record one observed error, remedy, build result, and commit per iteration.
- Do not add Tree-sitter or LSP packages until their corresponding milestone.
- Confirm upstream APIs before writing adapters; a written design is not proof
  that an external function exists.

## Sources checked on 2026-11-18

- OxCaml installation: <https://oxcaml.org/get-oxcaml/>
- OxCaml opam overlay: <https://github.com/oxcaml/opam-repository>
- OxCaml package switch guidance: <https://opam.ocaml.org/packages/oxcaml/>
- Zed: <https://opam.ocaml.org/packages/zed/>
- Lambda-term: <https://opam.ocaml.org/packages/lambda-term/>
- Dune: <https://dune.readthedocs.io/en/stable/quick-start.html>

Package compatibility with your exact OxCaml switch has **not** been verified
by compiling on your computer. The journal deliberately includes explicit
verification and records failures rather than silently substituting a standard
OCaml compiler.
