# MakerWorld Publishing Guide

This document covers the exact steps to publish this generator on
[MakerWorld's Parametric Model Maker](https://makerworld.com).

---

## 1. What to upload

Run the packaging script first to populate `dist/makerworld/`:

```bash
bash scripts/package_makerworld.sh
```

Upload **exactly these 10 files** (all flat, no subfolders):

```
cable_clamp_generator.scad   ← MAIN file
clamp.scad
mount.scad
multiconnectSlotDesign.scad
openconnect_lib.scad
opengrid_base.scad
opengrid_snap_lib.scad
opengrid_threads_lib.scad
params.scad
thread.scad
```

**Do NOT upload:**
- BOSL2 or any BOSL2 subfolder — MakerWorld provides it on the platform.
- `previews/`, `tests/`, `docs/`, `dist/`, `.step` reference files, or any
  Python/shell scripts.

---

## 2. Publishing steps on makerworld.com

1. Log in to [makerworld.com](https://makerworld.com).
2. Click **Upload** → **3D Model** → choose **Parametric Model Maker / OpenSCAD**.
3. Upload `cable_clamp_generator.scad` as the **Main file** (not a `.3mf`).
   MakerWorld detects the `.scad` extension and enables the Parametric Model
   Maker / Customize button automatically.
4. Add the other 9 `.scad` files as **Additional / Dependency files**. Keep
   them flat (no subfolders) — they must sit alongside the main file in the
   same directory so the `use <X.scad>` includes resolve by filename alone.
5. Confirm BOSL2 resolves automatically (it is pre-installed on MakerWorld).
   If a `can't open library 'BOSL2/...'` error appears, check that no
   uploaded file accidentally bundles a local BOSL2 path. All bundled files
   use bare `use <filename.scad>` or `include <BOSL2/...>` only.
6. Open **Customize**, exercise the parameter groups (Mount System, Cable Bore
   Diameter, Part, etc.), and render a couple of variants to confirm geometry.

---

## 3. Publish settings

| Setting | Value |
|---------|-------|
| License | **CC BY-NC-SA 4.0** |
| Main file | `cable_clamp_generator.scad` |
| Cover images | `cable_clamp/previews/multiboard_b16.png`, `openconnect_b10.png`, `opengrid_full_b14.png`, `opengrid_lite_b8.png` |

**Attribution / credits to include in the model description:**

- **David D** — openGrid system and Multiconnect slot system
- **Jonathan / Keep Making** — Multiboard mount system
- **mitufy** — openGrid snap and openConnect libraries
  (`opengrid_snap_lib.scad`, `openconnect_lib.scad`)
- **Chris Schneider / cschneid** — MultiConnect OpenSCAD implementation
  (`multiconnectSlotDesign.scad`)
- **Hands on Katie & BlackjackDuck** — Underware cable management ecosystem
- **user_3607339627** — original concept this generator is based on:
  <https://makerworld.com/en/models/1870669>

---

## 4. Pre-publish checklist

- [ ] Rendered **Body** part in the Customizer for each mount system:
  Multiboard, openGrid (Full board), openGrid (Lite board), openConnect,
  Underware.
- [ ] Rendered **Ring Nut** part — confirm it threads onto a Body.
- [ ] No console errors in the MakerWorld Customizer (warnings about `$fn`
  are acceptable).
- [ ] Parameter groups are clearly labeled in the Customizer UI (they derive
  from the `/* [Group Name] */` comments in `params.scad`).
- [ ] License set to CC BY-NC-SA 4.0.
- [ ] Attribution text in the model description (see Section 3).
- [ ] Cover images uploaded (`previews/*.png`).

---

## 5. Draft-first workflow

Publish the model as **private / draft** first. Then:

1. Open the MakerWorld Customizer on the live draft and exercise all parameter
   combinations end-to-end — this is the definitive platform confirmation.
2. The local parity render (run before committing) already simulates the
   MakerWorld environment: `OPENSCADPATH` is set to the BOSL2 library dir
   only, and the main file is rendered from `dist/makerworld/` with no
   `cable_clamp/` on the search path. All 4 variants (Multiboard Body,
   Ring Nut, openConnect Body, openGrid snap Body) exported successfully with
   exit code 0 and non-zero file sizes, confirming the flat bundle is
   self-resolving.
3. The openConnect receiver fit and openGrid snap/slot tolerances are
   best confirmed with a physical test print before going public — see
   `COMPATIBILITY_NOTES.md` for measured fit data.
4. Once satisfied, flip the model from draft to **public**.
