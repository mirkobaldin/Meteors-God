"""Meteor Gods - procedural meteor bodies for Blender (5.x).

Builds the 13 meteor bodies (no accessories: horns, crystals, crests are part of the rock),
renders previews and exports one FBX per meteor for Roblox.

Usage (Blender with no UI, or the `bpy` Python module):
    blender -b -P art/blender/meteors_build.py -- <out_dir> [--no-render] [--no-export] [--only Name]
or  python art/blender/meteors_build.py <out_dir> ...

Conventions (see docs/ASSET_PIPELINE.md):
- diameter ~1 stud, pivot at the center;
- the face side is Blender -Y, exported as Roblox -Z (FBX axis_forward='Z', axis_up='Y'):
  that side stays a smooth sphere of radius 0.5 because the code adds the 3D face there;
- the high-poly colors (crack glow included) are baked into <Name>.png on the low-poly UVs;
- export mesh is decimated to < 3000 triangles.
"""

import math
import os
import random
import sys

import bpy  # first: with the bpy module, bmesh/mathutils exist only after it
import bmesh
from mathutils import Vector, noise

# ------------------------------------------------------------------------------------------------
# Meteor definitions
# ------------------------------------------------------------------------------------------------

def rgb(r, g, b):
    return (r, g, b)


METEORS = [
    dict(id="Pebble", rarity="Common", seed=1,
         rock1=rgb(.16, .15, .14), rock2=rgb(.07, .065, .06), glow=None,
         freq=2.4, plate=.04, groove=.03, gw=.05, lump=.09, det=.014, rough=.9,
         features=[("backspikes", 3)]),
    dict(id="Ember", rarity="Common", seed=2,
         rock1=rgb(.045, .04, .035), rock2=rgb(.11, .07, .05), glow=rgb(1, .32, .04), glowStrength=5,
         freq=3.2, plate=.04, groove=.03, gw=.07, lump=.06, det=.012, rough=.85,
         features=[("backspikes", 8)]),
    dict(id="Frost", rarity="Uncommon", seed=3,
         rock1=rgb(.05, .09, .17), rock2=rgb(.22, .35, .5), glow=rgb(.45, .85, 1), glowStrength=5,
         freq=2.8, plate=.03, groove=.02, gw=.05, lump=.05, det=.01, rough=.35,
         features=[("ice", 26)]),
    dict(id="Spark", rarity="Uncommon", seed=4,
         rock1=rgb(.06, .06, .08), rock2=rgb(.14, .12, .11), glow=rgb(1, .8, .05), glowStrength=5,
         copper=True, freq=3.0, plate=.035, groove=.02, gw=.05, lump=.05, det=.01, rough=.6,
         features=[("bolts", 2)]),
    dict(id="Venom", rarity="Rare", seed=5,
         rock1=rgb(.06, .1, .045), rock2=rgb(.16, .06, .18), glow=rgb(.45, 1, .1), glowStrength=5,
         freq=3.0, plate=.04, groove=.025, gw=.07, lump=.06, det=.012, rough=.55,
         features=[("horns", 2, rgb(.12, .05, .14)), ("backspikes", 6)]),
    dict(id="Crystal", rarity="Rare", seed=6,
         rock1=rgb(.17, .15, .19), rock2=rgb(.28, .25, .3), glow=rgb(1, .3, .8), glowStrength=3,
         freq=2.8, plate=.035, groove=.02, gw=.05, lump=.05, det=.01, rough=.6,
         features=[("crystals", 10)]),
    dict(id="Magma", rarity="Epic", seed=7,
         rock1=rgb(.035, .03, .03), rock2=rgb(.08, .06, .05), glow=rgb(1, .22, .02), glowStrength=8,
         freq=2.4, plate=.06, groove=.04, gw=.11, lump=.05, det=.012, rough=.8,
         features=[("horns", 2, rgb(.05, .04, .04)), ("backspikes", 4)]),
    dict(id="Aurora", rarity="Epic", seed=8,
         rock1=rgb(.02, .045, .12), rock2=rgb(.04, .09, .2), glow=rgb(.1, 1, .7), glow2=rgb(.65, .3, 1), glowStrength=4,
         freq=2.2, plate=.035, groove=.02, gw=.06, lump=.03, det=.004, rough=.45,
         features=[("shards", 8, rgb(.05, .12, .25))]),
    dict(id="Solar", rarity="Legendary", seed=9,
         rock1=rgb(.75, .3, .03), rock2=rgb(.45, .12, .02), glow=rgb(1, .8, .3), glowStrength=5, bodyEmit=.5,
         freq=2.6, plate=.04, groove=.03, gw=.08, lump=.04, det=.01, rough=.5,
         features=[("crest", 11, rgb(1, .65, .12), 3)]),
    dict(id="Royal Comet", rarity="Legendary", seed=10,
         rock1=rgb(.4, .52, .7), rock2=rgb(.72, .82, .93), glow=None, gold=True,
         freq=2.6, plate=.035, groove=.02, gw=.06, lump=.04, det=.008, rough=.35,
         features=[("icecrest", 9)]),
    dict(id="Void", rarity="Mythic", seed=11,
         rock1=rgb(.01, .006, .016), rock2=rgb(.03, .012, .05), glow=rgb(.6, .15, 1), glowStrength=6,
         freq=3.4, plate=.04, groove=.03, gw=.07, lump=.08, det=.012, rough=.7,
         features=[("orbit", 7), ("backspikes", 5)]),
    dict(id="Supernova", rarity="Mythic", seed=12,
         rock1=rgb(.55, .06, .04), rock2=rgb(.95, .62, .12), glow=rgb(1, .85, .6), glowStrength=9,
         freq=2.3, plate=.06, groove=.05, gw=.13, lump=.04, det=.01, rough=.45, metalPlates=True,
         features=[("crest", 7, rgb(1, .95, .85), 12), ("orbit", 5)]),
    dict(id="Blue Comet", rarity="Epic", seed=13,
         rock1=rgb(.03, .08, .35), rock2=rgb(.08, .18, .55), glow=rgb(.3, .9, 1), glowStrength=5,
         freq=2.8, plate=.035, groove=.02, gw=.06, lump=.03, det=.008, rough=.4, stretch=1.3,
         features=[("fins", 5)]),
]

FRONT = Vector((0, -1, 0))  # the face side
BAKING = False  # while baking textures: no metal (a metal has no diffuse color, it would bake black)

# ------------------------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------------------------

def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def lerp3(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def cell_hash(p):
    v = math.sin(p.x * 127.1 + p.y * 311.7 + p.z * 74.7) * 43758.5453
    return v - math.floor(v)


def front_weight(n):
    """1 on the face area, 0 away from it."""
    return smoothstep(0.55, 0.8, n.dot(FRONT))


def new_material(name, color, rough=.6, metal=0., emit=None, emit_strength=0., transmission=0., alpha=1.):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = 0 if BAKING else metal
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = emit_strength
    if transmission:
        b.inputs["Transmission Weight"].default_value = transmission
    if alpha < 1:
        b.inputs["Alpha"].default_value = alpha
    return m


def body_material(d):
    m = bpy.data.materials.new(d["id"] + "_Body")
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    col = nt.nodes.new("ShaderNodeAttribute")
    col.attribute_name = "Col"
    glow = nt.nodes.new("ShaderNodeAttribute")
    glow.attribute_name = "Glow"
    metal = nt.nodes.new("ShaderNodeAttribute")
    metal.attribute_name = "Metal"
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(col.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(metal.outputs["Color"], sep.inputs["Color"])
    if not BAKING:
        nt.links.new(sep.outputs["Red"], b.inputs["Metallic"])
    b.inputs["Roughness"].default_value = d["rough"]
    if d.get("glow") or d.get("bodyEmit"):
        nt.links.new(glow.outputs["Color"], b.inputs["Emission Color"])
        b.inputs["Emission Strength"].default_value = min(d.get("glowStrength", 1), 3)
    return m


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def mesh_object(name, bm, material, smooth=False):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = smooth
    me.materials.append(material)
    return link(bpy.data.objects.new(name, me))


def set_point_color(me, name, values):
    attr = me.color_attributes.get(name) or me.color_attributes.new(name, "FLOAT_COLOR", "POINT")
    for i, c in enumerate(values):
        attr.data[i].color = (*c, 1)


def fill_feature_colors(obj, color, glow=(0, 0, 0), metal=0.):
    me = obj.data
    n = len(me.polygons)
    set_face_color(me, "Col", [color] * n)
    set_face_color(me, "Glow", [glow] * n)
    set_face_color(me, "Metal", [(metal, metal, metal)] * n)


def frame_for(direction):
    d = direction.normalized()
    up = Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))
    x = d.cross(up).normalized()
    y = d.cross(x).normalized()
    return x, y


def spike_bm(bm, base, direction, length, radius, sides=6, rings=8, bend=None, taper=1.0, tip=True):
    """Tapered tube along a (possibly curved) path, closed at the tip."""
    direction = direction.normalized()
    bend = bend or Vector((0, 0, 0))
    prev = None
    first = None
    for i in range(rings + 1):
        t = i / rings
        center = base + direction * length * t + bend * length * t * t
        ahead = base + direction * length * min(1, t + 0.01) + bend * length * min(1, t + 0.01) ** 2
        tangent = (ahead - center).normalized() if (ahead - center).length > 1e-6 else direction
        x, y = frame_for(tangent)
        r = radius * (1 - t) ** taper if tip else radius * (1 - 0.3 * t)
        if tip and i == rings:
            v = bm.verts.new(center)
            for k in range(sides):
                bm.faces.new((prev[k], prev[(k + 1) % sides], v))
            return
        ring = [bm.verts.new(center + (x * math.cos(a) + y * math.sin(a)) * r)
                for a in (k / sides * math.tau for k in range(sides))]
        if prev:
            for k in range(sides):
                bm.faces.new((prev[k], prev[(k + 1) % sides], ring[(k + 1) % sides], ring[k]))
        else:
            first = ring
        prev = ring
    bm.faces.new(list(reversed(first)))
    bm.faces.new(prev)


def crystal_bm(bm, base, direction, length, radius, sides=6):
    """Hexagonal crystal with a pointed tip (faceted)."""
    direction = direction.normalized()
    x, y = frame_for(direction)
    angles = [k / sides * math.tau for k in range(sides)]
    r0 = [bm.verts.new(base + (x * math.cos(a) + y * math.sin(a)) * radius * 0.85) for a in angles]
    mid = base + direction * length * 0.72
    r1 = [bm.verts.new(mid + (x * math.cos(a) + y * math.sin(a)) * radius) for a in angles]
    tipv = bm.verts.new(base + direction * length)
    for k in range(sides):
        bm.faces.new((r0[k], r0[(k + 1) % sides], r1[(k + 1) % sides], r1[k]))
        bm.faces.new((r1[k], r1[(k + 1) % sides], tipv))
    bm.faces.new(list(reversed(r0)))


def rock_bm(bm, center, radius, rng, sub=2):
    """Small lumpy rock (for chunks and orbiting debris)."""
    res = bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=radius)
    off = Vector((rng.random() * 50, rng.random() * 50, rng.random() * 50))
    for v in res["verts"]:
        n = v.co.normalized()
        v.co = center + n * radius * (1 + 0.35 * noise.noise(n * 2.2 + off))


def random_dir(rng, avoid_front=0.25, min_z=-1.0, max_z=1.0):
    for _ in range(200):
        v = Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))).normalized()
        if v.dot(FRONT) < avoid_front and min_z <= v.z <= max_z:
            return v
    return Vector((0, 1, 0))


# ------------------------------------------------------------------------------------------------
# Body
# ------------------------------------------------------------------------------------------------

def build_body_cracked(d, subdiv):
    """Previous look (kept for reference): smooth rock with glowing voronoi cracks."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=0.5)
    off = Vector((d["seed"] * 13.1, d["seed"] * 7.3, d["seed"] * 3.7))
    cols, glows, metals = [], [], []
    bm.verts.ensure_lookup_table()
    for v in bm.verts:
        n = v.co.normalized()
        dist, pts = noise.voronoi(n * d["freq"] + off, distance_metric="DISTANCE", exponent=2.5)
        edge = dist[1] - dist[0]
        h = cell_hash(pts[0])
        crack = 1 - smoothstep(0, d["gw"], edge)
        lump = noise.fractal(n * 1.4 + off, 1.0, 2.0, 3) * d["lump"]
        detail = noise.noise(n * 9 + off) * d["det"]
        r = 0.5 + lump + (h - 0.5) * 2 * d["plate"] - crack * d["groove"] + detail
        w = front_weight(n)
        r = r * (1 - w) + (0.5 + detail * 0.3) * w
        co = n * r
        if d.get("stretch") and co.y > 0:
            co.y *= d["stretch"]
        v.co = co

        gate = smoothstep(-0.35, 0.05, noise.noise(n * 2.3 + off * 1.7))  # not every crack glows
        rock = lerp3(d["rock1"], d["rock2"], h * 0.7 + 0.3 * (noise.noise(n * 4 + off) * 0.5 + 0.5))
        metal = 0.0
        if d.get("copper") and h > 0.85 and w < 0.3:
            rock, metal = (0.75, 0.38, 0.16), 1.0
        if d.get("metalPlates") and h > 0.55:
            rock, metal = lerp3(rock, (1.0, 0.7, 0.2), 0.7), 0.8
        g = (0, 0, 0)
        glow_mask = crack * gate * (1 - 0.6 * w)
        if d.get("glow"):
            gc = d["glow"]
            if d.get("glow2"):
                gc = lerp3(gc, d["glow2"], noise.noise(n * 1.8 + off) * 0.5 + 0.5)
            g = tuple(c * glow_mask for c in gc)
            rock = lerp3(rock, gc, glow_mask * 0.6)
        if d.get("gold"):
            rock = lerp3(rock, (1.0, 0.72, 0.25), crack)
            metal = max(metal, crack)
        if d.get("bodyEmit"):
            g = tuple(max(g[i], rock[i] * d["bodyEmit"] / d.get("glowStrength", 1)) for i in range(3))
        cols.append(rock)
        glows.append(g)
        metals.append((metal, metal, metal))
    obj = mesh_object(d["id"] + "_Body", bm, body_material(d), smooth=True)
    set_point_color(obj.data, "Col", cols)
    set_point_color(obj.data, "Glow", glows)
    set_point_color(obj.data, "Metal", metals)
    return obj


# ------------------------------------------------------------------------------------------------
# Carved body (the look the owner chose): faceted low-poly rock covered in octagonal craters,
# the angry face CUT INTO the rock. The inside of every hole glows with the meteor's element.
# ------------------------------------------------------------------------------------------------

# Face holes in the front plane (x right, z up as seen from the front), Blender units.
EYE = [(0.035, 0.0), (0.075, 0.075), (0.31, 0.165), (0.3, 0.04), (0.21, -0.055), (0.085, -0.06)]
MOUTH = [(-0.26, -0.115), (-0.13, -0.135), (-0.095, -0.205), (-0.06, -0.14), (0.06, -0.14), (0.095, -0.205),
         (0.13, -0.135), (0.26, -0.115), (0.2, -0.245), (0.07, -0.27), (0.035, -0.215), (-0.035, -0.215),
         (-0.07, -0.27), (-0.2, -0.245)]
CYCLOPS = [(-0.2, 0.06), (-0.1, 0.11), (0.0, 0.08), (0.1, 0.11), (0.2, 0.06), (0.15, -0.04), (0.0, -0.07), (-0.15, -0.04)]


def prism_bm(bm, outline, y_front, y_back):
    """Extrudes a 2D outline (x, z) along Y: a cutter for the face holes."""
    front = [bm.verts.new((x, y_front, z)) for (x, z) in outline]
    back = [bm.verts.new((x, y_back, z)) for (x, z) in outline]
    n = len(outline)
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((front[j], front[i], back[i], back[j]))


def frustum_bm(bm, center, normal, r_out, r_in, depth, sides=8):
    """Octagonal pit cutter: wide at the surface, narrower at the bottom (bevelled crater)."""
    x, y = frame_for(normal)
    top_c = center + normal * 0.25
    bot_c = center - normal * depth
    angles = [k / sides * math.tau + 0.2 for k in range(sides)]
    top = [bm.verts.new(top_c + (x * math.cos(a) + y * math.sin(a)) * r_out * 1.25) for a in angles]
    mid = [bm.verts.new(center + (x * math.cos(a) + y * math.sin(a)) * r_out) for a in angles]
    bot = [bm.verts.new(bot_c + (x * math.cos(a) + y * math.sin(a)) * r_in) for a in angles]
    bm.faces.new(top)
    bm.faces.new(list(reversed(bot)))
    for ring_a, ring_b in ((top, mid), (mid, bot)):
        for i in range(sides):
            j = (i + 1) % sides
            bm.faces.new((ring_a[j], ring_a[i], ring_b[i], ring_b[j]))


def apply_boolean(target, cutter):
    mod = target.modifiers.new("Carve", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = cutter
    mod.solver = "EXACT"
    mod.use_self = True
    bpy.ops.object.select_all(action="DESELECT")
    target.select_set(True)
    bpy.context.view_layer.objects.active = target
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter)


def build_body_carved(d, subdiv):
    """Previous look: single low-poly rock with craters and the carved face."""
    rng = random.Random(d["seed"] * 101)
    off = Vector((d["seed"] * 13.1, d["seed"] * 7.3, d["seed"] * 3.7))
    # 1) Faceted rock: a coarse icosphere pushed around by noise (flat shaded = chiselled stone).
    # Low-poly rock: a gently deformed sphere collapsed down to a few hundred big irregular facets.
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=5, radius=0.5)
    for v in bm.verts:
        n = v.co.normalized()
        r = 0.5 + noise.fractal(n * 1.3 + off, 1.0, 2.0, 2) * d.get("lump", .05) + noise.noise(n * 4 + off) * 0.025 \
            + noise.noise(n * 11 + off) * 0.008 + abs(noise.noise(n * 7 + off * 2)) * -0.012
        if n.dot(FRONT) > 0.55:  # keep the face area round so the carving reads well
            r = 0.5 + (r - 0.5) * 0.35
        co = n * r
        if d.get("stretch") and co.y > 0:
            co.y *= d["stretch"]
        v.co = co
    body = mesh_object(d["id"] + "_Body", bm, body_material(d), smooth=False)
    mod = body.modifiers.new("Facets", "DECIMATE")
    mod.ratio = d.get("facets", 1500) / len(body.data.polygons)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=mod.name)

    # 2) Cutters: the face and the craters, in one object.
    cut = bmesh.new()
    prism_bm(cut, EYE, -1.0, -0.28)  # every meteor has two eyes
    prism_bm(cut, [(-x, z) for (x, z) in reversed(EYE)], -1.0, -0.28)
    prism_bm(cut, MOUTH, -1.0, -0.27)
    placed = []
    for _ in range(d.get("craters", 55) * 10):
        if len(placed) >= d.get("craters", 55):
            break
        n = Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))).normalized()
        if n.z > 0.92:  # no big crater on top
            continue
        if n.dot(FRONT) > 0.2 and abs(n.x) < 0.42 and -0.4 < n.z < 0.32:  # not on the face itself
            continue
        size = rng.choice((0.03, 0.035, 0.045, 0.06, 0.08, 0.1, 0.13, 0.16))
        if any(math.acos(max(-1, min(1, n.dot(m)))) < (size + s2) * 1.35 for m, s2 in placed):
            continue
        placed.append((n, size))
        frustum_bm(cut, n * 0.5, n, size, size * 0.55, size * 0.75)
    bmesh.ops.recalc_face_normals(cut, faces=cut.faces)
    bmesh.ops.triangulate(cut, faces=cut.faces)
    cme = bpy.data.meshes.new("Cutter")
    cut.to_mesh(cme)
    cut.free()
    cutter = link(bpy.data.objects.new("Cutter", cme))
    apply_boolean(body, cutter)

    # 3) Colors per face: rock outside, glowing element color inside the holes.
    me = body.data
    glow = d.get("glow")
    cols, glows = [], []
    for poly in me.polygons:
        c = poly.center
        wall = smoothstep(0.47, 0.42, c.length)  # inside a hole
        depth = smoothstep(0.41, 0.31, c.length)  # near the bottom: glows
        h = cell_hash(c * 7 + off)
        rock = lerp3(d["rock1"], d["rock2"], h)
        rock = lerp3(rock, lerp3(d["rock1"], (0, 0, 0), 0.55), wall)
        if glow:
            gc = glow
            if d.get("glow2"):
                gc = lerp3(glow, d["glow2"], noise.noise(c * 3 + off) * 0.5 + 0.5)
            cols.append(lerp3(rock, gc, depth))
            glows.append(tuple(x * depth for x in gc))
        else:
            cols.append(lerp3(rock, lerp3(d["rock2"], (0, 0, 0), 0.6), depth))
            glows.append((0, 0, 0))
    set_face_color(me, "Col", cols)
    set_face_color(me, "Glow", glows)
    set_face_color(me, "Metal", [(0, 0, 0)] * len(cols))
    for poly in me.polygons:
        poly.use_smooth = False
    return body


DEFAULT_GLOW = (1.0, 0.55, 0.2)


def glow_of(d):
    return d.get("glow") or d.get("coreGlow") or DEFAULT_GLOW


def build_core(d):
    """Inner layer: a glowing ball of the element's color, seen through the cracks and the face."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=4, radius=0.43)
    gc = glow_of(d)
    mat = new_material(d["id"] + "_Core", gc, rough=.4, emit=gc, emit_strength=d.get("coreStrength", 1.6))
    core = mesh_object(d["id"] + "_Core", bm, mat, smooth=True)
    fill_feature_colors(core, gc, gc)
    return core


def build_body(d, subdiv, budget=None):
    """Outer layer: a rock shell of rounded plates. Along the cracks the shell dips below the
    glowing core (radius 0.43), so the core shows through as sharp lines of light. The angry
    face is cut through the shell. High detail for renders/baking; `budget` = max triangles."""
    off = Vector((d["seed"] * 13.1, d["seed"] * 7.3, d["seed"] * 3.7))
    freq = d.get("plates", 3.6)
    gw = d.get("crack", 0.07)
    gc = glow_of(d)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=max(subdiv, 7), radius=0.5)
    cols, glows = [], []
    for v in bm.verts:
        n = v.co.normalized()
        dist, pts = noise.voronoi(n * freq + off, distance_metric="DISTANCE", exponent=2.5)
        e = dist[1] - dist[0]
        h = cell_hash(pts[0])
        crack = (1 - smoothstep(0, gw, e)) ** 1.6
        # Big cracks everywhere, plus thin secondary cracks inside the plates.
        dist2, _ = noise.voronoi(n * freq * 2.6 + off * 1.9, distance_metric="DISTANCE", exponent=2.5)
        thin = 0.0 * dist2[0]  # (secondary cracks made speckles: off)
        mask = smoothstep(0.5, 0.68, n.dot(FRONT))  # the face is one solid plate (no cracks through it)
        crack *= 1 - mask
        pillow = max(smoothstep(0, gw * 4, e), mask)  # plates bulge in their middle
        r = 0.47 + pillow * 0.03 + (h - 0.5) * 0.02 \
            + noise.fractal(n * 1.3 + off, 1.0, 2.0, 2) * d.get("lump", .05) * 0.5 \
            + noise.noise(n * 16 + off) * 0.004 - crack * 0.1 - thin * 0.05
        if n.dot(FRONT) > 0.6:
            r = max(r, 0.45 + (r - 0.45) * 0.5)
        co = n * r
        if d.get("stretch") and co.y > 0:
            co.y *= d["stretch"]
        v.co = co
        rim = max(crack, thin) ** 0.7
        rock = lerp3(d["rock1"], d["rock2"], h * 0.75 + 0.25 * (noise.noise(n * 9 + off) * 0.5 + 0.5))
        rock = tuple(c * 0.65 for c in rock)
        cols.append(lerp3(rock, gc, min(1, rim * 1.2)))
        glows.append(tuple(x * rim for x in gc))
    shell = mesh_object(d["id"] + "_Body", bm, body_material(d), smooth=True)
    set_point_color(shell.data, "Col", cols)
    set_point_color(shell.data, "Glow", glows)
    set_point_color(shell.data, "Metal", [(0, 0, 0)] * len(cols))
    if budget:
        tris = sum(len(p.vertices) - 2 for p in shell.data.polygons)
        if tris > budget:
            bpy.ops.object.select_all(action="DESELECT")
            shell.select_set(True)
            bpy.context.view_layer.objects.active = shell
            dec = shell.modifiers.new("Budget", "DECIMATE")
            dec.ratio = budget / tris
            bpy.ops.object.modifier_apply(modifier=dec.name)
    # The face, cut through the shell (the core shows through).
    cut = bmesh.new()
    prism_bm(cut, EYE, -1.0, -0.3)
    prism_bm(cut, [(-x, z) for (x, z) in reversed(EYE)], -1.0, -0.3)
    prism_bm(cut, MOUTH, -1.0, -0.3)
    bmesh.ops.recalc_face_normals(cut, faces=cut.faces)
    bmesh.ops.triangulate(cut, faces=cut.faces)
    cme = bpy.data.meshes.new("Cutter")
    cut.to_mesh(cme)
    cut.free()
    apply_boolean(shell, link(bpy.data.objects.new("Cutter", cme)))
    return shell


def set_face_color(me, name, face_values):
    attr = me.color_attributes.get(name) or me.color_attributes.new(name, "FLOAT_COLOR", "CORNER")
    for poly, c in zip(me.polygons, face_values):
        for li in poly.loop_indices:
            attr.data[li].color = (*c, 1)


# ------------------------------------------------------------------------------------------------
# Features (all part of the body: rock, ice, crystal; never accessories)
# ------------------------------------------------------------------------------------------------

def add_feature(d, f, rng, parts):
    kind = f[0]
    dark = lerp3(d["rock1"], (0, 0, 0), 0.2)
    bm = bmesh.new()
    color, glow, metal = dark, (0, 0, 0), 0.0
    mat = None
    if kind == "chunks":
        for _ in range(f[1]):
            n = random_dir(rng, 0.2)
            rock_bm(bm, n * 0.5, rng.uniform(0.1, 0.17), rng)
        color = lerp3(d["rock1"], d["rock2"], 0.5)
        mat = new_material(d["id"] + "_Chunk", color, rough=d["rough"])
    elif kind == "ice":
        for _ in range(f[1]):
            n = random_dir(rng, 0.0)
            crystal_bm(bm, n * 0.36, (n + Vector((rng.gauss(0, .25), rng.gauss(0, .25), rng.gauss(0, .25)))),
                       rng.uniform(0.22, 0.55), rng.uniform(0.04, 0.085))
        color, glow = (0.75, 0.92, 1.0), (0.2, 0.45, 0.6)
        mat = new_material(d["id"] + "_Ice", color, rough=.05, transmission=.7, emit=(.4, .75, 1), emit_strength=.6)
    elif kind == "crystals":
        for i in range(f[1]):
            n = random_dir(rng, 0.0, min_z=-0.3)
            crystal_bm(bm, n * 0.36, n + Vector((rng.gauss(0, .2), rng.gauss(0, .2), rng.gauss(0, .2))),
                       rng.uniform(0.25, 0.55), rng.uniform(0.05, 0.1))
        color, glow = (1.0, 0.45, 0.85), (0.6, 0.15, 0.5)
        mat = new_material(d["id"] + "_Crystal", color, rough=.08, transmission=.45, emit=(1, .35, .85), emit_strength=1.5)
    elif kind == "horns":
        hc = f[2]
        for side in (-1, 1):
            base_dir = Vector((side * 0.55, 0.05, 0.8)).normalized()
            spike_bm(bm, base_dir * 0.38, Vector((side * 1.0, 0.1, 0.25)), 0.6, 0.12, sides=10, rings=14,
                     bend=Vector((-side * 0.2, 0.35, 1.0)), taper=0.85)
        color = hc
        mat = new_material(d["id"] + "_Horn", hc, rough=.55)
    elif kind == "backspikes":
        for _ in range(f[1]):
            n = random_dir(rng, -0.35)
            spike_bm(bm, n * 0.42, n, rng.uniform(0.18, 0.32), rng.uniform(0.04, 0.07), sides=5, rings=3, taper=1.0)
        mat = new_material(d["id"] + "_Spike", dark, rough=d["rough"])
    elif kind == "rods":
        for side in (-1, 1):
            base_dir = Vector((side * 0.45, 0.25, 0.85)).normalized()
            spike_bm(bm, base_dir * 0.42, base_dir + Vector((side * 0.2, 0, 0.3)), 0.4, 0.035, sides=6, rings=2,
                     tip=False)
            tip = base_dir * 0.42 + (base_dir + Vector((side * 0.2, 0, 0.3))).normalized() * 0.42
            bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.06, matrix=__import__("mathutils").Matrix.Translation(tip))
        color, metal, glow = (0.8, 0.42, 0.18), 1.0, (0.3, 0.25, 0.02)
        mat = new_material(d["id"] + "_Copper", color, rough=.3, metal=1, emit=(1, .9, .3), emit_strength=.4)
    elif kind == "bolts":
        # Zigzag lightning-bolt horns of copper.
        for side in (-1, 1):
            p = Vector((side * 0.45, 0.2, 0.85)).normalized() * 0.4
            steps = [Vector((side * 0.1, 0.02, 0.2)), Vector((-side * 0.07, 0.02, 0.12)), Vector((side * 0.12, 0.0, 0.2))]
            radius = 0.06
            for k, step in enumerate(steps):
                last = k == len(steps) - 1
                spike_bm(bm, p, step, step.length * (1.0 if last else 1.15), radius, sides=5, rings=2 if not last else 3,
                         taper=1.0 if last else 0.25, tip=last)
                p = p + step
                radius *= 0.75
        color, metal, glow = (0.8, 0.42, 0.18), 1.0, (0.3, 0.22, 0.0)
        mat = new_material(d["id"] + "_Copper", color, rough=.3, metal=1, emit=(1, .8, .1), emit_strength=.6)
    elif kind == "shards":
        for _ in range(f[1]):
            n = random_dir(rng, -0.1)
            crystal_bm(bm, n * 0.38, n, rng.uniform(0.25, 0.45), rng.uniform(0.05, 0.09), sides=4)
        color = f[2]
        glow = (0.05, 0.4, 0.3)
        mat = new_material(d["id"] + "_Shard", color, rough=.12, emit=(.1, 1, .7), emit_strength=.8)
    elif kind in ("crest", "icecrest"):
        count = f[1]
        for i in range(count):
            a = i / count * math.tau
            ring_dir = Vector((math.sin(a) * 0.55, math.cos(a) * 0.55 + 0.1, 0.8)).normalized()
            if ring_dir.dot(FRONT) > 0.55:
                ring_dir = (ring_dir + Vector((0, 0.4, 0.3))).normalized()
            tall = 0.42 if i % 2 == 0 else 0.28
            if kind == "crest":
                spike_bm(bm, ring_dir * 0.4, ring_dir + Vector((0, 0, 0.5)), tall, 0.065, sides=5, rings=4,
                         bend=Vector((0, 0.15, 0.1)), taper=1.2)
            else:
                crystal_bm(bm, ring_dir * 0.38, ring_dir + Vector((0, 0, 0.6)), tall + 0.05, 0.06)
        if kind == "crest":
            color = f[2]
            glow = tuple(c * 0.6 for c in color)
            mat = new_material(d["id"] + "_Crest", color, rough=.35, metal=.3, emit=color, emit_strength=f[3])
        else:
            color, glow = (0.85, 0.95, 1.0), (0.3, 0.45, 0.6)
            mat = new_material(d["id"] + "_IceCrest", color, rough=.04, transmission=.65, emit=(.6, .85, 1), emit_strength=.8)
    elif kind == "orbit":
        for i in range(f[1]):
            a = i / f[1] * math.tau + rng.random() * 0.4
            p = Vector((math.cos(a) * 0.78, math.sin(a) * 0.78 + 0.15, math.sin(a * 2) * 0.15 + 0.1))
            if p.normalized().dot(FRONT) > 0.5:
                p.y += 0.5
            crystal_bm(bm, p, Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))), rng.uniform(0.1, 0.18),
                       rng.uniform(0.03, 0.05), sides=4)
        color = lerp3(d["rock2"], (0, 0, 0), 0.3)
        glow = tuple(c * 0.4 for c in (d.get("glow") or (0, 0, 0)))
        mat = new_material(d["id"] + "_Debris", color, rough=.3, emit=d.get("glow"), emit_strength=1.5 if d.get("glow") else 0)
    elif kind == "fins":
        for i in range(f[1]):
            x = (i - (f[1] - 1) / 2) * 0.17
            base = Vector((x, -0.05, 0.47 - abs(x) * 0.5)).normalized() * 0.42
            spike_bm(bm, base, Vector((x * 1.2, 1.0, 0.55)), 0.95 - abs(x) * 0.8, 0.09, sides=4, rings=6,
                     bend=Vector((0, 0.2, -0.25)), taper=1.1)
        color = lerp3(d["rock2"], (0, 0, 0), 0.15)
        mat = new_material(d["id"] + "_Fin", color, rough=.35)
    else:
        bm.free()
        return
    obj = mesh_object(d["id"] + "_" + kind, bm, mat, smooth=False)
    fill_feature_colors(obj, color, glow, metal)
    parts.append(obj)


# ------------------------------------------------------------------------------------------------
# Face preview (only for the renders: in game the code adds the face)
# ------------------------------------------------------------------------------------------------

def face_preview(d):
    """Approximates MeteorVisual.lua's face (angry eyes, cocky grin) so the renders show the final look."""
    import mathutils
    parts = []
    skin = lerp3(d["rock1"], (0, 0, 0), 0.35)

    def surf(x, y):
        return -math.sqrt(max(0.25 - x * x - y * y, 0)) + 0.02

    def ball(name, pos, size, color, emit=0., rot=0.):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.5)
        m = mathutils.Matrix.Translation(pos) @ mathutils.Matrix.Rotation(rot, 4, "Y") @ mathutils.Matrix.Diagonal((*size, 1))
        bmesh.ops.transform(bm, matrix=m, verts=bm.verts)
        mat = new_material(name, color, rough=.3, emit=color if emit else None, emit_strength=emit)
        parts.append(mesh_object(d["id"] + "_Face_" + name, bm, mat, smooth=True))

    def block(name, pos, size, color, rot=0.):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1)
        m = mathutils.Matrix.Translation(pos) @ mathutils.Matrix.Rotation(rot, 4, "Y") @ mathutils.Matrix.Diagonal((*size, 1))
        bmesh.ops.transform(bm, matrix=m, verts=bm.verts)
        mat = new_material(name, color, rough=.7)
        parts.append(mesh_object(d["id"] + "_Face_" + name, bm, mat))

    # Roblox face coords (x right, y up, z = -front) -> Blender (x, z, y).
    def B(x, y, z):
        return Vector((x, z, y))

    cyclops = False  # every meteor has two eyes
    eye_color = d.get("glow") or (1.0, 0.8, 0.3)
    eyes = [(0, 0.08, 0.3)] if cyclops else [(-0.15, 0.07, 0.19), (0.15, 0.07, 0.19)]
    for (x, y, w) in eyes:
        z = surf(x, y)
        side = 1 if x > 0 else (-1 if x < 0 else 0)
        # Dark socket, glowing slanted slit, thin black pupil.
        ball("Socket", B(x, y, z + 0.015), (w * 1.15, w * 0.3, w * 0.6), skin, rot=side * math.radians(18))
        ball("Eye", B(x, y, z - 0.012), (w * 0.95, w * 0.3, w * 0.26), eye_color, emit=4, rot=side * math.radians(18))
        block("Pupil", B(x + side * w * 0.05, y, z - 0.04), (w * 0.09, 0.03, w * 0.3), (0.01, 0.01, 0.01))
    # Heavy V-shaped brow ridge (rock).
    for side in ((0,) if cyclops else (-1, 1)):
        bx = side * 0.13
        by = 0.17 if not cyclops else 0.2
        width = 0.26 if not cyclops else 0.42
        block("Brow", B(bx, by, surf(bx, by) - 0.04), (width, 0.09, 0.085), skin, rot=-side * math.radians(28))
    # Wide jagged mouth full of teeth.
    y = -0.15
    z = surf(0, y)
    ball("Mouth", B(0, y, z + 0.01), (0.36, 0.1, 0.14), (0.02, 0.005, 0.005))
    for i in range(6):
        tx = -0.15 + i * 0.06
        block("ToothTop", B(tx, y + 0.045, surf(tx, y + 0.045) - 0.03), (0.04, 0.03, 0.04), (0.95, 0.92, 0.85), rot=math.radians(45))
    for i in range(5):
        tx = -0.12 + i * 0.06
        block("ToothBottom", B(tx, y - 0.05, surf(tx, y - 0.05) - 0.03), (0.035, 0.03, 0.035), (0.95, 0.92, 0.85), rot=math.radians(45))
    return parts


# ------------------------------------------------------------------------------------------------
# Scene, render, export
# ------------------------------------------------------------------------------------------------

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


# Rig: the jaw is a separate piece hinged behind the mouth; the pupils are balls in the eye holes.
HINGE = Vector((0, -0.08, -0.16))  # Blender coords
JAW_TOP = -0.17  # the jaw is the front of the shell below this height (mid mouth)
PUPIL_R = 0.055
PUPIL_DEPTH = 0.445  # distance of the pupils' centers from the middle (just in front of the core)


def eye_center(side):
    xs = [p[0] for p in EYE]
    zs = [p[1] for p in EYE]
    x, z = sum(xs) / len(xs) * side, sum(zs) / len(zs)
    return Vector((x, -math.sqrt(max(0.25 - x * x - z * z, 0)), z)).normalized() * PUPIL_DEPTH


def split_jaw(shell):
    bpy.ops.object.select_all(action="DESELECT")
    shell.select_set(True)
    bpy.context.view_layer.objects.active = shell
    for p in shell.data.polygons:
        c = p.center
        p.select = (JAW_TOP > c.z > -0.47 and abs(c.x) < 0.34 and c.normalized().dot(FRONT) > 0.3)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    jaw = [o for o in bpy.context.selected_objects if o != shell][0]
    jaw.name = shell.name.replace("_Body", "") + "_Jaw"
    return jaw


def build_pupils(d):
    mat = new_material(d["id"] + "_Pupil", (0.01, 0.01, 0.012), rough=0.12)
    out = []
    for side in (-1, 1):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=16, radius=PUPIL_R)
        bmesh.ops.translate(bm, vec=eye_center(side), verts=bm.verts)
        o = mesh_object(d["id"] + ("_PupilL" if side < 0 else "_PupilR"), bm, mat, smooth=True)
        fill_feature_colors(o, (0.01, 0.01, 0.012))
        out.append(o)
    return out


def open_jaw(jaw, degrees):
    import mathutils
    m = mathutils.Matrix.Translation(HINGE) @ mathutils.Matrix.Rotation(math.radians(degrees), 4, "X") \
        @ mathutils.Matrix.Translation(-HINGE)
    jaw.matrix_world = m @ jaw.matrix_world


def build(d, subdiv=6, with_face=True, with_core=True, budget=None):
    rng = random.Random(d["seed"])
    body = build_body(d, subdiv, budget)
    jaw = split_jaw(body)
    if with_face:  # renders: show the rig (pupils looking at you, jaw a little open)
        open_jaw(jaw, 9)
    parts = [body, jaw] + (build_pupils(d) if with_face else [])
    if with_core:
        parts.append(build_core(d))
    for f in d["features"]:
        add_feature(d, f, rng, parts)
    face = []  # the face is carved in the rock (face_preview kept for the old look)
    return parts, face


def setup_render(scene, res, samples):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("Space")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.004, 0.003, 0.012, 1)
    bg.inputs["Strength"].default_value = 1
    scene.world = world
    scene.view_settings.view_transform = "Standard"  # saturated colors (AgX washed the glow out)
    scene.view_settings.look = "Medium High Contrast"


def add_light(scene, name, kind, loc, energy, color=(1, 1, 1), size=1.0):
    data = bpy.data.lights.new(name, kind)
    data.energy = energy
    data.color = color
    if kind == "AREA":
        data.size = size
    obj = bpy.data.objects.new(name, data)
    obj.location = loc
    direction = -Vector(loc)
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(obj)
    return obj


def add_camera(scene, loc, target, lens=50, ortho=None):
    cam = bpy.data.cameras.new("Cam")
    cam.lens = lens
    if ortho:
        cam.type = "ORTHO"
        cam.ortho_scale = ortho
    obj = bpy.data.objects.new("Cam", cam)
    obj.location = loc
    obj.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(obj)
    scene.camera = obj
    return obj


def lights(scene, scale=1.0):
    add_light(scene, "Key", "AREA", (-2.5 * scale, -3 * scale, 2.5 * scale), 350 * scale * scale, (1, .95, .9), 2 * scale)
    add_light(scene, "Rim", "AREA", (2.5 * scale, 3 * scale, 1.5 * scale), 500 * scale * scale, (.55, .45, 1), 2 * scale)
    add_light(scene, "Fill", "AREA", (3 * scale, -2 * scale, -1 * scale), 80 * scale * scale, (.6, .8, 1), 3 * scale)


def group(parts, offset, yaw):
    import mathutils
    m = mathutils.Matrix.Translation(offset) @ mathutils.Matrix.Rotation(yaw, 4, "Z")
    for p in parts:
        p.matrix_world = m @ p.matrix_world


def render_single(d, path):
    reset()
    scene = bpy.context.scene
    parts, face = build(d)
    group(parts + face, Vector((0, 0, 0)), math.radians(-16))
    setup_render(scene, (900, 900), 96)
    lights(scene)
    add_camera(scene, (0, -2.6, 0.5), (0, 0, 0.05), lens=55)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def render_grid(path, subdiv=6):
    reset()
    scene = bpy.context.scene
    cols = 5
    for i, d in enumerate(METEORS):
        r, c = divmod(i, cols)
        n_in_row = min(cols, len(METEORS) - r * cols)
        x = (c - (n_in_row - 1) / 2) * 1.75
        z = -(r - 1) * 2.15
        parts, face = build(d, subdiv)
        group(parts + face, Vector((x, 0, z)), math.radians(-14))
        txt = bpy.data.curves.new(d["id"] + "_Label", "FONT")
        txt.body = d["id"] + "\n" + d["rarity"]
        txt.align_x = "CENTER"
        txt.size = 0.17
        label = bpy.data.objects.new(d["id"] + "_Label", txt)
        label.location = (x, -0.6, z - 0.95)
        label.rotation_euler = (math.radians(90), 0, 0)
        label.data.materials.append(new_material("Label", (1, 1, 1), emit=(1, 1, 1), emit_strength=2))
        scene.collection.objects.link(label)
    setup_render(scene, (2400, 1900), 64)
    add_light(scene, "Key", "AREA", (-5, -9, 6), 6000, (1, .95, .9), 8)
    add_light(scene, "Rim", "AREA", (6, 8, 3), 6000, (.55, .45, 1), 8)
    add_light(scene, "Fill", "AREA", (7, -6, -3), 1500, (.6, .8, 1), 8)
    add_camera(scene, (0, -12, 0.3), (0, 0, 0.1), ortho=10.6)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def join(parts, name):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj


def bake_low(high, name, budget, tex_size, tex_path):
    """Decimated copy of `high` with its colors baked into one texture."""
    scene = bpy.context.scene
    low = high.copy()
    low.data = high.data.copy()
    scene.collection.objects.link(low)
    low.name = name
    low.data.name = name
    bpy.ops.object.select_all(action="DESELECT")
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    tris = sum(len(p.vertices) - 2 for p in low.data.polygons)
    if tris > budget:
        mod = low.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = budget / tris
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for attr in [a.name for a in low.data.color_attributes]:
        low.data.color_attributes.remove(low.data.color_attributes[attr])
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")
    image = bpy.data.images.new(name, tex_size, tex_size)
    mat = bpy.data.materials.new(name + "_Baked")
    mat.use_nodes = True
    node = mat.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = image
    mat.node_tree.nodes.active = node
    low.data.materials.clear()
    low.data.materials.append(mat)
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 4
    high.select_set(True)
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, use_selected_to_active=True,
                        cage_extrusion=0.04, max_ray_distance=0.15, margin=6)
    image.filepath_raw = tex_path
    image.file_format = "PNG"
    image.save()
    mat.node_tree.links.new(node.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    return low


def roblox_box(obj):
    """Bounding box in Roblox axes (X = -x, Y = z, Z = y), in units of the sphere's diameter (1)."""
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return dict(size=(max(xs) - min(xs), max(zs) - min(zs), max(ys) - min(ys)),
                center=(-(max(xs) + min(xs)) / 2, (max(zs) + min(zs)) / 2, (max(ys) + min(ys)) / 2))


def to_roblox(v):
    return (-v.x, v.z, v.y)


def export_fbx(d, path, max_tris=16000, tex_size=2048):
    """One FBX per meteor with two meshes: "Body" (rock shell + horns/crystals) and "Jaw" (hinged),
    each with its colors (cracks included) baked into a texture. The core and the pupils are made
    in Roblox (neon ball + balls moved by the code)."""
    global BAKING
    reset()
    BAKING = True
    try:
        parts, _ = build(d, subdiv=6, with_face=False, with_core=False)
    finally:
        BAKING = False
    body_parts = [p for p in parts if not p.name.endswith("_Jaw")]
    jaw_high = [p for p in parts if p.name.endswith("_Jaw")][0]
    body_high = join(body_parts, d["id"] + "_High")
    jaw_high.name = d["id"] + "_JawHigh"
    folder = os.path.dirname(path)
    file = os.path.splitext(os.path.basename(path))[0]
    body = bake_low(body_high, "Body", max_tris - 2500, tex_size, os.path.join(folder, file + ".png"))
    jaw = bake_low(jaw_high, "Jaw", 2500, tex_size // 2, os.path.join(folder, file + "_Jaw.png"))
    bpy.data.objects.remove(body_high)
    bpy.data.objects.remove(jaw_high)
    tris = sum(len(p.vertices) - 2 for o in (body, jaw) for p in o.data.polygons)
    info = dict(body=roblox_box(body), jaw=roblox_box(jaw), hinge=to_roblox(HINGE),
                eyes=(to_roblox(eye_center(-1)), to_roblox(eye_center(1))), pupil=PUPIL_R * 2)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    jaw.select_set(True)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_UNITS", mesh_smooth_type="FACE",
                             object_types={"MESH"}, path_mode="COPY", embed_textures=True)
    return tris, info


def write_config(path, infos):
    v = lambda t: "Vector3.new(%.4f, %.4f, %.4f)" % tuple(t)
    lines = [
        "-- Generated by art/blender/meteors_build.py: do not edit by hand.",
        "-- Meteor meshes (Assets/Meteors/<id>: a Model with MeshParts \"Body\" and \"Jaw\"), in units of the",
        "-- rock sphere's diameter: bounding boxes (MeshParts are centered on them), the jaw hinge, the",
        "-- centers of the eye holes (where the pupils go) and the pupil diameter.",
        "",
        "return {",
    ]
    for name, i in infos.items():
        lines.append('\t["%s"] = {' % name)
        lines.append("\t\tsize = %s, center = %s," % (v(i["body"]["size"]), v(i["body"]["center"])))
        lines.append("\t\tjaw = { size = %s, center = %s }," % (v(i["jaw"]["size"]), v(i["jaw"]["center"])))
        lines.append("\t\thinge = %s," % v(i["hinge"]))
        lines.append("\t\teyes = { %s, %s }," % (v(i["eyes"][0]), v(i["eyes"][1])))
        lines.append("\t\tpupil = %.4f," % i["pupil"])
        lines.append("\t},")
    lines.append("}")
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    out = os.path.abspath(argv[0] if argv else "art")
    only = argv[argv.index("--only") + 1] if "--only" in argv else None
    render_dir = os.path.join(out, "renders", "meteors")
    export_dir = os.path.join(out, "export", "meteors")
    os.makedirs(render_dir, exist_ok=True)
    os.makedirs(export_dir, exist_ok=True)
    todo = [d for d in METEORS if not only or d["id"] == only]
    boxes = {}
    for d in todo:
        file = d["id"].replace(" ", "")
        if "--no-render" not in argv:
            render_single(d, os.path.join(render_dir, file + ".png"))
        if "--no-export" not in argv:
            tris, box = export_fbx(d, os.path.join(export_dir, file + ".fbx"))
            boxes[d["id"]] = box
            print("EXPORTED", d["id"], tris, "tris")
    if "--config" in argv and boxes:
        write_config(argv[argv.index("--config") + 1], boxes)
    if not only and "--no-render" not in argv and "--no-grid" not in argv:
        render_grid(os.path.join(render_dir, "_all_meteors.png"))
    print("DONE")


if __name__ == "__main__":
    main()
