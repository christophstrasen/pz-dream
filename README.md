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

## Local development

Deploy to your local Workshop wrapper folder (default):

```bash
./dev/sync-workshop.sh
```

Watch mode:

```bash
./dev/watch.sh
```

Deploy to your local mods folder:

```bash
./dev/sync-mods.sh
```

Tip: all `dev/watch.sh` scripts default to `TARGET=workshop`. Use `TARGET=mods` if you prefer `~/Zomboid/mods`.

## DREAM suite

For co-developing all DREAM modules together (sync all + watch all), use:

- https://github.com/christophstrasen/DREAM-Workspace
