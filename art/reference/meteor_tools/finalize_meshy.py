# Finalize the processed Meshy meteor: diameter 1, UVs, game-resolution copies, .blend + .glb in art/reference.
import bpy, bmesh, math, os, sys
from mathutils import Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ART = r"C:\Users\mirko\Desktop\Meteors-God\art\reference"
GAME_ROCK, GAME_CORE = 18000, 2000

sys.path.insert(0, HERE)
from imgutil import load, save, crop

def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)

def apply_mod(ob, kind, **props):
    m = ob.modifiers.new(kind.lower(), kind)
    for k, v in props.items():
        setattr(m, k, v)
    with bpy.context.temp_override(object=ob, active_object=ob, selected_objects=[ob]):
        bpy.ops.object.modifier_apply(modifier=m.name)

def clean(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    for _ in range(6):
        bad = [e for e in bm.edges if not e.is_manifold]
        if not bad:
            break
        if all(len(e.link_faces) == 1 for e in bad):
            bmesh.ops.holes_fill(bm, edges=bad, sides=0)
            rest = [e for e in bad if e.is_valid and e.is_boundary]
            if rest:
                bmesh.ops.contextual_create(bm, geom=rest)
        else:
            faces = list({f for e in bad for v in e.verts for f in v.link_faces})
            bmesh.ops.delete(bm, geom=faces, context="FACES")
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bmesh.ops.triangulate(bm, faces=bm.faces)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bad = sum(1 for e in bm.edges if not e.is_manifold)
    bm.to_mesh(ob.data)
    bm.free()
    return bad

def smart_uv(ob):
    for o in bpy.context.view_layer.objects:
        o.select_set(o is ob)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.003)
    bpy.ops.object.mode_set(mode="OBJECT")

def smooth(ob, deg):
    with bpy.context.temp_override(object=ob, active_object=ob, selected_objects=[ob], selected_editable_objects=[ob]):
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(deg))

def collection(name, hide=False):
    c = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    if c.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(c)
    bpy.context.view_layer.layer_collection.children[c.name].hide_viewport = hide
    c.hide_render = hide
    return c

def move(ob, coll):
    for c in list(ob.users_collection):
        c.objects.unlink(ob)
    coll.objects.link(ob)

rock, core = bpy.data.objects["Rock"], bpy.data.objects["Core"]
dims = [max(v.co[a] for v in rock.data.vertices) - min(v.co[a] for v in rock.data.vertices) for a in range(3)]
S = 1.0 / max(dims)
for ob in (rock, core):
    ob.data.transform(Matrix.Scale(S, 4))
print("REPORT scale %.4f, rock dims" % S, [round(d * S, 3) for d in dims])

main = collection("Meteor")
game = collection("Meteor Game (Roblox)", hide=True)
for ob in (rock, core):
    move(ob, main)
    smart_uv(ob)

for src, target, angle in ((rock, GAME_ROCK, 35), (core, GAME_CORE, 50)):
    g = src.copy()
    g.data = src.data.copy()
    g.name = g.data.name = src.name + "_Game"
    game.objects.link(g)
    apply_mod(g, "DECIMATE", ratio=target / tris(g))
    bad = clean(g)
    smooth(g, angle)
    print("REPORT", g.name, tris(g), "nonmanifold", bad)
for ob in (rock, core):
    bm = bmesh.new(); bm.from_mesh(ob.data)
    print("REPORT", ob.name, tris(ob), "nonmanifold", sum(1 for e in bm.edges if not e.is_manifold),
          "uv", [u.name for u in ob.data.uv_layers], "mat", [m.name for m in ob.data.materials])
    bm.free()

# reference images behind the model (Empty > Image), sized for the normalized model
refc = collection("Meteor Reference")
ref = load(os.path.join(ART, "meteor_base.png"))
for key, box in (("front", (40, 20, 780, 600)), ("threequarter", (840, 20, 1500, 600))):
    save(crop(ref, *box), os.path.join(HERE, "ref_%s.png" % key))
def empty(name, path, size, loc, rot):
    img = bpy.data.images.load(path)
    img.pack()
    e = bpy.data.objects.new(name, None)
    e.empty_display_type = "IMAGE"
    e.data = img
    e.empty_display_size = size
    e.location = loc
    e.rotation_euler = rot
    e.use_empty_image_alpha = True
    e.color[3] = 0.5
    refc.objects.link(e)
empty("Ref_Front", os.path.join(HERE, "ref_front.png"), 740 / 283 * S, (-25 / 283 * S, 1.0, -3 / 283 * S), (math.radians(90), 0, 0))
az = math.radians(45)
empty("Ref_3-4", os.path.join(HERE, "ref_threequarter.png"), 660 / 290 * S,
      (-1.0 * math.sin(az), 1.0 * math.cos(az), 0), (math.radians(90), 0, az))

bpy.context.scene["meteor_scale"] = S
for o in bpy.context.view_layer.objects:
    o.select_set(False)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART, "meteor_base.blend"), compress=True)

# .glb for the game: the light copies, named Rock / Core
rg, cg = bpy.data.objects["Rock_Game"], bpy.data.objects["Core_Game"]
rock.name, core.name = "Rock_HD", "Core_HD"
rg.name, cg.name = "Rock", "Core"
bpy.context.view_layer.layer_collection.children[game.name].hide_viewport = False
for o in bpy.context.view_layer.objects:
    o.select_set(o in (rg, cg))
bpy.ops.export_scene.gltf(filepath=os.path.join(ART, "meteor_base.glb"), export_format="GLB", use_selection=True,
                          export_apply=True, export_yup=True, export_texcoords=True, export_normals=True,
                          export_materials="EXPORT")
print("REPORT exported glb")
