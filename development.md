# DREAM [42SP] — Development

This repo is the **meta-mod** for the DREAM mod family.

Part of the DREAM suite:
- DREAM-Workspace (multi-repo convenience): https://github.com/christophstrasen/DREAM-Workspace

Prereqs (for the `dev/` scripts): `rsync`, `inotifywait` (`inotify-tools`), `inkscape`.

## Sync

Deploy to your local Workshop wrapper folder (default):

```bash
./dev/sync-workshop.sh
```

Optional: deploy to `~/Zomboid/mods` instead:

```bash
./dev/sync-mods.sh
```

## Watch

Watch + deploy (default: Workshop wrapper under `~/Zomboid/Workshop`):

```bash
./dev/watch.sh
```

Optional: deploy to `~/Zomboid/mods` instead:

```bash
TARGET=mods ./dev/watch.sh
```

## Tests

Headless unit tests (require/path + metadata sanity checks):

```bash
busted --helper=tests/helper.lua tests/unit
```

Note: tests assume DREAMBase is available at `../DREAMBase` (DREAM-Workspace layout) or `external/DREAMBase`.

## Lint

```bash
luacheck Contents/mods/DREAM/42/media/lua/shared/examples
```

## Pre-commit hooks

This repo ships a `.pre-commit-config.yaml` mirroring CI (`luacheck` + `busted`).

Enable hooks:

```bash
pre-commit install
```

Run on demand:

```bash
pre-commit run --all-files
```

## Suite testing

For suite-level local testing, prefer using `DREAM-Workspace` and run (from the workspace root):

```bash
./dev/sync-all.sh
./dev/smoke.sh
```

## Notes

Because this is a meta-mod, most changes are about:
- dependencies in `mod.info`
- examples / docs / learning material
