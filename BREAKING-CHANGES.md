# Breaking changes (read before updating)

**`git pull` by itself does not delete your data or restart containers.**  
Your running stack keeps working until you rebuild / re-apply / re-run `install.sh`.

If you installed from an **older revision** of this repo, those next steps **are not an in-place upgrade**. They can break the app or leave you on an unsupported layout. **Back up first.** Prefer a **fresh install** (new data directory / new PVCs) when moving to the current manifests.

## What changed

| Older clone | Current repo | Safe path |
|-------------|--------------|-----------|
| `lscr.io/linuxserver/heimdall` | Build `heimdall:local` from official `php:apache` | Keep the old commit **or** export bookmarks / screenshot tiles, wipe `data/`, reinstall |
| LinuxServer-style `/config` tree (`www/`, `keys/`, …) | New `/config` layout (Laravel storage + sqlite under `/config`) | Do **not** mount old data into the new image |

## If you already have a working Heimdall

1. **Do nothing** — leave containers as they are; skip `install.sh` / `compose up` after pull.
2. Or pin the last working commit and stay there.
3. Or migrate deliberately: back up `data/`, remove it, run a **new** install from `main`, re-add links.

`install.sh` refuses to proceed when it detects LinuxServer Heimdall data unless you set:

```bash
I_UNDERSTAND_THIS_IS_A_FRESH_INSTALL=yes ./install.sh
```

That override means you accept starting clean (or you already moved old data aside).
