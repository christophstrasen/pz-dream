# pz-dream — Agent Guide

Quick rules for working with this repo (the DREAM **meta-mod**).

## Priority and scope

- **Priority:** system > developer > `AGENTS.md` > `.aicontext/*` > task instructions > file-local comments.
- **Scope:** this file applies to `pz-dream/` (this repo only).

## Interaction style

- Keep answers direct; skip flattery.
- Ask when unsure rather than guessing (especially about Build 42 API behavior).
- Preserve behavior when refactoring; call out intentional behavior changes.
- Prefer minimal changes over speculative “future-proofing”.
- Prefer direct, fail-fast code in examples; avoid overly defensive guardrails or silent fallbacks.

## What this repo is (and is not)

- **This repo is the suite entrypoint:** high-level orientation, dependency wiring, and curated examples.
- **This repo is not the source of truth for module internals.** Avoid duplicating detailed API docs that belong in module repos; link to them instead.

## Sources to load first (when writing docs/examples)

Within DREAM these repos sit next to `pz-dream/`:
- WorldObserver: `../WorldObserver/readme.md`, `../WorldObserver/docs/`, plus `../WorldObserver/.aicontext/context.md`
- PromiseKeeper: `../PromiseKeeper/readme.md`, `../PromiseKeeper/docs/`, plus `../PromiseKeeper/.aicontext/context.md`
- SceneBuilder: `../SceneBuilder/readme.md`, plus `../SceneBuilder/.aicontext/context.md`

If you are **not** operating inside DREAM and those folders are missing, ask for the relevant repo version (or a link) before making claims about behavior/APIs.

When a claim depends on module behavior, **verify it from those docs or code**. If it’s unclear, ask rather than guessing.

## Documentation + examples rules

- **Target audience:** modders using the DREAM suite; keep examples copy/paste-ready and explain intent before details.
- **Keep examples small and composable:** prefer “one concept per file” over big end-to-end demos.
- **Prefer stable seams:** examples should use public APIs of modules; avoid reaching into internals unless the module docs explicitly endorse it.
- **Keep `require()` paths Build 42 compatible:** use slash-separated paths (e.g. `require("examples/dream_examples")`), don’t rely on `init.lua` auto-loading, don’t hack `package.path` in shipped code.
- **No ad-hoc logging:** use repo-provided utilities (typically `require("DREAMBase/util")`) instead of `print`.
- **Preserve existing example contracts:** `Contents/mods/DREAM/42/media/lua/shared/examples/dream_examples.lua` is required by tests and must keep exporting a table with a `name` field.
- **Zomboid style:** prefer direct calls that assume engine APIs exist; fail fast rather than wrapping everything in safe-call guards.
- **Logging:** never include `:` in any `print` or log message text; use spaces or dashes instead.

## Project Zomboid + Lua constraints (baseline)

- Target runtime is **Project Zomboid Build 42** (Lua 5.1 / Kahlua).
- Keep code compatible with **vanilla Lua 5.1** where feasible (tests run outside the engine).
- Avoid metatable “magic” (`setmetatable`) unless explicitly requested.

## Testing expectations

- For changes to examples, `require()` paths, or mod layout, run repo tests:
  - `luacheck Contents/mods/DREAM/42/media/lua/shared/examples`
  - `busted --helper=tests/helper.lua tests/unit`
- Prefer using `pre-commit run --all-files` where available (mirrors CI).
- For suite-level validation inside DREAM, prefer:
  - `../dev/sync-all.sh`
  - `../dev/smoke.sh`

## Safety / ops

- NixOS + `zsh`; ignore noisy `gpg-agent` warnings at shell start.
- Avoid destructive git operations (no reset/force-push) unless explicitly requested.
