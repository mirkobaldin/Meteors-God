# Step 5: bake the high-res sculpt into textures on the game mesh, then keep only the light version.
#   Rock (18k tris) gets a tangent-space normal map and an ambient-occlusion map baked from the 200k Rock.
#   Core uses its 2k copy (smooth, nothing to bake).
# usage: blender -b --factory-startup ../meteor_base.blend --python bake_meteor.py
import bpy, bmesh, math, os
import numpy as np

ART = os.path.dirname(bpy.data.filepath)
TEX = os.path.join(ART, "textures")
SIZE = 2048
os.makedirs(TEX, exist_ok=True)
sc = bpy.context.scene

hi, lo = bpy.data.objects["Rock"], bpy.data.objects["Rock_Game"]
core_hi, core_lo = bpy.data.objects["Core"], bpy.data.objects["Core_Game"]
for lc in bpy.context.view_layer.layer_collection.children:
    lc.hide_viewport = False
    lc.exclude = False
    lc.collection.hide_render = False
for o in (lo, core_lo):
    o.hide_set(False)
    o.hide_render = False

def only(objs, active):
    for o in bpy.context.view_layer.objects:
        o.select_set(o in objs)
    bpy.context.view_layer.objects.active = active

def chart_unwrap(ob):
    """Few big UV islands: the ball is split into 6 cube-like regions (the whole face is one of them),
    each unwrapped in one piece, so tiling BlendKit materials and the baked maps have almost no seams."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.faces.ensure_lookup_table()
    axes = np.array([[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]], float)
    chart = {}
    for f in bm.faces:
        c = np.array(f.calc_center_median())
        chart[f.index] = int(np.argmax(axes @ (c / (np.linalg.norm(c) + 1e-9))))
    for e in bm.edges:
        lf = e.link_faces
        e.seam = len(lf) == 2 and chart[lf[0].index] != chart[lf[1].index]
    bm.to_mesh(ob.data)
    bm.free()
    only([ob], ob)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.unwrap(method="ANGLE_BASED", margin=0.004)
    bpy.ops.uv.average_islands_scale()
    try:
        bpy.ops.uv.pack_islands(rotate=True, margin=0.004)
    except TypeError:
        bpy.ops.uv.pack_islands(margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    # stretch report: UV area / 3D area per face, relative to the median
    me = ob.data
    uv = me.uv_layers.active.data
    ratios = []
    for p in me.polygons:
        a3 = p.area
        if a3 <= 1e-12:
            continue
        pts = [uv[i].uv for i in p.loop_indices]
        a2 = abs(sum(pts[k].x * pts[(k + 1) % len(pts)].y - pts[(k + 1) % len(pts)].x * pts[k].y
                      for k in range(len(pts)))) / 2
        ratios.append(a2 / a3)
    r = np.array(ratios) / np.median(ratios)
    print("REPORT", ob.name, "UV stretch percentiles (5,25,75,95):", np.percentile(r, [5, 25, 75, 95]).round(2))

chart_unwrap(lo)
chart_unwrap(core_lo)

sc.render.engine = "CYCLES"
try:
    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.compute_device_type = "OPTIX"
    prefs.get_devices()
    for d in prefs.devices:
        d.use = True
    sc.cycles.device = "GPU"
except Exception as e:
    print("GPU setup failed", e)

def image(name):
    img = bpy.data.images.get(name) or bpy.data.images.new(name, SIZE, SIZE, alpha=False)
    img.colorspace_settings.name = "Non-Color"
    return img

# the low-poly material: base colour x AO, baked normal map
old = bpy.data.materials.get("Rock")
if old:
    old.name = "Rock_HD_placeholder"
mat = bpy.data.materials.new("Rock")
mat.use_nodes = True
nt = mat.node_tree
bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
bsdf.inputs["Roughness"].default_value = 0.85
tex_n = nt.nodes.new("ShaderNodeTexImage"); tex_n.location = (-700, -250)
tex_ao = nt.nodes.new("ShaderNodeTexImage"); tex_ao.location = (-700, 200)
nmap = nt.nodes.new("ShaderNodeNormalMap"); nmap.location = (-350, -250)
mix = nt.nodes.new("ShaderNodeMix"); mix.location = (-350, 200)
mix.data_type, mix.blend_type = "RGBA", "MULTIPLY"
mix.inputs["Factor"].default_value = 1.0
a_in = next(i for i in mix.inputs if i.name == "A" and i.type == "RGBA")
b_in = next(i for i in mix.inputs if i.name == "B" and i.type == "RGBA")
out = next(o for o in mix.outputs if o.name == "Result" and o.type == "RGBA")
a_in.default_value = (0.18, 0.17, 0.16, 1.0)
nt.links.new(tex_ao.outputs["Color"], b_in)
nt.links.new(out, bsdf.inputs["Base Color"])
nt.links.new(tex_n.outputs["Color"], nmap.inputs["Color"])
nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
lo.data.materials.clear()
lo.data.materials.append(mat)

bake = sc.render.bake
bake.margin = 16

# normal map: from the 200k Rock onto the 18k Rock
img_n = image("Meteor_Rock_Normal")
tex_n.image = img_n
nt.nodes.active = tex_n
core_hi.hide_render = core_lo.hide_render = True
bake.use_selected_to_active = True
bake.cage_extrusion = 0.012
bake.max_ray_distance = 0.04
sc.cycles.samples = 8
only([hi, lo], lo)
bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT")
img_n.filepath_raw = os.path.join(TEX, "meteor_rock_normal.png")
img_n.file_format = "PNG"
img_n.save()
print("REPORT baked normal")

# ambient occlusion on the game mesh itself (crevices and strips darken)
img_ao = image("Meteor_Rock_AO")
tex_ao.image = img_ao
nt.nodes.active = tex_ao
hi.hide_render = True
bake.use_selected_to_active = False
if sc.world is None:
    sc.world = bpy.data.worlds.new("World")
sc.world.light_settings.distance = 0.08
sc.cycles.samples = 128
only([lo], lo)
bpy.ops.object.bake(type="AO")
img_ao.filepath_raw = os.path.join(TEX, "meteor_rock_ao.png")
img_ao.file_format = "PNG"
img_ao.save()
print("REPORT baked AO")

# keep only the light version
main = bpy.data.collections["Meteor"]
for o in (hi, core_hi):
    bpy.data.objects.remove(o)
game = bpy.data.collections.get("Meteor Game (Roblox)")
for o in (lo, core_lo):
    for c in list(o.users_collection):
        c.objects.unlink(o)
    main.objects.link(o)
if game:
    bpy.data.collections.remove(game)
lo.name = lo.data.name = "Rock"
core_lo.name = core_lo.data.name = "Core"
core_lo.hide_render = False
for img in (img_n, img_ao):
    img.filepath = bpy.path.relpath(img.filepath_raw)
for m in [m for m in bpy.data.materials if m.users == 0]:
    bpy.data.materials.remove(m)
for me in [m for m in bpy.data.meshes if m.users == 0]:
    bpy.data.meshes.remove(me)
for o in (lo, core_lo):
    print("REPORT", o.name, sum(len(p.vertices) - 2 for p in o.data.polygons), "tris, mats",
          [m.name for m in o.data.materials], "uv", [u.name for u in o.data.uv_layers])
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath, compress=True)

only([lo, core_lo], lo)
bpy.ops.export_scene.gltf(filepath=os.path.join(ART, "meteor_base.glb"), export_format="GLB", use_selection=True,
                          export_apply=True, export_yup=True, export_texcoords=True, export_normals=True,
                          export_materials="EXPORT")
print("REPORT saved blend + glb")
