# DREAM — Declarative REactive Authoring Modules [42SP]

This repo is the **meta-mod** for the DREAM mod family.

- **Mod ID:** `DREAM`
- **Display name:** `DREAM — Declarative REactive Authoring Modules [42SP]`

It exists to:
- provide a single Workshop item that points at the required mods
- ship examples and educational material

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
