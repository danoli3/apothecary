# apothecary — cleanup & support task list

Based on a read-through of the repo (root README, `apothecary/README.md`, `apothecary/PROGRESS.md`, `scripts/AGENTS.md`, `scripts/apo.sh`, `docker/README.md`, `.github/workflows/`) on 2026-08-11.

## P0 — broken or misleading right now

1. **`./apo` doesn't exist at repo root.** `scripts/AGENTS.md` documents `./apo` as the entry point and the new root README now references it too, but there's no `apo` file/symlink at the repo root — only `apothecary.sh`. Either add a root-level `apo` (symlink or thin wrapper to `scripts/apo.sh`, matching how `apothecary.sh` already forwards to it) or fix `AGENTS.md` to point at `apothecary.sh`. This is the single biggest doc/reality mismatch in the repo.
2. **`apothecary/PROGRESS.md` is stale.** It only tracks ~20 libs and is missing `openssl`'s current state split, plus `brotli`, `curl`(partially), `gstreamer`, `json`, `libpng`, `libssh2`, `libusb`, `libxml2`, `metalangle`, `opencv`, `pixman`, `pugixml`, `shaderc`, `svgtiny`, `uriparser`, `utf8`, `zlib` aren't in the table at all. Either regenerate it from `apothecary/formulas/` or drop it and rely on CI badges + `apo status`/`apo formulas`.
3. **No root `CONTRIBUTING.md`.** `apothecary/README.md` has a great "Writing Formulas" guide but nothing tells a new contributor how to open a PR, which platforms need testing, or how CI (`.github/workflows/*`) maps to platforms. Worth splitting a short `CONTRIBUTING.md` out of the existing formula-writing docs.
4. **`docker/README.md` has stale paths.** Example commands (`./apothecary/apothecary/apothecary`, `apothecary/scripts/build.sh`) don't match the current root layout (`apothecary/apothecary`, `scripts/build.sh`) and never mention `./apo`. Needs a pass once the `apo` root-entry question above is settled.

## P1 — accuracy / consistency

5. **Formula list drift.** Root README previously listed 26 libraries and was missing `cairo` (typo'd as "cario"), `fmod`, `fmodex`, `gstreamer`, `kiss`, `libssh2`, `metalangle`, `opencv`, `shaderc`. Fixed in this pass — but there's no automated check tying the README list to `apothecary/formulas/*`, so it will drift again. Consider generating that section (`apo formulas` output) at release time instead of hand-maintaining it.
6. **Legacy CI configs.** `.travis.yml` and `.appveyor.yml` still sit at the repo root alongside a full GitHub Actions suite (19 workflows). If Travis/AppVeyor are no longer used, remove them (or note clearly in a comment why they're kept) so contributors don't think two CI systems are both live.
7. **`legacy_tomes/` is undocumented.** Contains a `uri` formula that's presumably superseded by `uriparser` — no README explains what "legacy tomes" means or when something should move there vs. be deleted.
8. **Encrypted keys committed at repo root/`scripts/`** (`scripts/id_rsa.enc`, `scripts/githubactions-id_rsa.enc`). Not a README issue, but worth a one-line note in `CONTRIBUTING.md`/`SECURITY.md` on what these are for and the rotation process, since it's the kind of thing that raises questions in a fresh clone.
9. **Windows section duplicated build type info.** Root README repeated "Setup your Environment" as a heading twice (one empty). Fixed in this pass.

## P2 — nice to have

10. **No top-level architecture diagram.** A short "how a formula run flows" diagram (download → prepare → build → copy → clean, plus how `FORMULA_DEPENDS` recurses) would help newcomers faster than prose alone — `apothecary/README.md` already has the words, just not a picture.
11. **No `--json`/`--quiet` output**, called out as a known gap in `scripts/AGENTS.md` itself ("No `--json` / `--quiet` yet"). Worth an issue/milestone since it blocks cleaner agent/CI parsing.
12. **Per-library support matrix regeneration.** If `PROGRESS.md` is kept (see #2), script it to regenerate from `apothecary/formulas/` + last CI run status rather than hand-edited.
13. **`apothecary/legacy_tomes` and `apothecary/formulas/_depends`** could use one-line READMEs explaining their purpose, same treatment the top-level docs now get.

## What changed in this pass

- Rewrote root `README.md`: removed the duplicated/empty "Setup your Environment" section, fixed the library list (typo + 9 missing libs), switched primary usage examples to `./apo` (per `scripts/AGENTS.md`) while keeping the raw `apothecary/apothecary` engine syntax as a documented fallback, added missing build-status rows (VS2026, MSYS2, Linux cross/RPi with real badges instead of a static "complete" label), and tightened Requirements/Quick Start/Commands into tables instead of prose.
- Everything above this section is what's still open.
