# Procedural build of the Meteor Gods base comet (headless Blender).
#   Rock : chiseled rock plates (Voronoi cells) separated by crack strips + the sculpted face
#          (Luffy-style curled brows, deep eye holes, mouth with 2 fangs and 2 lower teeth).
#   Core : inner layer under the plates, visible through the cracks, the eyes and the mouth.
# Units: ball half-height 1 while building (reference: 283 px = 1); normalized to diameter 1 at export.
# Front view = looking along +Y, face points to -Y. Front-view coords (u, v) = (x, z).
# usage (Blender 5.2):
#   blender -b --factory-startup --python build_meteor.py                       -> meteor_build.blend
#   blender -b --factory-startup meteor_build.blend --python export_meteor.py   -> ../meteor_base.blend/.glb
#   blender -b --factory-startup meteor_build.blend --python render_compare.py -- <tag>   (vs the reference)
import bpy, bmesh, math, os, sys, time
import numpy as np
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ART = r"C:\Users\mirko\Desktop\Meteors-God\art\reference"
OUT_BLEND = os.path.join(HERE, "meteor_build.blend")
SX = 1.14             # the ball is wider than tall in the reference
VOXEL = 0.009         # union of plates + face features (keeps the crack strips open)
VOXEL_FINAL = 0.0065
ROCK_TRIS = 15000
CORE_TRIS = 3000
SEED = 11
GAP = (0.032, 0.06)   # crack strip width range
R_IN = 0.76           # plate bottoms (hidden inside the core)
CORE_R = 0.885        # inner layer radius: strips sit 0.1-0.2 below the plate tops

T0 = time.time()
def log(*a):
    print("[build %6.1fs]" % (time.time() - T0), *a, flush=True)

def norm(v):
    return v / np.linalg.norm(v)

def surf_y(u, v, r=1.0):
    return -r * math.sqrt(max(1.0 - (u / (SX * r)) ** 2 - (v / r) ** 2, 0.0))

def front_point(u, v, r=1.0, y=None):
    return np.array([u, surf_y(u, v, r) if y is None else y, v], float)

def face_normal(p, k=0.55):
    """Ellipsoid normal blended toward the viewer (-Y): face features look forward like a mask."""
    n = norm(np.array([p[0] / SX ** 2, p[1], p[2]]))
    return norm(n * (1 - k) + np.array([0.0, -1.0, 0.0]) * k)

def new_obj(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob

def apply_mod(ob, mod):
    with bpy.context.temp_override(object=ob, active_object=ob, selected_objects=[ob]):
        bpy.ops.object.modifier_apply(modifier=mod.name)

def modify(ob, kind, **props):
    m = ob.modifiers.new(kind.lower(), kind)
    for k, v in props.items():
        setattr(m, k, v)
    apply_mod(ob, m)

def tri_count(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)

def nonmanifold(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    n = sum(1 for e in bm.edges if not e.is_manifold)
    bm.free()
    return n

def join(objs, name):
    target = objs[0]
    with bpy.context.temp_override(active_object=target, selected_editable_objects=objs):
        bpy.ops.object.join()
    target.name = name
    target.data.name = name
    return target

def tangent_frame(n, up=np.array([0.0, 0.0, 1.0])):
    up = up - n * np.dot(up, n)
    if np.linalg.norm(up) < 1e-4:
        up = np.array([1.0, 0.0, 0.0]) - n * n[0]
    up = norm(up)
    return np.cross(up, n), up

# ---------------------------------------------------------------- rock plates
# Face plates follow the stone layout of the reference face (front coords u, v; mirrored when u != 0).
# (u, v, top height, chisel tilt range)
FACE_SEEDS = [
    (0.00, 0.30, 1.03), (0.00, 0.64, 1.04), (0.00, -0.30, 1.04), (0.00, -0.72, 1.04), (0.00, -0.93, 1.01),
    (0.07, -0.12, 1.05),                       # nose (vertical crack in the middle)
    (0.30, 0.50, 1.02), (0.24, 0.10, 1.00),    # forehead, under the spiral
    (0.53, -0.04, 1.01),                       # eye (mostly cut away by the hole)
    (0.27, -0.30, 1.03), (0.55, -0.31, 1.03),  # upper lip / under the eye
    (0.86, -0.30, 1.03), (0.97, 0.08, 1.01),   # cheek, temple
    (0.66, -0.53, 1.02), (0.38, -0.70, 1.03), (0.42, -0.90, 1.00),  # mouth corner, jaw, chin
    (0.62, 0.40, 1.00), (0.88, 0.56, 1.00),    # under the brow band
]

def in_face_mask(d):  # d on the unit sphere (x not yet stretched)
    return d[1] < -0.25 and abs(d[0] * SX) < 1.0 and -1.0 < d[2] < 0.78

def seeds():
    """Unit-sphere seeds (x not yet stretched by SX): face layout + jittered Fibonacci body."""
    rng = np.random.default_rng(SEED)
    out = []
    for (u, v, h) in FACE_SEEDS:
        for uu in ((u, -u) if u != 0 else (u,)):
            p = front_point(uu, v)
            out.append((norm(np.array([p[0] / SX, p[1], p[2]])), h, True))
    face_dirs = [s for s, _, _ in out]
    n = 96
    ga = math.pi * (3.0 - math.sqrt(5.0))
    for i in range(n):
        z = 1.0 - 2.0 * (i + 0.5) / n
        r = math.sqrt(1.0 - z * z)
        d = norm(np.array([r * math.cos(i * ga), r * math.sin(i * ga), z]) + rng.uniform(-0.13, 0.13, 3))
        if in_face_mask(d) or max(np.dot(d, f) for f in face_dirs) > math.cos(0.2):
            continue
        out.append((d, rng.uniform(0.96, 1.12), False))
    # a few extra seeds break the regular pattern into big and small plates
    tries = 0
    while tries < 400 and sum(1 for o in out if not o[2]) < 100:
        tries += 1
        d = norm(rng.normal(size=3))
        if in_face_mask(d) or max(np.dot(d, o[0]) for o in out) > math.cos(0.17):
            continue
        out.append((d, rng.uniform(0.96, 1.12), False))
    return out

def pair_gap(i, j):
    a, b = min(i, j), max(i, j)
    f = math.sin(a * 12.9898 + b * 78.233) * 43758.5453
    return GAP[0] + (GAP[1] - GAP[0]) * (f - math.floor(f))

def clip(bm, co, no):
    """Keep the half-space (x - co).no <= 0 and cap the cut (the plate stays a closed convex solid)."""
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-7,
                           plane_co=Vector(co), plane_no=Vector(no), clear_outer=True)
    bmesh.ops.holes_fill(bm, edges=bm.edges[:], sides=0)

def build_plates():
    rng = np.random.default_rng(SEED + 1)
    S = seeds()
    bm_all = bmesh.new()
    count = 0
    for i, (s, h, is_face) in enumerate(S):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=3.0)
        for j, (t, _, _) in enumerate(S):  # Voronoi cell shrunk by half the crack width
            if j != i and np.dot(s, t) > 0.5:
                n = norm(s - t)
                g = pair_gap(i, j) * (0.55 if is_face and S[j][2] else 1.0)  # thinner cracks on the face
                clip(bm, n * g * 0.5, -n)
        clip(bm, s * R_IN, -s)             # bottom, buried in the core
        if is_face:                        # flat mask-like fronts
            m = norm(s * 0.65 + np.array([0.0, -1.0, 0.0]) * 0.35)
            tilt, rho, k = (0.30, 0.42), (0.08, 0.13), 5
        else:                              # protruding, chiseled rock tops
            m = norm(s + rng.uniform(-0.2, 0.2, 3))
            tilt, rho, k = (0.35, 0.75), (0.03, 0.12), 7
        clip(bm, m * h, m)
        t1, t2 = tangent_frame(m, rng.normal(size=3))
        ph0 = rng.uniform(0, 2 * math.pi)
        for q in range(k):                 # chisel facets around the top
            ph = ph0 + 2 * math.pi * q / k + rng.uniform(-0.3, 0.3)
            a = rng.uniform(*tilt)
            radial = math.cos(ph) * t1 + math.sin(ph) * t2
            nq = math.cos(a) * m + math.sin(a) * radial
            Q = m * h + radial * rng.uniform(*rho)
            clip(bm, Q, nq)
        if len(bm.verts) < 4:
            bm.free()
            continue
        bmesh.ops.scale(bm, vec=(SX, 1, 1), verts=bm.verts)
        me = bpy.data.meshes.new("plate")
        bm.to_mesh(me)
        bm.free()
        bm_all.from_mesh(me)
        bpy.data.meshes.remove(me)
        count += 1
    log("plates", count)
    return new_obj("Plates", bm_all)

# ---------------------------------------------------------------- sweeps (brows, spiral, eye rims)
def catmull(ctrl, per_seg, closed=False):
    P = list(ctrl)
    P = [P[-1]] + P + [P[0], P[1]] if closed else [P[0]] + P + [P[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(per_seg):
            t = k / per_seg
            out.append(0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                              + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t))
    if not closed:
        out.append(P[-2])
    return out

def sweep(bm, centers, widths, hf, hb, profile, normal_fn):
    """Closed tube along `centers`; profile (t, h): t in [-1,1] across, h in [-1,1] (-1=back, 1=front)."""
    N = len(centers)
    rings = []
    for i in range(N):
        p = centers[i]
        T = norm(centers[min(i + 1, N - 1)] - centers[max(i - 1, 0)])
        nr = normal_fn(p)
        B = norm(np.cross(T, nr))
        nr = np.cross(B, T)
        ring = []
        for (t, h) in profile:
            hh = h * hf[i] if h > 0 else h * hb[i]
            ring.append(bm.verts.new(p + B * t * widths[i] * 0.5 + nr * hh))
        rings.append(ring)
    M = len(profile)
    for i in range(N - 1):
        for j in range(M):
            bm.faces.new((rings[i][j], rings[i][(j + 1) % M], rings[i + 1][(j + 1) % M], rings[i + 1][j]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])

def sweep_ctrl(bm, ctrl, profile, per_seg=10, k=0.55):
    """ctrl rows: u, v, y (None = on the surface), width, front h, back h"""
    rows = [np.array([*front_point(u, v, 1.0, y), w, f, b]) for (u, v, y, w, f, b) in ctrl]
    dense = catmull(rows, per_seg)
    sweep(bm, [d[:3] for d in dense], [d[3] for d in dense], [d[4] for d in dense], [d[5] for d in dense],
          profile, lambda p: face_normal(p, k))

# t=+1 is the upper edge of the left brow: big lit bevel on top, small chamfer below
BAND_PROFILE = [(-1, -1), (1, -1), (1, 0.2), (0.62, 1.0), (-0.75, 1.0), (-1, 0.55)]
RIM_PROFILE = [(-1, -1), (1, -1), (1, 0.4), (0.5, 1), (-0.5, 1), (-1, 0.4)]

# Left brow (viewer's left, -X): from the inner spiral, along the face, around the side, up into the hook
BROW = [
    (-0.24, 0.10, None, 0.38, 0.20, 0.18),
    (-0.40, 0.15, None, 0.40, 0.21, 0.18),
    (-0.58, 0.25, None, 0.42, 0.21, 0.18),
    (-0.76, 0.37, None, 0.43, 0.21, 0.18),
    (-0.92, 0.46, None, 0.42, 0.20, 0.17),
    (-0.97, 0.55, -0.34, 0.32, 0.17, 0.15),
    (-1.00, 0.65, -0.34, 0.24, 0.14, 0.13),
    (-0.98, 0.75, -0.34, 0.14, 0.10, 0.09),
    (-0.93, 0.83, -0.34, 0.03, 0.03, 0.03),
]
BROW_K = 0.4  # brow frame: mostly follows the ball's curvature so it wraps around the side
SPIRAL = dict(u=-0.24, v=0.10, R=0.20, hf=0.20, hb=0.18,
              th0=100.0, th1=520.0, rho0=0.19, rho1=0.05, w0=0.08, w1=0.035)
# raised orbit rim around the outer/lower side of the left eye
EYE_RIM = [
    (-0.79, 0.17, None, 0.15, 0.040, 0.12),
    (-0.87, 0.02, None, 0.18, 0.045, 0.12),
    (-0.81, -0.18, None, 0.18, 0.045, 0.12),
    (-0.62, -0.30, None, 0.17, 0.045, 0.12),
    (-0.44, -0.30, None, 0.16, 0.045, 0.12),
    (-0.31, -0.24, None, 0.14, 0.040, 0.12),
    (-0.21, -0.16, None, 0.10, 0.030, 0.12),
]

def spiral_frame():
    s = SPIRAL
    c = front_point(s["u"], s["v"])
    n = face_normal(c, BROW_K)
    right, up = tangent_frame(n)
    return s, c, n, right, up

def spiral_disk(bm):
    s, c, n, right, up = spiral_frame()
    segs = 64
    prof = [(s["R"], -s["hb"]), (s["R"], s["hf"] * 0.45), (s["R"] * 0.86, s["hf"])]
    rings = []
    for (rad, h) in prof:
        rings.append([bm.verts.new(c + n * h + rad * (math.cos(a) * right + math.sin(a) * up))
                      for a in (2 * math.pi * k / segs for k in range(segs))])
    for i in range(len(rings) - 1):
        for k in range(segs):
            bm.faces.new((rings[i][k], rings[i][(k + 1) % segs], rings[i + 1][(k + 1) % segs], rings[i + 1][k]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])

def spiral_groove(bm):
    """Counter-clockwise inward V-groove carved in the disk face (mirrored for the right brow)."""
    s, c, n, right, up = spiral_frame()
    centers, widths, depths = [], [], []
    steps = 100
    for k in range(steps + 1):
        f = k / steps
        th = math.radians(s["th0"] + (s["th1"] - s["th0"]) * f)
        rho = s["rho0"] + (s["rho1"] - s["rho0"]) * f
        centers.append(c + n * s["hf"] + rho * (math.cos(th) * right + math.sin(th) * up))
        w = s["w0"] + (s["w1"] - s["w0"]) * f
        widths.append(w)
        depths.append(w * 0.8)
    sweep(bm, centers, widths, [0.04] * len(centers), depths,
          [(-1, 0), (0, -1), (1, 0), (0, 1)], lambda p: n)

def mirror_obj(src, name, coll=None):
    bm = bmesh.new()
    bm.from_mesh(src.data)
    bmesh.ops.transform(bm, matrix=Matrix.Diagonal((-1, 1, 1, 1)), verts=bm.verts)
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    ob = new_obj(name, bm)
    if coll is not None:
        bpy.context.scene.collection.objects.unlink(ob)
        coll.objects.link(ob)
    return ob

def fix_normals(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()

# ---------------------------------------------------------------- cutters and teeth
EYE = [(-0.75, 0.13), (-0.81, 0.02), (-0.75, -0.13), (-0.61, -0.22), (-0.46, -0.225), (-0.36, -0.19),
       (-0.28, -0.13), (-0.40, -0.02), (-0.55, 0.06), (-0.68, 0.12)]

def eye_outline(mirror=False):
    pts = [tuple(p) for p in catmull([np.array(p) for p in EYE], 6, closed=True)]
    return [(-u, v) for (u, v) in reversed(pts)] if mirror else pts

MOUTH_HALF = [(0.0, -0.665), (-0.20, -0.665), (-0.275, -0.71), (-0.375, -0.565), (-0.46, -0.555),
              (-0.52, -0.525), (-0.548, -0.46), (-0.545, -0.40), (-0.515, -0.355), (-0.46, -0.345),
              (0.0, -0.345)]

def mouth_outline():
    return MOUTH_HALF + [(-u, v) for (u, v) in reversed(MOUTH_HALF)][1:-1]

EYE_RINGS = [(-1.6, "local", 1.22), (-0.92, "local", 1.0), (-0.62, "local", 0.82), (-0.12, "origin", 0.45)]
MOUTH_RINGS = [(-1.6, "local", 1.06), (-0.78, "local", 1.0), (-0.55, "local", 0.9), (-0.12, "origin", 0.45)]
# pockets in the core behind the holes: a bit narrower than the rock tunnel so its walls stay hidden
EYE_POCKET = [(-1.6, "local", 0.92), (-0.80, "local", 0.92), (-0.55, "local", 0.7)]
MOUTH_POCKET = [(-1.6, "local", 0.94), (-0.70, "local", 0.94), (-0.50, "local", 0.75)]

def loft_cutter(bm, outline, rings):
    """rings: (y, mode, scale). mode 'local' scales about the outline centroid, 'origin' about (0,0)."""
    cu = sum(p[0] for p in outline) / len(outline)
    cv = sum(p[1] for p in outline) / len(outline)
    vrings = []
    for (y, mode, sc) in rings:
        if mode == "local":
            vrings.append([bm.verts.new((cu + (u - cu) * sc, y, cv + (v - cv) * sc)) for (u, v) in outline])
        else:
            vrings.append([bm.verts.new((u * sc, y, v * sc)) for (u, v) in outline])
    M = len(outline)
    for i in range(len(vrings) - 1):
        for j in range(M):
            bm.faces.new((vrings[i][j], vrings[i][(j + 1) % M], vrings[i + 1][(j + 1) % M], vrings[i + 1][j]))
    f0 = bm.faces.new(vrings[0][::-1])
    f1 = bm.faces.new(vrings[-1])
    bmesh.ops.triangulate(bm, faces=[f0, f1])

def tooth(bm, outline, r_front, depth, bevel=0.018):
    cu = sum(p[0] for p in outline) / len(outline)
    cv = sum(p[1] for p in outline) / len(outline)
    yf = surf_y(cu, cv, r_front)
    tmp = bmesh.new()
    front = [tmp.verts.new((u, yf, v)) for (u, v) in outline]
    back = [tmp.verts.new((u, yf + depth, v)) for (u, v) in outline]
    M = len(outline)
    for j in range(M):
        tmp.faces.new((front[j], front[(j + 1) % M], back[(j + 1) % M], back[j]))
    tmp.faces.new(front[::-1])
    tmp.faces.new(back)
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    bmesh.ops.bevel(tmp, geom=list(tmp.edges), offset=bevel, segments=1, affect="EDGES", clamp_overlap=True)
    me = bpy.data.meshes.new("tmp")
    tmp.to_mesh(me)
    tmp.free()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)

FANG = [(-0.37, -0.28), (-0.19, -0.28), (-0.28, -0.445)]
LOW_TOOTH = [(-0.18, -0.48), (-0.035, -0.48), (-0.005, -0.535), (-0.005, -0.76), (-0.26, -0.76), (-0.255, -0.70)]

def cutter_collection(name, items):
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    for (oname, fill) in items:
        b = bmesh.new()
        fill(b)
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        ob = new_obj(oname, b)
        bpy.context.scene.collection.objects.unlink(ob)
        coll.objects.link(ob)
    return coll

# ---------------------------------------------------------------- finishing
def smart_uv(ob):
    for o in bpy.context.scene.objects:
        o.select_set(o is ob)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.003)
    bpy.ops.object.mode_set(mode="OBJECT")

def smooth_by_angle(ob, deg):
    with bpy.context.temp_override(object=ob, active_object=ob, selected_objects=[ob],
                                   selected_editable_objects=[ob]):
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(deg))

def finish(ob, target, angle):
    modify(ob, "DECIMATE", ratio=min(1.0, target / tri_count(ob)))
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.dissolve_degenerate(bm, dist=1e-6, edges=bm.edges[:])
    bmesh.ops.triangulate(bm, faces=bm.faces)
    for _ in range(6):  # rare decimation leftovers: close small holes, drop pinched flaps
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
    smooth_by_angle(ob, angle)

def placeholder_material(name, color, emission=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = 0.85
    if emission:
        bsdf.inputs["Emission Color"].default_value = emission
        bsdf.inputs["Emission Strength"].default_value = 3.0
    return mat

def add_reference_empties():
    sys.path.insert(0, HERE)
    from imgutil import load, save, crop
    ref = load(os.path.join(ART, "meteor_base.png"))
    paths = {}
    for key, box in (("front", (40, 20, 780, 600)), ("threequarter", (840, 20, 1500, 600))):
        p = os.path.join(HERE, "ref_%s.png" % key)
        save(crop(ref, *box), p)
        paths[key] = p
    coll = bpy.data.collections.new("Reference")
    bpy.context.scene.collection.children.link(coll)
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
        coll.objects.link(e)
    # sized for the normalized model (diameter 1): 283 px = 1 build unit = SCALE
    s = SCALE
    empty("Ref_Front", paths["front"], 740 / 283 * s, (-25 / 283 * s, 2.0, 3 / 283 * s), (math.radians(90), 0, 0))
    az = math.radians(45)
    empty("Ref_ThreeQuarter", paths["threequarter"], 660 / 290 * s,
          (-2.0 * math.sin(az), 2.0 * math.cos(az), 0), (math.radians(90), 0, az))

SCALE = 1.0

def main():
    global SCALE
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # ---- Rock: plates + face features, fused by a voxel remesh (crack strips stay open)
    plates = build_plates()
    bm = bmesh.new()
    sweep_ctrl(bm, BROW, BAND_PROFILE, k=BROW_K)
    spiral_disk(bm)
    sweep_ctrl(bm, EYE_RIM, RIM_PROFILE, k=0.3)
    featL = new_obj("FeatL", bm)
    fix_normals(featL)
    featR = mirror_obj(featL, "FeatR")
    rock = join([plates, featL, featR], "Rock")
    modify(rock, "REMESH", mode="VOXEL", voxel_size=VOXEL, adaptivity=0.0)
    log("rock voxel tris", tri_count(rock), "nonmanifold", nonmanifold(rock))

    eyeL, eyeR, mouth = eye_outline(), eye_outline(True), mouth_outline()
    cuts = cutter_collection("Cutters", [
        ("EyeL", lambda b: loft_cutter(b, eyeL, EYE_RINGS)),
        ("EyeR", lambda b: loft_cutter(b, eyeR, EYE_RINGS)),
        ("Mouth", lambda b: loft_cutter(b, mouth, MOUTH_RINGS)),
        ("GrooveL", spiral_groove),
    ])
    mirror_obj(cuts.objects["GrooveL"], "GrooveR", cuts)
    modify(rock, "BOOLEAN", operation="DIFFERENCE", operand_type="COLLECTION", collection=cuts, solver="MANIFOLD")
    log("rock after cut", tri_count(rock), "nonmanifold", nonmanifold(rock))

    tb = bmesh.new()
    for outline, rf in ((FANG, 1.01), (LOW_TOOTH, 1.02)):
        tooth(tb, outline, rf, 0.28)
        tooth(tb, [(-u, v) for (u, v) in reversed(outline)], rf, 0.28)
    rock = join([rock, new_obj("Teeth", tb)], "Rock")
    modify(rock, "REMESH", mode="VOXEL", voxel_size=VOXEL_FINAL, adaptivity=0.0)
    log("rock final remesh", tri_count(rock))
    finish(rock, ROCK_TRIS, 30)
    log("rock tris", tri_count(rock), "nonmanifold", nonmanifold(rock))

    # ---- Core: inner layer under the plates, with pockets behind the eyes and the mouth
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=5, radius=CORE_R)
    rng = np.random.default_rng(SEED + 2)
    waves = [(norm(rng.normal(size=3)), rng.uniform(3, 7), rng.uniform(0, 6.28)) for _ in range(6)]
    for vtx in bm.verts:
        p = np.array(vtx.co)
        d = sum(math.sin(np.dot(p, w) * f + ph) for (w, f, ph) in waves) / len(waves)
        vtx.co = Vector(p * (1.0 + 0.018 * d))
    bmesh.ops.scale(bm, vec=(SX, 1, 1), verts=bm.verts)
    core = new_obj("Core", bm)
    pockets = cutter_collection("CorePockets", [
        ("PocketEyeL", lambda b: loft_cutter(b, eyeL, EYE_POCKET)),
        ("PocketEyeR", lambda b: loft_cutter(b, eyeR, EYE_POCKET)),
        ("PocketMouth", lambda b: loft_cutter(b, mouth, MOUTH_POCKET)),
    ])
    modify(core, "BOOLEAN", operation="DIFFERENCE", operand_type="COLLECTION", collection=pockets, solver="MANIFOLD")
    finish(core, CORE_TRIS, 40)
    log("core tris", tri_count(core), "nonmanifold", nonmanifold(core))

    for ob in list(bpy.context.scene.objects):
        if ob.type == "MESH" and ob not in (rock, core):
            bpy.data.objects.remove(ob)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)

    # ---- normalize: diameter 1 (largest dimension), ball center at the origin, face toward -Y
    dims = [max(v.co[a] for v in rock.data.vertices) - min(v.co[a] for v in rock.data.vertices) for a in range(3)]
    SCALE = 1.0 / max(dims)
    for ob in (rock, core):
        ob.data.transform(Matrix.Scale(SCALE, 4))
    log("dims before normalize", ["%.3f" % d for d in dims], "scale", "%.4f" % SCALE)

    # one material slot per object (remesh/boolean leave an empty slot behind)
    for ob, mat in ((rock, placeholder_material("Rock", (0.18, 0.17, 0.16, 1))),
                    (core, placeholder_material("Comet_Core", (1.0, 0.35, 0.05, 1), (1.0, 0.35, 0.05, 1)))):
        ob.data.materials.clear()
        ob.data.materials.append(mat)
        for p in ob.data.polygons:
            p.material_index = 0
    smart_uv(rock)
    smart_uv(core)
    add_reference_empties()
    bpy.context.scene["meteor_scale"] = SCALE
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    log("saved", OUT_BLEND, "total tris", tri_count(rock) + tri_count(core))

main()
