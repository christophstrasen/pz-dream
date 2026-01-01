# DREAM — Declarative REactive Authoring Modules [42SP]

*The **meta-mod** for the DREAM mod family.*
[![CI](https://github.com/christophstrasen/pz-dream/actions/workflows/ci.yml/badge.svg)](https://github.com/christophstrasen/pz-dream/actions/workflows/ci.yml)

---

- **Mod ID:** `DREAM`
- **Display name:** `DREAM — Declarative REactive Authoring Modules [42SP]`

It exists to:
- provide a single Workshop item that points at the required mods
- ship examples and educational material

## Documentation scope

- This repo is the **suite entrypoint**: high-level orientation, curated examples, and user-facing guidance that spans multiple modules.
- Module-specific docs live in the respective repos (WorldObserver, PromiseKeeper, SceneBuilder, etc.).
- Maintainer coordination for the whole suite lives in `DREAM-Workspace`, including the workspace logbook:
  - https://github.com/christophstrasen/DREAM-Workspace/blob/main/logbook.md

## PromiseKeeper mental model (when this, then that)

PromiseKeeper is the suite’s persistent “when this happens, do that” module:

- A **promise** ties a `situationKey` (when) to an `actionId` (do that) with a `policy` (how often).
- `promiseId` is the stable identity of the rule (how you recognize/replace/disable “that promise” later).
- Each situation emission has an `occurranceKey` that identifies what the rule is acting on (tile, zombie,
  player). This drives idempotence and deterministic chance.

Read more in PromiseKeeper:
- https://github.com/christophstrasen/PromiseKeeper/blob/main/docs/concepts/mental_model.md
- https://github.com/christophstrasen/PromiseKeeper/blob/main/docs/concepts/ids.md
- https://github.com/christophstrasen/PromiseKeeper/blob/main/docs/guides/policy.md

## Wildcard patterns

DREAM examples use a small, explicit wildcard rule:
- Trailing `%` means “prefix match” (example: `"Police%"`, `"Road%"`).
- `%` by itself matches all names.

Where this applies (today):
- WorldObserver sprite interest `spriteNames` for `near` / `vision` scopes.
- WorldObserver zombie outfit helpers (`:hasOutfit(...)`).
- WorldObserver square floor material helpers (`:squareFloorMaterialMatches(...)`, `:isRoad()`).

Where this does **not** apply:
- `sprites` with `scope = "onLoadWithSprite"` requires explicit names (no wildcards).

## Local development

See `development.md`.

## DREAM suite

For co-developing all DREAM modules together (sync all + watch all), use:

- https://github.com/christophstrasen/DREAM-Workspace

## Examples

Console-friendly examples live under `Contents/mods/DREAM/42/media/lua/shared/examples/`.

- `examples/police_road_cone`: When a police zombie walks over a road square, spawn a cone on that tile with a 25% chance (PromiseKeeper + WorldObserver).
