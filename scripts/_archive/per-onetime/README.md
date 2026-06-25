# per-onetime/

One-time Python refactor scripts written by teammate **Per** during the
backend → frontend refactor (May–June 2026). All of them have already
been run against the codebase, and their results are committed in the
git history. They are **preserved here for archaeology** — not for
re-execution.

## Why archived, not deleted

Several of them are useful to *read* (to understand how a particular
mass-rename was done) and git history alone doesn't always make the
intent obvious. Keeping them under an `_archive/` folder also makes
their status clear: not part of the app, not part of the toolchain,
not runnable on this machine.

## Do NOT run these

- 4/11 scripts hardcode `C:\Users\Per\Downloads\noMoreF2TECH\…` —
  those paths only exist on Per's machine.
- 7/11 scripts use relative `src/…` paths and *could* technically
  run, but their changes have already been applied to the repo.
  Re-running them will produce no diff (or, worse, a conflicting one).
- None of them have a `requirements.txt`. `translate_locales.py`
  needs `deep-translator` which is not declared anywhere.

## What's in here

| File | Intent | Status |
|---|---|---|
| `extract_functions.py` | Pull code blocks out of a markdown file | done |
| `fix_stickers.py` | Add `stickerUrl` to layouts | done |
| `inject_lang.py` | Inject `lang` attribute (Per's local path) | done |
| `patch_admin_floors.py` | First attempt at patching `AdminFloorsView` | superseded |
| `patch_admin_floors_final.py` | Final, working version | done |
| `patch_all.py` | Multi-file patcher | done |
| `patch_layouts.py` | Layout-specific patches | done |
| `patch_logos.py` | Logo updates in layouts | done |
| `translate_locales.py` | i18n translation via Google Translate | done (vi, en, ja) |
| `update_headers.py` | Layout header updates | done |
| `update_logos.py` | Logo asset updates (Per's local path) | done |

## If you actually need a new bulk-edit script

Write it as a one-off shell or Node command in your shell history.
Don't reintroduce root-level `.py` files — they pollute the repo and
confuse the next person reading it.
