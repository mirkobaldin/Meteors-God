# Turn the Meshy image-to-3D result into the game asset (step 3 of 4):
#   Rock: the Meshy sculpt, with the seams between its rocks sunk into "strips"
#   Core: a smooth inner layer just under the rock, visible through the strips, the eyes and the mouth
# Build units match the reference: ball half-height 1, face toward -Y, face center at x = 0.
import bpy, bmesh, math, os, sys, time
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
GLB = os.path.join(HERE, "meshy_meteor.glb")
OUT = os.path.join(HERE, "meshy_processed.blend")
VOXEL = 0.007        # uniform working resolution
BASE_VOXEL = 0.05    # coarse copy that becomes the "average surface"
STRIP_T0, STRIP_T1 = 0.02, 0.045   # how far below the average surface a seam starts / is fully a strip
FACE_EXTRA = 0.015  # stricter on the face
STRIP_DEPTH = 0.12   # how far strips sink
CORE_DEPTH = 0.05    # inner layer, below the average surface
ROCK_TRIS = 200000
CORE_TRIS = 6000

T0 = time.time()
def log(*a):
    print("[meshy %6.1fs]" % (time.time() - T0), *a, flush=True)

def apply_mod(ob, kind, **props):
    m = ob.modifiers.new(kind.lower(), kind)
    for k, v in props.items():
        setattr(m, k, v)
    with bpy.context.temp_override(object=ob, active_object=ob, selected_objects=[ob]):
        bpy.ops.object.modifier_apply(modifier=m.name)

def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)

def nonmanifold(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    n = sum(1 for e in bm.edges if not e.is_manifold)
    bm.free()
    return n

def copy(ob, name):
    c = ob.copy()
    c.data = ob.data.copy()
    c.name = c.data.name = name
    bpy.context.scene.collection.objects.link(c)
    return c

def arrays(ob):
    me = ob.data
    n = len(me.vertices)
    co = np.empty(n * 3); me.vertices.foreach_get("co", co)
    nr = np.empty(n * 3); me.vertex_normals.foreach_get("vector", nr)
    return co.reshape(-1, 3), nr.reshape(-1, 3)

def clean(ob):
    """Close the rare holes / pinched flaps the decimator leaves."""
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
    bm.to_mesh(ob.data)
    bm.free()

def material(name, color, emission=None):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = 0.85
    if emission:
        bsdf.inputs["Emission Color"].default_value = emission
        bsdf.inputs["Emission Strength"].default_value = 3.0
    return mat

def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)

# Eye opening traced from the reference front view (left eye; build units, face center at x = 0)
EYE = [(-0.75, 0.13), (-0.81, 0.02), (-0.75, -0.13), (-0.61, -0.22), (-0.46, -0.225), (-0.36, -0.19),
       (-0.28, -0.13), (-0.40, -0.02), (-0.55, 0.06), (-0.68, 0.12)]
EYE_RINGS = [(-1.6, "local", 1.12), (-0.90, "local", 1.0), (-0.62, "local", 0.82), (-0.12, "origin", 0.45)]
EYE_POCKET = [(-1.6, "local", 0.9), (-0.78, "local", 0.9), (-0.52, "local", 0.68)]

def catmull_closed(pts, per_seg):
    P = [np.array(p) for p in pts]
    P = [P[-1]] + P + [P[0], P[1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(per_seg):
            t = k / per_seg
            out.append(tuple(0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                                    + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t)))
    return out

def loft_cutter(name, outline, rings):
    """Closed tube through the outline: rings (y, 'local'|'origin', scale)."""
    bm = bmesh.new()
    cu = sum(p[0] for p in outline) / len(outline)
    cv = sum(p[1] for p in outline) / len(outline)
    vr = []
    for (y, mode, sc) in rings:
        if mode == "local":
            vr.append([bm.verts.new((cu + (u - cu) * sc, y, cv + (v - cv) * sc)) for (u, v) in outline])
        else:
            vr.append([bm.verts.new((u * sc, y, v * sc)) for (u, v) in outline])
    M = len(outline)
    for i in range(len(vr) - 1):
        for j in range(M):
            bm.faces.new((vr[i][j], vr[i][(j + 1) % M], vr[i + 1][(j + 1) % M], vr[i + 1][j]))
    f0 = bm.faces.new(vr[0][::-1])
    f1 = bm.faces.new(vr[-1])
    bmesh.ops.triangulate(bm, faces=[f0, f1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob

def cut(ob, cutters):
    coll = bpy.data.collections.new("cut_" + ob.name)
    bpy.context.scene.collection.children.link(coll)
    for c in cutters:
        bpy.context.scene.collection.objects.unlink(c)
        coll.objects.link(c)
    apply_mod(ob, "BOOLEAN", operation="DIFFERENCE", operand_type="COLLECTION", collection=coll, solver="MANIFOLD")
    for c in cutters:
        bpy.data.objects.remove(c)
    bpy.data.collections.remove(coll)

MOUTH_INSIDE = [(-0.74, "local", 1.0), (-0.40, "local", 1.0)]

def rounded_rect(u0, u1, v0, v1, r, n=6):
    pts = []
    for (cu, cv, a0) in ((u1 - r, v0 + r, -90), (u1 - r, v1 - r, 0), (u0 + r, v1 - r, 90), (u0 + r, v0 + r, 180)):
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n)
            pts.append((cu + r * math.cos(a), cv + r * math.sin(a)))
    return pts

def eye_outlines():
    left = catmull_closed(EYE, 6)
    right = [(-u, v) for (u, v) in reversed(left)]
    return left, right

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=GLB)
    rock = next(o for o in bpy.data.objects if o.type == "MESH")
    for o in list(bpy.data.objects):
        if o is not rock:
            bpy.data.objects.remove(o)
    rock.data.transform(rock.matrix_world)
    rock.matrix_world = Matrix.Identity(4)
    co, _ = arrays(rock)
    lo, hi = co.min(0), co.max(0)
    s = 2.0 / (hi[2] - lo[2])
    zc = (hi[2] + lo[2]) / 2
    rock.data.transform(Matrix.Scale(s, 4) @ Matrix.Translation((0, 0, -zc)))
    rock.name = rock.data.name = "Rock"
    rock.data.materials.clear()
    log("scaled x%.3f, dims" % s, [round(d, 3) for d in rock.dimensions])

    apply_mod(rock, "REMESH", mode="VOXEL", voxel_size=VOXEL, adaptivity=0.0)
    log("rock remesh", tris(rock))

    base = copy(rock, "Base")
    apply_mod(base, "REMESH", mode="VOXEL", voxel_size=BASE_VOXEL, adaptivity=0.0)
    apply_mod(base, "SMOOTH", factor=1.0, iterations=12)
    bvh = BVHTree.FromObject(base, bpy.context.evaluated_depsgraph_get())
    log("base", tris(base))

    co, nr = arrays(rock)
    near = np.empty_like(co)
    bn = np.empty_like(co)
    for i, p in enumerate(co):
        loc, n, _, _ = bvh.find_nearest(Vector(p))
        near[i] = loc
        bn[i] = n
    d = ((co - near) * bn).sum(1)          # + above the average surface, - in seams and sockets
    log("depth percentiles (1,5,25,50,75,95,99):", np.percentile(d, [1, 5, 25, 50, 75, 95, 99]).round(3))
    # on the face only the real seams become strips, so the features keep their shape
    wf = smoothstep(0.25, 0.5, -co[:, 1]) * smoothstep(-1.0, -0.85, -np.abs(co[:, 0])) \
        * smoothstep(-1.0, -0.9, co[:, 2]) * smoothstep(-0.8, -0.7, -co[:, 2])
    t0 = STRIP_T0 + FACE_EXTRA * wf
    t1 = STRIP_T1 + FACE_EXTRA * wf
    m = np.clip((-d - t0) / (t1 - t0), 0.0, 1.0)
    m = m * m * (3 - 2 * m)
    log("strip area fraction: %.3f (face %.3f)" % ((m > 0.5).mean(), (m[wf > 0.5] > 0.5).mean()))
    co2 = co - bn * (m * STRIP_DEPTH)[:, None]
    rock.data.vertices.foreach_set("co", co2.ravel())
    rock.data.update()
    log("rock nonmanifold", nonmanifold(rock))

    eyeL, eyeR = eye_outlines()
    # the inner surface Meshy put behind the teeth: removed from behind the fang/tooth fronts backwards
    mouth = rounded_rect(-0.46, 0.46, -0.50, -0.355, 0.04)
    cut(rock, [loft_cutter("EyeL", eyeL, EYE_RINGS), loft_cutter("EyeR", eyeR, EYE_RINGS),
               loft_cutter("MouthInside", mouth, MOUTH_INSIDE)])
    log("eyes + mouth cut, rock nonmanifold", nonmanifold(rock))

    core = copy(base, "Core")
    cco, cnr = arrays(core)
    core.data.vertices.foreach_set("co", (cco - cnr * CORE_DEPTH).ravel())
    core.data.update()
    apply_mod(core, "SMOOTH", factor=0.5, iterations=4)
    apply_mod(core, "SUBSURF", levels=1)
    cut(core, [loft_cutter("PocketL", eyeL, EYE_POCKET), loft_cutter("PocketR", eyeR, EYE_POCKET)])
    bpy.data.objects.remove(base)

    for ob, target, angle in ((rock, ROCK_TRIS, 30), (core, CORE_TRIS, 50)):
        apply_mod(ob, "DECIMATE", ratio=min(1.0, target / tris(ob)))
        clean(ob)
        with bpy.context.temp_override(object=ob, active_object=ob, selected_objects=[ob], selected_editable_objects=[ob]):
            bpy.ops.object.shade_smooth_by_angle(angle=math.radians(angle))
        log(ob.name, tris(ob), "nonmanifold", nonmanifold(ob))
    for ob, mat in ((rock, material("Rock", (0.18, 0.17, 0.16, 1))),
                    (core, material("Comet_Core", (1.0, 0.35, 0.05, 1), (1.0, 0.35, 0.05, 1)))):
        ob.data.materials.clear()
        ob.data.materials.append(mat)
    bpy.context.scene["meteor_scale"] = 1.0
    bpy.ops.wm.save_as_mainfile(filepath=OUT)
    log("saved")

main()
