# Export the built meteor: .blend working file + .glb (Rock + Core), with a final sanity report.
import bpy, bmesh, os

ART = r"C:\Users\mirko\Desktop\Meteors-God\art\reference"
rock = bpy.data.objects["Rock"]
core = bpy.data.objects["Core"]

for ob in (rock, core):
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    nonman = sum(1 for e in bm.edges if not e.is_manifold)
    bm.free()
    xs = [v.co for v in me.vertices]
    lo = [min(c[a] for c in xs) for a in range(3)]
    hi = [max(c[a] for c in xs) for a in range(3)]
    print("REPORT %s tris=%d nonmanifold=%d uv=%s mats=%s bbox_min=%s bbox_max=%s" % (
        ob.name, sum(len(p.vertices) - 2 for p in me.polygons), nonman, [u.name for u in me.uv_layers],
        [m.name for m in me.materials], ["%.3f" % v for v in lo], ["%.3f" % v for v in hi]))

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART, "meteor_base.blend"), compress=True)

for o in bpy.context.scene.objects:
    o.select_set(o in (rock, core))
bpy.context.view_layer.objects.active = rock
bpy.ops.export_scene.gltf(filepath=os.path.join(ART, "meteor_base.glb"), export_format="GLB",
                          use_selection=True, export_apply=True, export_yup=True,
                          export_texcoords=True, export_normals=True, export_materials="EXPORT")
print("REPORT exported")
