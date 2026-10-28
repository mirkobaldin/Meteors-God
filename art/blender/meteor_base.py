"""Meteor Gods - base meteor mesh, modeled on art/reference/meteor_base.png.

A ball made of big chipped boulders packed together, with a sculpted stone face on the front:
two horn-shaped brows that curl into a spiral above the nose, deep angry eye sockets and a wide
mouth with fangs. Under the stones there is a glowing core (second layer) that shows through
the gaps between the boulders, the eyes and the mouth.

Coordinates: Blender units, diameter ~1, the face looks towards -Y (front view), Z up.
Face-plane coordinates (fx, fz): fx to the right of the viewer, fz up.
"""

import math
import random

import bpy  # noqa: F401  (bmesh/mathutils need bpy loaded first when used as a module)
import bmesh
from mathutils import Matrix, Vector, noise

R = 0.5  # outer radius of the ball
FRONT = Vector((0, -1, 0))


# ------------------------------------------------------------------------------------------------
# Small geometry helpers
# ------------------------------------------------------------------------------------------------

def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def on_face(fx, fz, lift=0.0, radius=R):
    """3D point on the front of the ball for face-plane coordinates, pushed out by `lift`
    (points outside the silhouette, like the horn tips, stay just in front of the middle)."""
    y = -math.sqrt(max(radius * radius - fx * fx - fz * fz, 0.12 ** 2))
    p = Vector((fx, y, fz))
    return p.normalized() * (p.length + lift)


def frame_for(direction):
    d = direction.normalized()
    up = Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))
    x = d.cross(up).normalized()
    y = d.cross(x).normalized()
    return x, y


def boulder_bm(bm, center, normal, size, rng, flat=0.75, planes=16):
    """Chipped boulder: the intersection of random half-spaces (crisp flat facets), slightly
    rounded, flattened along `normal`, with chip noise. Returns the new verts."""
    res = bmesh.ops.create_icosphere(bm, subdivisions=4, radius=1.0)
    verts = res["verts"]
    cuts = []
    for _ in range(planes):
        nrm = Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))).normalized()
        cuts.append((nrm, rng.uniform(0.5, 0.86)))
    off = Vector((rng.random() * 90, rng.random() * 90, rng.random() * 90))
    x, y = frame_for(normal)
    m = Matrix((x, y, normal.normalized())).transposed()  # local (x, y, n) -> world
    for v in verts:
        n = v.co.normalized()
        r = 1.0
        for nrm, d in cuts:
            dd = n.dot(nrm)
            if dd > 0.15:
                r = min(r, d / dd)
        r = r * 0.95 + 0.05 * 0.8  # keep the cut edges crisp
        # Chiselled micro-facets (the reference's hand-cut look) and small chips.
        q = n * 9 + off
        dist, pts = noise.voronoi(q, distance_metric="DISTANCE", exponent=2.5)
        cp = pts[0]
        tilt = Vector((math.sin(cp.x * 12.9), math.sin(cp.y * 78.2), math.sin(cp.z * 37.7)))
        r += (q - cp).dot(tilt) * 0.026 - (1 - smoothstep(0, 0.05, dist[1] - dist[0])) * 0.01 \
            + noise.noise(n * 15 + off) * 0.005
        local = n * r
        local.z *= flat
        v.co = center + (m @ local) * size
    return verts


def sweep_bm(bm, points, radii, sides=10, cap_end=True):
    """Tube through `points` with a radius per point; the last ring collapses to a tip if its
    radius is 0. Used for the horn-brows and the spirals."""
    rings = []
    prev_x = None
    for i, p in enumerate(points):
        a = points[max(i - 1, 0)]
        b = points[min(i + 1, len(points) - 1)]
        t = (b - a).normalized()
        # Parallel transport of the ring frame (no twisting).
        if prev_x is None:
            x, _ = frame_for(t)
        else:
            x = (prev_x - t * prev_x.dot(t)).normalized()
        y = t.cross(x).normalized()
        prev_x = x
        r = radii[i]
        if r <= 1e-5:
            rings.append([bm.verts.new(p)])
        else:
            rings.append([bm.verts.new(p + (x * math.cos(k / sides * math.tau) + y * math.sin(k / sides * math.tau)) * r)
                          for k in range(sides)])
    for ra, rb in zip(rings, rings[1:]):
        if len(rb) == 1:
            for k in range(sides):
                bm.faces.new((ra[k], ra[(k + 1) % sides], rb[0]))
        elif len(ra) == 1:
            for k in range(sides):
                bm.faces.new((ra[0], rb[(k + 1) % sides], rb[k]))
        else:
            for k in range(sides):
                bm.faces.new((ra[k], ra[(k + 1) % sides], rb[(k + 1) % sides], rb[k]))
    if len(rings[0]) > 1:
        bm.faces.new(list(reversed(rings[0])))
    if cap_end and len(rings[-1]) > 1:
        bm.faces.new(rings[-1])


# ------------------------------------------------------------------------------------------------
# The face (reference: horn-brows with spirals, deep sockets, fanged mouth)
# ------------------------------------------------------------------------------------------------

# Measured on the reference (ball radius = 0.5): eyes centered at (±0.23, -0.07), mouth from
# z -0.23 to -0.37, spirals at (±0.165, 0.065), horn tips at (±0.5, 0.42).
EYE = [(0.11, -0.055), (0.165, -0.01), (0.26, 0.015), (0.33, 0.0), (0.35, -0.06), (0.325, -0.12),
       (0.255, -0.148), (0.175, -0.135), (0.125, -0.1)]
MOUTH = [(-0.21, -0.23), (-0.14, -0.235), (-0.12, -0.285), (-0.1, -0.24), (0.1, -0.24), (0.12, -0.285),
         (0.14, -0.235), (0.21, -0.23), (0.22, -0.28), (0.19, -0.34), (0.08, -0.37), (0.05, -0.31),
         (0.0, -0.34), (-0.05, -0.31), (-0.08, -0.37), (-0.19, -0.34), (-0.22, -0.28)]


def brow_path(side):
    """Hooked horn tip (outside the ball) -> thick band over the eye -> spiral above the nose."""
    pts = [(0.43, 0.395), (0.448, 0.36), (0.458, 0.325), (0.458, 0.29), (0.443, 0.258), (0.41, 0.232),
           (0.36, 0.205), (0.3, 0.172), (0.25, 0.142), (0.215, 0.12)]
    cx, cz = 0.165, 0.065
    start = math.atan2(0.12 - cz, 0.215 - cx)
    steps = 26
    for i in range(1, steps + 1):
        t = i / steps
        ang = start + t * 1.15 * math.tau  # counter-clockwise: curls down on the inner side
        r = 0.075 * (1 - t) + 0.016
        pts.append((cx + math.cos(ang) * r, cz + math.sin(ang) * r))
    if side < 0:
        pts = [(-fx, fz) for fx, fz in pts]
    return pts


def band_bm(bm, points, outs, halfs, sides=16):
    """Sweep with a rounded-square cross-section: `outs` = how far it stands out of the surface,
    `halfs` = half its height along the surface."""
    rings = []
    for i, p in enumerate(points):
        a = points[max(i - 1, 0)]
        b = points[min(i + 1, len(points) - 1)]
        t = (b - a).normalized()
        nrm = p.normalized()
        if abs(p.y) < 0.3:  # outside the ball's outline (horn tips): stand out towards the viewer
            nrm = (nrm + FRONT * 1.5).normalized()
        nrm = (nrm - t * nrm.dot(t)).normalized()
        side = t.cross(nrm).normalized()
        if outs[i] <= 1e-5:
            rings.append([bm.verts.new(p)])
            continue
        ring = []
        for k in range(sides):
            ang = k / sides * math.tau
            c, s_ = math.cos(ang), math.sin(ang)
            c = math.copysign(abs(c) ** 0.55, c)
            s_ = math.copysign(abs(s_) ** 0.55, s_)
            # The bottom of the section sits inside the surface (no gap under the band).
            ring.append(bm.verts.new(p + nrm * (c * outs[i] * 0.5 + outs[i] * 0.2) + side * s_ * halfs[i]))
        rings.append(ring)
    for ra, rb in zip(rings, rings[1:]):
        if len(ra) == 1:
            for k in range(sides):
                bm.faces.new((ra[0], rb[(k + 1) % sides], rb[k]))
        elif len(rb) == 1:
            for k in range(sides):
                bm.faces.new((ra[k], ra[(k + 1) % sides], rb[0]))
        else:
            for k in range(sides):
                bm.faces.new((ra[k], ra[(k + 1) % sides], rb[(k + 1) % sides], rb[k]))
    if len(rings[-1]) > 1:
        bm.faces.new(rings[-1])
    if len(rings[0]) > 1:
        bm.faces.new(list(reversed(rings[0])))


def outline_rim(bm, outline, out, half, grow=0.012):
    """Raised stone rim around a face hole (closed loop), like the reference's sockets."""
    n = len(outline)
    cx = sum(p[0] for p in outline) / n
    cz = sum(p[1] for p in outline) / n
    pts = []
    for i in range(n + 1):
        fx, fz = outline[i % n]
        d = Vector((fx - cx, fz - cz))
        d = d.normalized() * (d.length + grow) if d.length > 1e-6 else d
        pts.append(on_face(cx + d.x, cz + d.y, 0.0))
    # Densify (smoother loop).
    dense = []
    for a, b in zip(pts, pts[1:]):
        for k in range(4):
            q = a.lerp(b, k / 4)
            dense.append(q.normalized() * pts[0].length if False else q)
    dense.append(dense[0])
    band_bm(bm, dense, [out] * len(dense), [half] * len(dense), sides=10)


def tooth_bm(bm, base_fx, base_fz, tip_fx, tip_fz, width, depth=0.07):
    """Triangular stone tooth in the mouth (front face + back face, pointed)."""
    b0 = on_face(base_fx - width / 2, base_fz, -0.01)
    b1 = on_face(base_fx + width / 2, base_fz, -0.01)
    tip = on_face(tip_fx, tip_fz, -0.015)
    inward = Vector((0, depth, 0))
    f = [bm.verts.new(v) for v in (b0, b1, tip)]
    k = [bm.verts.new(v + inward) for v in (b0, b1, tip)]
    bm.faces.new((f[0], f[1], f[2]))
    bm.faces.new((k[2], k[1], k[0]))
    for i in range(3):
        j = (i + 1) % 3
        bm.faces.new((f[j], f[i], k[i], k[j]))


def build_teeth():
    bm = bmesh.new()
    for sx in (-1, 1):
        tooth_bm(bm, sx * 0.15, -0.225, sx * 0.14, -0.315, 0.075)  # fangs hanging from the top corners
        tooth_bm(bm, sx * 0.045, -0.37, sx * 0.03, -0.285, 0.065)  # pointed teeth rising in the middle
    return bm


def build_brows(rng):
    bm = bmesh.new()
    for side in (-1, 1):
        path = brow_path(side)
        n = len(path)
        points, outs, halfs = [], [], []
        for i, (fx, fz) in enumerate(path):
            if i < 10:  # horn: blunt tip hooking inwards, growing into the band
                k = i / 9
                out = 0.012 + 0.1 * smoothstep(0, 1, k) ** 0.55
                half = 0.008 + 0.07 * smoothstep(0, 1, k) ** 0.55
                lift = 0.06 + 0.02 * (1 - k)
            else:
                k = (i - 10) / (n - 11)
                out = 0.11 * (1 - k) + 0.06 * k
                half = 0.075 * (1 - k) + 0.028 * k
                lift = 0.06 * (1 - k) + 0.045 * k
            points.append(on_face(fx, fz, lift))
            outs.append(out)
            halfs.append(half)
        band_bm(bm, points, outs, halfs)
    teeth = build_teeth()
    tmp = bpy.data.meshes.new("_teeth")
    teeth.to_mesh(tmp)
    teeth.free()
    bm.from_mesh(tmp)
    bpy.data.meshes.remove(tmp)
    # Chisel the brows (stone, not plastic).
    off = Vector((rng.random() * 50, 0, 0))
    for v in bm.verts:
        v.co += v.co.normalized() * (noise.noise(v.co * 35 + off) * 0.006 + noise.noise(v.co * 90 + off) * 0.002)
    return bm


FACE_E = (0.43, 0.37, -0.12)  # face ellipse in the face plane: half-width, half-height, center z


def in_face(fx, fz, scale=1.0):
    ax, az, cz = FACE_E
    return (fx / (ax * scale)) ** 2 + ((fz - cz) / (az * scale)) ** 2 < 1


def build_mask(rng):
    """The face: big flat chiselled stone slabs (forehead, cheeks, nose, chin) on the front. Its
    edge follows the grooves between the slabs, so it blends with the boulders around it."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=6, radius=0.5)
    off = Vector((rng.random() * 50, rng.random() * 50, rng.random() * 50))
    freq = 4.4

    def cell(n):
        dist, pts = noise.voronoi(n * freq + off, distance_metric="DISTANCE", exponent=2.5)
        return dist, pts[0]

    def keep_cell(cp):
        d = (cp - off).normalized()
        return d.dot(FRONT) > 0.35 and in_face(d.x * 0.5, d.z * 0.5)

    gone = [f for f in bm.faces if not keep_cell(cell(f.calc_center_median().normalized())[1])]
    bmesh.ops.delete(bm, geom=gone, context="FACES")
    for v in bm.verts:
        n = v.co.normalized()
        dist, cp = cell(n)
        h = (cp.length * 7.13) % 1
        e = dist[1] - dist[0]
        slab = smoothstep(0.0, 0.22, e) * 0.018  # each slab bulges a little, rounded edges
        groove = 1 - smoothstep(0, 0.05, e)
        fx, fz = n.x * 0.5, n.z * 0.5
        chin = 0.025 * math.exp(-((fx / 0.2) ** 2 + ((fz + 0.43) / 0.07) ** 2))
        nose = 0.03 * math.exp(-((fx / 0.06) ** 2 + ((fz + 0.1) / 0.09) ** 2))
        r = 0.505 + slab + chin + nose + (h - 0.5) * 0.014 - groove * 0.02 \
            + noise.noise(n * 18 + off) * 0.003 + noise.noise(n * 55 + off) * 0.001
        v.co = n * r
    bm.normal_update()
    for f in bm.faces:
        if f.normal.dot(f.calc_center_median()) < 0:
            f.normal_flip()
    bm.normal_update()
    return bm


def build_face_base():
    """Smooth stone shell behind the face stones: their gaps show stone, and only the carved eyes
    and mouth (cut through it) show the glowing core."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=5, radius=0.465)
    gone = [f for f in bm.faces if f.calc_center_median().normalized().dot(FRONT) < 0.3]
    bmesh.ops.delete(bm, geom=gone, context="FACES")
    for v in bm.verts:
        n = v.co.normalized()
        v.co = n * (0.465 + noise.noise(n * 8) * 0.008)
    bm.normal_update()
    for f in bm.faces:
        if f.normal.dot(f.calc_center_median()) < 0:
            f.normal_flip()
    return bm


def face_cutter():
    bm = bmesh.new()

    def prism(outline):
        # Funnel: wider at the surface, narrower inside -> sloped, clean socket walls.
        cx = sum(p[0] for p in outline) / len(outline)
        cz = sum(p[1] for p in outline) / len(outline)
        front = [bm.verts.new((cx + (x - cx) * 1.3, -1.0, cz + (z - cz) * 1.3)) for x, z in outline]
        back = [bm.verts.new((cx + (x - cx) * 0.8, -0.3, cz + (z - cz) * 0.8)) for x, z in outline]
        k = len(outline)
        bm.faces.new(front)
        bm.faces.new(list(reversed(back)))
        for i in range(k):
            j = (i + 1) % k
            bm.faces.new((front[j], front[i], back[i], back[j]))

    prism(EYE)
    prism([(-x, z) for x, z in reversed(EYE)])
    prism(MOUTH)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    return bm


# ------------------------------------------------------------------------------------------------
# The ball of boulders
# ------------------------------------------------------------------------------------------------

def fibonacci(n):
    pts = []
    golden = math.pi * (3 - math.sqrt(5))
    for i in range(n):
        z = 1 - 2 * (i + 0.5) / n
        r = math.sqrt(1 - z * z)
        a = i * golden
        pts.append(Vector((math.cos(a) * r, math.sin(a) * r, z)))
    return pts


# Stones of the face, placed like the reference (face plane coords, size). Big and flat, so
# they read as slabs around the carved eyes and mouth.
FACE_STONES = [
    (0.0, 0.3, 0.2), (-0.22, 0.3, 0.17), (0.22, 0.3, 0.17),          # forehead
    (0.0, 0.1, 0.13),                                                 # between the brows
    (0.0, -0.1, 0.15),                                                # nose
    (-0.4, 0.0, 0.16), (0.4, 0.0, 0.16),                              # temples
    (-0.23, -0.17, 0.14), (0.23, -0.17, 0.14),                        # under the eyes
    (-0.37, -0.22, 0.15), (0.37, -0.22, 0.15),                        # cheeks
    (0.0, -0.44, 0.17), (-0.18, -0.42, 0.15), (0.18, -0.42, 0.15),    # chin
    (-0.32, -0.37, 0.14), (0.32, -0.37, 0.14),                        # jaw corners
]


def build_boulders(rng, count=34):
    bm = bmesh.new()
    for d in fibonacci(count):
        d = (d + Vector((rng.gauss(0, 0.08), rng.gauss(0, 0.08), rng.gauss(0, 0.08)))).normalized()
        if d.dot(FRONT) > 0.55:
            continue  # the face stones are placed by hand
        size = rng.uniform(0.17, 0.24)
        if d.z > 0.5:
            size *= 1.1  # bigger stones on top, like the reference
        boulder_bm(bm, d * (R - size * 0.4), d, size, rng, flat=0.68)
    for fx, fz, size in FACE_STONES:
        n = on_face(fx, fz).normalized()
        boulder_bm(bm, n * (R - size * 0.42), n, size * 1.2, rng, flat=0.42, planes=12)
    return bm


def build_base(seed=1):
    """Returns three bmeshes: the stones (face stones included), the brows and the face cutter.
    The caller carves the eyes and the mouth through the stones (the core shows through)."""
    rng = random.Random(seed)
    stones = build_boulders(rng)
    base = build_face_base()
    brows = build_brows(rng)
    cutter = face_cutter()
    squash = Matrix.Diagonal((1.08, 1.0, 0.9, 1.0))
    for b in (stones, base, brows, cutter):
        bmesh.ops.transform(b, matrix=squash, verts=b.verts)
    return stones, base, brows, cutter
