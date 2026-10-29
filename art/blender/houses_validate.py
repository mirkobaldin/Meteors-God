"""Validate the six Blender villas and round-trip both mesh export formats.

blender -b -P art/blender/houses_validate.py
"""
import json
import math
import struct
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art/export/houses"
BLENDS = ROOT / "art/blender/houses"
RENDERS = ROOT / "art/renders/houses"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def bounds(objects):
    bpy.context.view_layer.update()
    points = [obj.matrix_world @ Vector(corner) for obj in objects
              if obj.type == "MESH" for corner in obj.bound_box]
    return [max(p[i] for p in points) - min(p[i] for p in points) for i in range(3)]


def glb_json(path):
    data = path.read_bytes()
    magic, version, size = struct.unpack_from("<III", data)
    require(magic == 0x46546C67 and version == 2 and size == len(data), "Invalid GLB header")
    length, kind = struct.unpack_from("<II", data, 12)
    require(kind == 0x4E4F534A, "Missing GLB JSON chunk")
    return json.loads(data[20:20 + length])


def validate(tier):
    bpy.ops.wm.open_mainfile(filepath=str(BLENDS / ("House%d.blend" % tier)))
    root = bpy.data.objects.get("House%d" % tier)
    require(root is not None and root.type == "EMPTY", "Missing editable house root")
    require(root.location.length < .0001, "Individual house root is not at the origin")
    require(bpy.data.objects.get("Base") is not None, "Missing Base")
    require(bpy.data.objects.get("Sign") is not None, "Missing Sign")
    require(bpy.context.scene.camera is not None, "Missing saved camera")
    require(bpy.context.scene.render.film_transparent, "Opaque render background")
    require(all(image.packed_file for image in bpy.data.images if image.type == "IMAGE" and image.size[0]),
            "Unpacked texture in portable Blender file")
    collection = bpy.data.collections["House%d" % tier]
    require(all(obj.parent is not None for obj in collection.all_objects if obj != root),
            "Detached house component")
    if tier == 4:
        require(all(any(obj.name.startswith("Level_%d_Front_Glass" % floor)
                        for obj in collection.objects) for floor in (1, 2, 3)), "Titan missing a floor")
        require(any(obj.name.startswith("Telescope_Lens") for obj in collection.objects), "Missing telescope")
    if tier == 5:
        rings = [obj for obj in collection.objects if obj.name.startswith("Orbital_Gold_Ring_")]
        require(len(rings) == 2 and all(obj.animation_data for obj in rings), "Missing animated orbital rings")
        require(bpy.data.objects.get("Floating_Level_Control") is not None, "Missing floating level")
        upper = bpy.data.objects["Floating_Upper_Pavilion_Floor"]
        lower = bpy.data.objects["Lower_Glass_Pavilion_Roof"]
        require(upper.location.z - lower.location.z > 9, "Floating floor gap too small")
    if tier == 6:
        require(bpy.data.objects.get("Captured_Star") is not None, "Missing captured star")
        require(any(obj.name.startswith("Glass_Entrance_Tread") for obj in collection.objects),
                "Missing grand glass staircase")
    manifest = json.loads((OUT / ("House%d_manifest.json" % tier)).read_text(encoding="utf-8"))
    require(manifest["footprint_radius"] < 100, "Model exceeds plot radius")
    require(max(m["triangles"] for m in manifest["meshes"]) <= 12000, "Export chunk too large")
    for suffix in ("", "_sheet"):
        path = RENDERS / ("House%d%s.png" % (tier, suffix))
        image = bpy.data.images.load(str(path), check_existing=False)
        require(tuple(image.size) == (1536, 1024), "Wrong render dimensions")
        require(image.channels == 4 and image.pixels[3] == 0, "Missing transparent render border")
        bpy.data.images.remove(image)
    doc = glb_json(OUT / ("House%d.glb" % tier))
    names = {n.get("name") for n in doc["nodes"]}
    require({"Base", "Sign", "House%d" % tier}.issubset(names), "Export contract names changed")
    require(len(doc.get("images", [])) >= 3, "Missing exported PBR textures")
    require(all("bufferView" in image for image in doc["images"]), "GLB image is not embedded")
    triangles = 0
    for mesh in doc["meshes"]:
        for primitive in mesh["primitives"]:
            count = doc["accessors"][primitive["indices"]]["count"] // 3
            require(count <= 12000, "GLB primitive exceeds mesh budget")
            require("NORMAL" in primitive["attributes"], "Missing export normals")
            require("TEXCOORD_0" in primitive["attributes"], "Missing export UVs")
            triangles += count
    require(triangles == manifest["triangles"], "Triangle count changed during export")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(OUT / ("House%d.glb" % tier)))
    glb_bounds = bounds(bpy.context.scene.objects)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(OUT / ("House%d.fbx" % tier)))
    fbx_bounds = bounds(bpy.context.scene.objects)
    # Axis conventions differ in glTF/FBX; compare sorted extents to catch scale errors.
    require(all(abs(a - b) < .05 for a, b in zip(sorted(glb_bounds), sorted(fbx_bounds))),
            "FBX/glTF round-trip size mismatch")
    radius = math.hypot(fbx_bounds[0] / 2, fbx_bounds[1] / 2)
    result = {"tier": tier, "triangles": triangles, "mesh_parts": manifest["export_meshes"],
              "max_mesh_triangles": max(m["triangles"] for m in manifest["meshes"]),
              "radius_studs": round(manifest["footprint_radius"], 3),
              "round_trip_extents": [round(v, 3) for v in fbx_bounds], "passed": True}
    print("VALIDATED", json.dumps(result), flush=True)
    return result


results = [validate(tier) for tier in range(1, 7)]
require((BLENDS / "Houses_Collection.blend").is_file(), "Missing combined Blender scene")
progression = bpy.data.images.load(str(RENDERS / "Houses_Progression.png"), check_existing=False)
require(tuple(progression.size) == (2400, 1200), "Wrong progression size")
pixels = np.empty(2400 * 1200 * 4, dtype=np.float32)
progression.pixels.foreach_get(pixels)
alpha = pixels.reshape((-1, 4))[:, 3]
require(np.count_nonzero(alpha > .05) > 50000, "Progression camera sees no houses")
bpy.data.images.remove(progression)
(OUT / "validation.json").write_text(json.dumps({"passed": True, "houses": results}, indent=2), encoding="utf-8")
print("ALL_SIX_HOUSES_VALIDATED", flush=True)
