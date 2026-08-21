# apothecary CLI — agent contract

How AI systems and automation should drive the `apo` CLI. Humans can use the interactive menu; agents must not.

**Entry:** `./apo` (repo root) → `scripts/apo.sh`  
**UI kit:** `scripts/ui.sh`  
**Engine:** `apothecary/apothecary` (real build tool; `apo` is the pretty front-end)

When used **from openFrameworks**, prefer the submodule:

```text
openFrameworks/scripts/apothecary/apo
```

oF’s own agent notes: `openFrameworks/scripts/AGENTS.md` (`of` downloads prebuilts; `apo` compiles formulas).

---

## Rules (always)

1. **Prefer explicit commands** with a library name (or `core`). Never rely on bare `./apo` menus in CI/agents.
2. **Disable chrome:**
   ```bash
   NO_COLOR=1 UI_ANIM=0 ./apo <command> …
   ```
3. **Always set `TYPE` and `ARCH`** when not targeting the host default.
4. **Do not parse spinner / task redraw lines.** Use final `key  value` lines and the engine’s own logs.
5. **Confirms:** `confirmYes` defaults to **yes** on empty Enter. Non-TTY `read` with empty stdin often auto-accepts. Prefer piping `yes` only when you intend to proceed; never hang waiting for a human.
6. **Require a library list** for `update` / `download` / `build` / `clean` / `remove` — no bare action with zero libs.
7. **Direct engine passthrough** is available for unknown verbs if `apothecary/apothecary` exists; still set `TYPE`/`ARCH` via env so the wrapper passes `-t`/`-a`.
8. **Verify every network source before use.** Archive downloads must declare a pinned SHA-256 and call `verify_sha256` before extraction. Git downloads must check out a pinned 40-character commit and call `verify_git_commit`. Run `scripts/audit-formula-checksums.sh` after formula changes.

---

## Commands

| Command | Purpose | Agent notes |
|--------|---------|-------------|
| `apo status` | Host, TYPE/ARCH, paths, formula count | Safe first call |
| `apo formulas` | List formula names | Alias: `libs` |
| `apo platforms` | Build types + arches | |
| `apo version` | CLI version | |
| `apo update <lib…>` | Download + build + copy | Main path; needs lib(s) or `core` |
| `apo download <lib…>` | Sources only | |
| `apo build <lib…>` | Compile only | |
| `apo modular <lib…>` | Stage XCFramework output | Accepts core names, addon names, or formula script paths |
| `apo variant <profile> [build\|package\|all]` | Build an isolated modular variant | Profiles: `opencv-cuda`, `opencv-cuda-ai`; Linux/Windows only |
| `apo clean <lib…>` | Clean build tree | |
| `apo remove <lib…>` | Remove from build cache | |
| `apo help` | Usage | |
| `apo menu` / bare `apo` on TTY | Interactive | **Do not use** in agents |
| `apo demo` | UI preview | Skip in automation |

Unknown commands may **passthrough** to the underlying `apothecary` binary.

---

## Environment

| Variable | Default | Meaning |
|----------|---------|---------|
| `TYPE` | host OS (`osx`, `linux`, …) | Build type (`-t`). Also accepted: `TARGET`. `macos` is normalized to the engine's canonical `osx` target. |
| `ARCH` | host arch | Architecture (`-a`) |
| `FORCE=1` | `0` | Force re-download (`-f`). Alias: `APO_FORCE` |
| `VERBOSE=1` | off | Extra logging (`-v`) |
| `NO_COLOR=1` | off | No ANSI color |
| `UI_ANIM=0` | `1` | No spinners / list animation |
| `OUTPUT_FOLDER` | `<repo>/out` | Install / package output (`-d`) |
| `BUILD_DIR` | `<repo>/build` | Build cache (`-b`) |
| `PACKAGE_LIBS` | unset | Space/comma-separated non-core staging directories for `scripts/package-individual.sh` |
| `OPENCV_EXTRA_DEFINES` | unset | Additional CMake definitions for modular OpenCV variants |

**Valid `TYPE` values (wrapper list):**  
`osx` `macos` `ios` `tvos` `xros` `watchos` `catos` `android` `linux` `vs` `msys2` `emscripten`

**Arch examples:**  
- `osx` / `macos`: `arm64`, `x86_64`  
- Apple mobile: `arm64`, `SIM_arm64`, `x86_64`  
- `android`: e.g. `arm64`, `x86_64` (as supported by scripts)

---

## Paths

| Path | Role |
|------|------|
| repo root | Apothecary project root |
| `apothecary/formulas/` | Library formulas |
| `apothecary/apothecary` | Engine binary/script |
| `scripts/calculate_formulas.sh` | Per-target / per-bundle formula lists |
| `.github/path-filters.yml` | CI path groups (keep in sync with calculate_formulas) |
| `.github/workflows/detect-path-changes.yml` | Reusable dorny/paths-filter job |
| `out/` | Default `OUTPUT_FOLDER` (built libs) |
| `build/` | Default `BUILD_DIR` (build cache) |

**openFrameworks integration:** set output into OF’s tree, e.g.:

```bash
export OUTPUT_FOLDER="/path/to/openFrameworks/libs"
export BUILD_DIR="/path/to/openFrameworks/scripts/apothecary/build"
```

(or whatever path the OF menu already exports when launching apo).

---

## Recipes (copy/paste)

```bash
export NO_COLOR=1 UI_ANIM=0

# Inspect
./apo status
./apo formulas
./apo platforms

# Host: update one library
./apo update zlib

# Host: core set
./apo update core

# Cross / explicit target
TYPE=android ARCH=arm64 ./apo update openssl
TYPE=osx ARCH=arm64 FORCE=1 ./apo update glfw glm

# Download only / build only
./apo download curl
./apo build curl

# Install into a custom folder (e.g. OF libs)
OUTPUT_FOLDER=/path/to/openFrameworks/libs \
BUILD_DIR=/path/to/apothecary/build \
TYPE=osx ARCH=arm64 \
  ./apo update core
```

---

## Exit codes (current)

| Code | Meaning |
|------|---------|
| `0` | Success (also “cancelled” after a no-confirm in some paths — check logs) |
| non-zero | Missing lib args, engine missing, build failure, unknown command without passthrough |

Bare `./apo` with **no TTY** prints help and exits **1**.

No `--json` / `--quiet` yet. Engine lines are the source of truth for compile errors.

---

## Output parsing (until --json)

From `status` / help footers, prefer lines like:

```text
  host           osx / arm64
  type           osx
  arch           arm64
  out            /…/out
  build          /…/build
  formulas       /…/formulas
```

`formulas` command lists one name per line (after the banner). Ignore task UI redraws.

---

## Anti-patterns

- `./apo` or `./apo menu` in headless agent sessions  
- `apo update` with **no** library names  
- Building `ios` / `android` / multi-arch without user request  
- Assuming `out/` is openFrameworks `libs/` (only if `OUTPUT_FOLDER` was set)  
- Treating prebuilt **download** via OF (`of update libs`) as the same as **compiling** here  
- Parsing gum / braille spinner frames  
- Changing `scripts/calculate_formulas.sh` without updating `.github/path-filters.yml` and the matching workflow `on.paths`  
- Putting `nghttp2` / `nghttp3` / `ngtcp2` / `libssh2` into published artifacts or xcframeworks (they are curl build-only)  
- Editing openFrameworks from this repo unless the user asked  

---

## CI

Stay in this repo. Commit titles are plain sentences (no `fix(x):` prefixes).

### Path filters

Two layers. Formula groups must match `scripts/calculate_formulas.sh`.

1. **Workflow `on.paths`** — GitHub does not brace-expand; list both `formulas/name.sh` and `formulas/name/**`. Linux must not start for an openssl-only change.
2. **Job-level bundles** — each build workflow calls `detect-path-changes.yml`. Skip a matrix bundle unless engine, that platform’s scripts, or that bundle’s formulas changed. `workflow_dispatch` always builds.

`.github/workflows/*` is gitignored except a whitelist. New workflow files need `!/.github/workflows/<file>.yml` in `.gitignore`.

`detect-path-changes.yml` is a `workflow_call`. Callers see `github.event_name == 'workflow_call'` inside it, so:

- Callers OR `github.event_name == 'workflow_dispatch'` in the job `if`.
- The detect job diffs with git (`token: ''`) against `github.event.pull_request.base.sha` or `github.event.before`.

Engine paths (apothecary, toolchains, `calculate_formulas.sh`, `scripts/build.sh` / `package.sh`, `.github/workflows/**`, `.github/path-filters.yml`) rebuild **every bundle of every workflow that starts**.

| Group | Rebuilds |
|-------|----------|
| `apple-bundle1` | pixman zlib utf8 libpng brotli pugixml freetype libxml2 svgtiny FreeImage assimp glew videoInput rtAudio tess2 uriparser cairo |
| `apple-bundle2` | glm json zlib glfw opencv portaudio libusb (iOS subset is glm json opencv) |
| `apple-bundle3` | fmt openssl nghttp2 nghttp3 ngtcp2 libssh2 curl poco dawn |
| `vs-bundle1` / MSYS2 1 | pixman zlib libpng brotli freetype libxml2 svgtiny assimp FreeImage glew glfw glm json libusb kiss portaudio pugixml utf8 videoInput rtAudio tess2 uriparser opencv cairo |
| `vs-bundle2` / MSYS2 2 | fmt openssl nghttp2 nghttp3 ngtcp2 libssh2 curl poco dawn |
| `linux-formulas` | glm json utf8 brotli zlib libpng glew glfw freetype libxml2 svgtiny tess2 kiss FreeImage fmt uriparser |
| `android-formulas` | linux-like core plus pugixml assimp opencv openssl nghttp\* libssh2 curl |
| `emscripten-formulas` | default emscripten brew list (includes svgtiny) |

Apple platforms: bundles 1/2/3. VS: bundles 1/2. MSYS2 / Android / Emscripten / Linux: no bundle matrix (whole job skips or runs).

When all matrix bundles skip, downstream jobs skip too (iOS `wait-for-workflows` / `build-xcframework`, macOS smoke test). That is intended.

### Artifacts

- Retention: 90 days. Missing upload must fail (`if-no-files-found: error`) on VS.
- VS restores one named artifact via `.github/actions/restore-named-artifact` (exact name like `libs-latest-vs-64-1`). PRs look up the last successful **bleeding** run of the same workflow file; missing artifact is a skip.
- MSYS2: `cache: true`, `update: false` on pull_request. `clangarm64` runs on `windows-11-arm` with `release: true`. `MSYSTEM=CLANGARM64` is native — do not set `CROSSCOMPILING=1` or look for `msys2x86_64.toolchain.cmake`.
- Package with `ALWAYS_BUILD` so PRs still produce the zip.

### Formula lists and depends

- `calculate_formulas.sh` is the brew order. Private curl HTTP/3 deps (`nghttp2` `nghttp3` `ngtcp2` `libssh2`) must appear **before** `curl` and stay in `FORMULAS_INTERNAL` (pickles yes, tarball/xcframework no).
- A parent formula must not `load()` if a `FORMULA_DEPENDS` dir is missing (`formulaDependsReady` / `skipCachedFormula`).
- Changing a bundle list here requires the same names in `.github/path-filters.yml` and each workflow’s `on.paths`.

---

## Relationship to openFrameworks `of`

| Goal | Tool |
|------|------|
| Download stock prebuilt packages | `of update libs` / `of setup` |
| Check OF tree health | `of status` |
| Compile a formula from source | `apo update <lib>` |
| Install compiled libs into OF | `apo` with `OUTPUT_FOLDER=…/libs` (or OF’s apothecary menu) |

---

## Version

CLI version appears as `cli` / banner (e.g. `0.3.0`). Keep this file aligned with `apo help`.
