# OpenSCAD / toolchain setup (pinned for MakerWorld parity)

Recorded 2026-06-02. These exact versions were installed and verified (all three mount libs render manifold).

## OpenSCAD
- **Version: 2026.01.14 snapshot** — chosen to exactly match MakerWorld's Parametric Model Maker renderer.
- Installed from the OpenSCAD snapshot archive: `https://files.openscad.org/snapshots/OpenSCAD-2026.01.14.dmg`
  (downloaded with `curl`, mounted with `hdiutil`, copied to `/Applications`, quarantine cleared with `xattr -dr`).
- Binary: `/Applications/OpenSCAD-2026.01.14.app/Contents/MacOS/OpenSCAD`
- Set `OPENSCAD_BIN` to that path if it ever moves.

## BOSL2 (local only — NOT bundled; MakerWorld provides BOSL2)
- Installed to the OpenSCAD user library dir: `~/Documents/OpenSCAD/libraries/BOSL2`
- **Pinned commit: `7e5dfe5275b23f1b568962e2e286f0630c0c9b57`** (2026-01-18, contemporary with the OpenSCAD build).
- The test harness puts `~/Documents/OpenSCAD/libraries` on `OPENSCADPATH`; override with `OPENSCAD_LIBDIR`.

## Vendored libs (flat in `cable_clamp/`, bundled for upload)
- **mitufy / opengrid-projects** (`github.com/mitufy/opengrid-projects`, lib/): `opengrid_base.scad`,
  `opengrid_threads_lib.scad`, `opengrid_snap_lib.scad`, `openconnect_lib.scad` — CC-BY. Use BOSL2.
- **cschneid / MultiConnectOpenSCAD** (`github.com/cschneid/MultiConnectOpenSCAD`, Modules/):
  `multiconnectSlotDesign.scad` — CC-BY-NC (Chris Schneider). **Plain OpenSCAD, no BOSL2.** License bundled as
  `cable_clamp/LICENSE-MultiConnectOpenSCAD`.

## Rejected
- QuackWorks `Modules/multiconnectSlotDesignBOSL.scad` (`github.com/AndyLevesque/QuackWorks`) renders **empty** on
  BOSL2 ≥ 2026-01 (its `attachable`/`diff()` usage broke) — incompatible with MakerWorld's current renderer. Do not use.

## Python
- Shared venv at `../.venv` (Python 3.13). Dev deps in `tests/requirements-dev.txt`: trimesh, numpy, pytest.

## Verified (Task 0 de-risk, 2026-06-02)
- `base_snap` (openGrid snap), `openconnect_slot_grid` (openConnect), and `multiconnectBack` (Multiboard) all
  render **manifold, NoError** on the above OpenSCAD + BOSL2.
