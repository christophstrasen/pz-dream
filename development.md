# DREAM [42SP] — Development

This repo is the **meta-mod** for the DREAM mod family.

Part of the DREAM suite:
- DREAM-Workspace (multi-repo convenience): https://github.com/christophstrasen/DREAM-Workspace

## Quickstart (single repo)

Prereqs: `rsync`, `inotifywait` (`inotify-tools`), `inkscape`.

Watch + deploy (default: Workshop wrapper under `~/Zomboid/Workshop`):

```bash
./dev/watch.sh
```

Optional: deploy to `~/Zomboid/mods` instead:

```bash
TARGET=mods ./dev/watch.sh
```

## What to test

Because this is a meta-mod, most changes are about:
- dependencies in `mod.info`
- examples / docs / learning material

For “suite-level” local testing, prefer using DREAM-Workspace and run:

```bash
./dev/sync-all.sh
./dev/smoke.sh
```
