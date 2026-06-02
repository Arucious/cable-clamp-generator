# Compatibility notes & modifications

Deviations from a naive "just reuse the upstream libs" build, and workarounds made for MakerWorld
(OpenSCAD 2026.01.14, Manifold backend) + current BOSL2 (2026-01). Flagged here so future maintainers
know where the bodies are buried. The README links to this file.

## 1. Multiboard backer — switched libraries (QuackWorks → cschneid)
- **What:** the Multiboard/Multiconnect mount uses cschneid's `multiconnectSlotDesign.scad` (`multiconnectBack()`,
  plain OpenSCAD, no BOSL2). We do **NOT** use QuackWorks' `multiconnectSlotDesignBOSL.scad`.
- **Why:** the QuackWorks BOSL2 module renders **empty** on current BOSL2 (≥2026-01) — even standalone. Its
  `attachable`/`diff()` usage broke against newer BOSL2. It would fail on MakerWorld too.
- **Risk / watch:** if Multiboard fit is off, it's our use of cschneid's geometry, not QuackWorks'. If QuackWorks
  is ever fixed upstream and you want it back, re-verify against the pinned OpenSCAD/BOSL2 first.

## 2. Vendored `multiconnectSlotDesign.scad` was modified
- **What:** removed the file's top-level demo `multiconnectBack(...)` call, and turned its six file-level globals
  (`slotQuickRelease`, `dimpleScale`, `slotTolerance`, `slotDepthMicroadjustment`, `onRampEnabled`,
  `onRampEveryXSlots`) into parameters of `multiconnectBack()`/`slotTool` with defaults.
- **Why:** `use <file>` does not import a file's top-level vars, so those globals were `undef` → slots/dimples/
  on-ramp silently degraded. Parameterizing makes the module `use`-safe and lets `MB_Dimples`/`MB_OnRamp` work.
- **Risk / watch:** **re-applying upstream updates** to this file will clobber the edits — re-do them. CC-BY-NC
  (Chris Schneider) permits modification with attribution; header note added.

## 3. openConnect receiver — built from `openconnect_head`, not `openconnect_slot_grid`
- **What:** the openConnect mount carves its slot receiver from mitufy's `openconnect_head(head_type="slot")`
  profile plus a hand-built slide-in entry channel — NOT `openconnect_slot_grid()`.
- **Why:** `openconnect_slot_grid()` (BOSL2 tag-based `intersect()`) produces **non-manifold** output under the
  Manifold backend (MakerWorld's). `openconnect_head` uses plain `linear_extrude`+`difference` CSG → manifold.
- **Risk / watch:** the receiver's real-world mate with a printed openConnect head/screw is **not yet verified by
  print** — confirm fit on a test print. Hand-tuned dims: entry channel 17.4 × 10.6 × 2.9 mm (the 17.4 vs 17.2
  head width is a deliberate +0.2 to avoid coplanar T-junctions).

## 4. openGrid snap T-junctions — watertight verified on CGAL, not Manifold
- **What:** tests that assert `trimesh.is_watertight` on snap-containing geometry render with `backend="CGAL"`.
  A separate test confirms the default (Manifold) backend renders without error.
- **Why:** `base_snap`'s nub geometry leaves T-junction coincident faces in Manifold-backend STL output that trip
  trimesh's strict watertight check — **even though OpenSCAD's Manifold backend reports `NoError`** (i.e. it
  renders fine on MakerWorld and the Manifold library guarantees manifoldness). CGAL's Nef Boolean eval yields a
  clean mesh trimesh accepts.
- **Risk / watch:** if a slicer or MakerWorld ever rejects the Manifold output of a snap body, the fallback is to
  export that part via CGAL. So far Manifold reports NoError, so this is a trimesh-strictness artifact, not a
  real defect.

## 5. "Knurl" ring-nut grip is currently a chamfered cylinder
- **What:** the `Nut_Grip = "Knurl"` option renders a plain chamfered cylinder, not a true knurled texture.
- **Why:** BOSL2 surface `texture` was slow and prone to non-manifold artifacts on a small ring. "Flats" (the
  default) and "Wings" are real; "Knurl" is a placeholder.
- **Risk / watch:** purely cosmetic. Revisit with a manifold-safe knurl if desired.

## 6. Toolchain pins (for MakerWorld parity)
- **OpenSCAD 2026.01.14** (matches MakerWorld's renderer) and **BOSL2 @ 7e5dfe5 (2026-01-18)**, installed locally.
- **BOSL2 is NOT bundled** in the upload — MakerWorld provides it. Only the openGrid (mitufy) + MultiConnect
  (cschneid) `.scad` files are bundled.
- **Risk / watch:** if MakerWorld bumps its OpenSCAD/BOSL2, re-run the test suite against the new versions before
  re-publishing — the mitufy openGrid libs are the most BOSL2-version-sensitive piece.
