import os, shutil, subprocess
from pathlib import Path
import trimesh

REPO = Path(__file__).resolve().parent.parent          # project root (cable-clamp-generator/)
CC   = REPO / "cable_clamp"                              # flat model dir (path-less includes resolve here)
# BOSL2 lives here (the dir that CONTAINS the BOSL2/ folder). Override with OPENSCAD_LIBDIR.
BOSL2_LIBDIR = os.environ.get("OPENSCAD_LIBDIR", str(Path.home() / "Documents/OpenSCAD/libraries"))

def _openscad_bin():
    for c in [
        os.environ.get("OPENSCAD_BIN"),
        "/Applications/OpenSCAD-2026.01.14.app/Contents/MacOS/OpenSCAD",
        "/Applications/OpenSCAD (Nightly).app/Contents/MacOS/OpenSCAD",
        "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
        shutil.which("openscad"),
    ]:
        if c and Path(c).exists():
            return c
    raise RuntimeError("OpenSCAD binary not found; set OPENSCAD_BIN")

def _env():
    return {**os.environ, "OPENSCADPATH": f"{CC}{os.pathsep}{BOSL2_LIBDIR}"}

def _fmt(v):
    if isinstance(v, bool):  return "true" if v else "false"
    if isinstance(v, str):   return f'"{v}"'
    return repr(v)

def _run(src_path, params, out, fast):
    cmd = [_openscad_bin(), "-o", str(out), "--export-format", "binstl"]
    if fast:
        cmd += ["-D", "$fn=24"]
    for k, v in params.items():
        cmd += ["-D", f"{k}={_fmt(v)}"]
    cmd += [str(src_path)]
    res = subprocess.run(cmd, capture_output=True, text=True, env=_env(), timeout=300)
    if res.returncode != 0:
        raise subprocess.CalledProcessError(res.returncode, cmd, res.stdout, res.stderr)
    return out

def render_scad(source: str, params: dict, tmp_path, fast=True) -> Path:
    """Render an OpenSCAD source STRING. Path-less `use <thread.scad>` resolves via OPENSCADPATH=CC."""
    src = Path(tmp_path) / "model.scad"; src.write_text(source)
    return _run(src, params, Path(tmp_path) / "out.stl", fast)

def render_file(scad_file, params, tmp_path, fast=True) -> Path:
    """Render an actual repo .scad file IN PLACE (path relative to REPO) so its own
    path-less includes resolve from its dir (cable_clamp/)."""
    return _run(REPO / scad_file, params, Path(tmp_path) / "out.stl", fast)

def measure_stl(stl_path) -> dict:
    mesh = trimesh.load(str(stl_path))
    ext = mesh.bounding_box.extents
    return {
        "bbox": tuple(round(float(x), 2) for x in ext),
        "volume": float(mesh.volume),
        "watertight": bool(mesh.is_watertight),
        "bounds": [[round(float(c), 3) for c in row] for row in mesh.bounds],
    }
