"""Review tool: renders the base meteor mesh in grey clay next to art/reference/meteor_base.png.

    python art/blender/base_review.py <out.png>
"""

import math
import os
import sys

import bpy
import bmesh  # noqa: F401
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import meteor_base as mb  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(HERE, "..", "reference", "meteor_base.png")


def clay():
    m = bpy.data.materials.new("Clay")
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.32, 0.31, 0.3, 1)
    b.inputs["Roughness"].default_value = 0.85
    return m


def to_object(name, bm, mat, smooth=False):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = smooth
    me.materials.append(mat)
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def apply(obj, mod):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)


def build_clay(seed=1):
    mat = clay()
    stones, base, brows, cutter = mb.build_base(seed)
    st = to_object("Stones", stones, mat)
    fb = to_object("FaceBase", base, mat, smooth=True)
    sol = fb.modifiers.new("Thick", "SOLIDIFY")
    sol.thickness = 0.05
    sol.offset = -1
    apply(fb, sol)
    c = to_object("Cutter", cutter, mat)
    for target in (st, fb):
        boo = target.modifiers.new("Carve", "BOOLEAN")
        boo.operation = "DIFFERENCE"
        boo.object = c
        boo.solver = "EXACT"
        boo.use_self = True
        boo.use_hole_tolerant = True
        apply(target, boo)
    bpy.data.objects.remove(c)
    b = to_object("Brows", brows, mat, smooth=True)
    # Dark core so the holes read like the reference (in the game it glows).
    import bmesh as _bm
    core = _bm.new()
    _bm.ops.create_icosphere(core, subdivisions=4, radius=0.4)
    dark = bpy.data.materials.new("Dark")
    dark.use_nodes = True
    dark.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.01, 0.01, 0.01, 1)
    to_object("Core", core, dark, smooth=True)
    return [st, fb, b]


def camera(loc, target, ortho):
    cam = bpy.data.cameras.new("Cam")
    cam.type = "ORTHO"
    cam.ortho_scale = ortho
    obj = bpy.data.objects.new("Cam", cam)
    obj.location = loc
    obj.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.scene.camera = obj
    return obj


def render(path, res=(700, 560)):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def load(path):
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:]).reshape(h, w, 4)
    return px[::-1]  # top-down


def main():
    out = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else sys.argv[1]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.02, 0.02, 0.02, 1)
    sc.world = world
    sc.view_settings.view_transform = "Standard"
    for name, loc, energy in (("Key", (-2, -3, 3), 170), ("Fill", (3, -2, 0.5), 45), ("Top", (0, 0, 4), 50)):
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy
        light.size = 3
        o = bpy.data.objects.new(name, light)
        o.location = loc
        o.rotation_euler = (-Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        sc.collection.objects.link(o)
    build_clay()
    tmp = os.path.dirname(os.path.abspath(out))
    front = os.path.join(tmp, "_front.png")
    side = os.path.join(tmp, "_side.png")
    camera((0, -5, 0.15), (0, 0, 0.0), 1.25)
    render(front)
    camera((4.0, -3.0, 0.4), (0, 0, 0.0), 1.25)
    render(side)
    # Side by side: reference (top) / ours (bottom).
    ref = load(REF)
    a = load(front)
    b = load(side)
    h, w = a.shape[:2]
    ref_front = ref[0:590, 40:780]
    ref_side = ref[0:590, 830:1530]

    def fit(img):
        ys = np.linspace(0, img.shape[0] - 1, h).astype(int)
        xs = np.linspace(0, img.shape[1] - 1, w).astype(int)
        return img[ys][:, xs]

    top = np.concatenate([fit(ref_front), fit(ref_side)], axis=1)
    bottom = np.concatenate([a, b], axis=1)
    sheet = np.concatenate([top, bottom], axis=0)
    H, W = sheet.shape[:2]
    img = bpy.data.images.new("Sheet", W, H, alpha=True)
    img.pixels = sheet[::-1].reshape(-1)
    img.filepath_raw = out
    img.file_format = "PNG"
    img.save()


if __name__ == "__main__":
    main()
