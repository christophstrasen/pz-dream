# DREAM — Declarative REactive Authoring Modules [42SP]

*The **meta-mod** for the [DREAM](https://github.com/christophstrasen/DREAM) family.*

[![CI](https://github.com/christophstrasen/pz-dream/actions/workflows/ci.yml/badge.svg)](https://github.com/christophstrasen/pz-dream/actions/workflows/ci.yml)

---

[Steam Workshop → [42SP] DREAM — Declarative REactive Authoring Modules](LinkTBD)

---

## Scope

- Provide a single Workshop item that requires the other modules
- This repo is _not_ the **suite entrypoint** but rather a **packaging wrapper** to ship examples and small suite-wide educational and demo material that can be run in-game
- For a proper high level introduction and for collaboration visit [DREAM](https://github.com/christophstrasen/DREAM)

## Local development

See `development.md`.

## Examples

Console-friendly examples live under `Contents/mods/DREAM/42/media/lua/shared/examples/`.

- `examples/police_road_cone`: When a police zombie walks over a road square, spawn a cone on that tile with a 25% chance (PromiseKeeper + WorldObserver).
