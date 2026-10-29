# Render the built meteor and compose side-by-side / overlay comparisons with the reference.
# usage: blender -b meteor_build.blend --python render_compare.py -- <tag> [final_front.png final_34.png]
#   compare mode: clay rock + dark core (crack strips read as crevices) vs the reference sheet
#   final mode  : placeholder materials (grey rock, glowing core) to show the strips and the holes
import bpy, math, os, sys
import numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from imgutil import load, save

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TAG = argv[0] if argv else "v"
FINAL = argv[1:] if len(argv) > 1 else None

scene = bpy.context.scene
S = scene.get("meteor_scale", 1.0)   # build units -> exported units
rock = bpy.data.objects["Rock"]
core = bpy.data.objects["Core"]

def setup_render():
    scene.render.engine = "CYCLES"
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "OPTIX"
        prefs.get_devices()
        for d in prefs.devices:
            d.use = True
        scene.cycles.device = "GPU"
    except Exception as e:
        print("GPU setup failed", e)
    scene.cycles.samples = 64
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.012, 0.012, 0.012, 1)
    scene.world = world
    def light(name, loc, energy, size):
        L = bpy.data.lights.new(name, "AREA")
        L.energy = energy * S * S
        L.size = size * S
        o = bpy.data.objects.new(name, L)
        o.location = Vector(loc) * S
        o.rotation_euler = (-Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(o)
    light("Key", (-5.0, -5.0, 5.0), 950, 3.0)
    light("Fill", (5.0, -5.0, 0.5), 90, 5.0)
    light("Rim", (2.0, 6.0, 4.0), 250, 4.0)
    light("Under", (0.0, -4.0, -5.0), 25, 5.0)

def clay(name, color, emission=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = 0.85
    if emission:
        bsdf.inputs["Emission Color"].default_value = emission
        bsdf.inputs["Emission Strength"].default_value = 4.0
    return mat

def set_mat(ob, mat):
    ob.data.materials.clear()
    ob.data.materials.append(mat)

def cam_at(az_deg, ortho_scale, res, shift_px=(0, 0), px_per_unit=283.0, persp=False, elev_deg=0.0):
    c = bpy.data.cameras.new("C")
    o = bpy.data.objects.new("Cam", c)
    scene.collection.objects.link(o)
    az, el = math.radians(az_deg), math.radians(elev_deg)
    fwd = Vector((-math.sin(az) * math.cos(el), math.cos(az) * math.cos(el), -math.sin(el)))
    right = Vector((math.cos(az), math.sin(az), 0))
    if persp:
        c.type = "PERSP"
        c.lens = 85
        pos = -fwd * 7.5 * S
    else:
        c.type = "ORTHO"
        c.ortho_scale = ortho_scale * S
        pos = -fwd * 10 * S
    # shift_px = where the origin should appear relative to the image center (px right, px up)
    pos += (right * (-shift_px[0] / px_per_unit) + Vector((0, 0, -shift_px[1] / px_per_unit))) * S
    o.location = pos
    o.rotation_euler = fwd.to_track_quat("-Z", "Y").to_euler()
    scene.camera = o
    scene.render.resolution_x, scene.render.resolution_y = res
    return o

def render(path):
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)

setup_render()
if FINAL:
    scene.cycles.samples = 256
    cam_at(0, 0, (1024, 1024), persp=True, elev_deg=4)
    render(FINAL[0])
    if len(FINAL) > 1:
        cam_at(45, 0, (1024, 1024), persp=True, elev_deg=8)
        render(FINAL[1])
else:
    set_mat(rock, clay("Clay", (0.32, 0.31, 0.30, 1)))
    set_mat(core, clay("Dark", (0.03, 0.03, 0.03, 1)))
    # front: ref crop 740x580, 283 px/unit; the reference is turned ~5 deg (face 27 px right of ball center)
    cam_at(-5, 740 / 283, (740, 580), shift_px=(-2, 4))
    render(os.path.join(HERE, "r_front.png"))
    cam_at(45, 660 / 290, (660, 580), shift_px=(0, 3), px_per_unit=290)
    render(os.path.join(HERE, "r_34.png"))
    for key in ("front", "34"):
        refp = os.path.join(HERE, "ref_front.png" if key == "front" else "ref_threequarter.png")
        a = load(refp)[..., :3]
        b = load(os.path.join(HERE, "r_%s.png" % key))[..., :3]
        side = np.concatenate([a, np.full((a.shape[0], 8, 3), 0.5, np.float32), b], 1)
        save(side, os.path.join(HERE, "cmp_%s_%s.png" % (key, TAG)))
        ov = np.stack([a[..., 0], (a[..., 1] + b[..., 1]) * 0.5, b[..., 2]], -1)
        save(ov, os.path.join(HERE, "ov_%s_%s.png" % (key, TAG)))
print("done")
