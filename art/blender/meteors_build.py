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
         features=[("chunks", 7), ("backspikes", 3)]),
    dict(id="Ember", rarity="Common", seed=2,
         rock1=rgb(.045, .04, .035), rock2=rgb(.11, .07, .05), glow=rgb(1, .32, .04), glowStrength=5,
         freq=3.2, plate=.04, groove=.03, gw=.07, lump=.06, det=.012, rough=.85,
         features=[("backspikes", 8), ("chunks", 3)]),
    dict(id="Frost", rarity="Uncommon", seed=3,
         rock1=rgb(.05, .09, .17), rock2=rgb(.22, .35, .5), glow=rgb(.45, .85, 1), glowStrength=5,
         freq=2.8, plate=.03, groove=.02, gw=.05, lump=.05, det=.01, rough=.35,
         features=[("ice", 26)]),
    dict(id="Spark", rarity="Uncommon", seed=4,
         rock1=rgb(.06, .06, .08), rock2=rgb(.14, .12, .11), glow=rgb(1, .8, .05), glowStrength=5,
         copper=True, freq=3.0, plate=.035, groove=.02, gw=.05, lump=.05, det=.01, rough=.6,
         features=[("bolts", 2), ("chunks", 2)]),
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
         freq=2.2, plate=.035, groove=.02, gw=.06, lump=.03, det=.004, rough=.18,
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
         freq=3.4, plate=.04, groove=.03, gw=.07, lump=.08, det=.012, rough=.3,
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
        b.inputs["Emission Strength"].default_value = d.get("glowStrength", 1)
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
    n = len(me.vertices)
    set_point_color(me, "Col", [color] * n)
    set_point_color(me, "Glow", [glow] * n)
    set_point_color(me, "Metal", [(metal, metal, metal)] * n)


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

def build_body(d, subdiv):
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

    cyclops = d["id"] == "Void"
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


def build(d, subdiv=6, with_face=True):
    rng = random.Random(d["seed"])
    body = build_body(d, subdiv)
    parts = [body]
    for f in d["features"]:
        add_feature(d, f, rng, parts)
    face = face_preview(d) if with_face else []
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
    bg.inputs["Color"].default_value = (0.012, 0.008, 0.03, 1)
    bg.inputs["Strength"].default_value = 1
    scene.world = world
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Punchy"


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
    group(parts + face, Vector((0, 0, 0)), math.radians(-28))
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
        group(parts + face, Vector((x, 0, z)), math.radians(-25))
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


def export_fbx(d, path, max_tris=2900, tex_size=1024):
    """Low-poly mesh with the high-poly colors (cracks included) baked into one texture."""
    global BAKING
    reset()
    scene = bpy.context.scene
    BAKING = True
    try:
        high = join(build(d, subdiv=6, with_face=False)[0], d["id"] + "_High")
    finally:
        BAKING = False
    low = high.copy()
    low.data = high.data.copy()
    scene.collection.objects.link(low)
    low.name = d["id"]
    low.data.name = d["id"]
    tris = sum(len(p.vertices) - 2 for p in low.data.polygons)
    bpy.ops.object.select_all(action="DESELECT")
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    if tris > max_tris:
        mod = low.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = max_tris / tris
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for name in [a.name for a in low.data.color_attributes]:
        low.data.color_attributes.remove(low.data.color_attributes[name])
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")

    # Bake the high-poly base color onto the low-poly UVs.
    file = os.path.splitext(os.path.basename(path))[0]
    image = bpy.data.images.new(file, tex_size, tex_size)
    mat = bpy.data.materials.new(d["id"] + "_Baked")
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
    tex_path = os.path.join(os.path.dirname(path), file + ".png")
    image.filepath_raw = tex_path
    image.file_format = "PNG"
    image.save()
    mat.node_tree.links.new(node.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    bpy.data.objects.remove(high)

    tris = sum(len(p.vertices) - 2 for p in low.data.polygons)
    xs = [v.co.x for v in low.data.vertices]
    ys = [v.co.y for v in low.data.vertices]
    zs = [v.co.z for v in low.data.vertices]
    # Bounding box in Roblox axes (X = -x, Y = z, Z = y), in units of the sphere's diameter (1).
    box = dict(size=(max(xs) - min(xs), max(zs) - min(zs), max(ys) - min(ys)),
               center=(-(max(xs) + min(xs)) / 2, (max(zs) + min(zs)) / 2, (max(ys) + min(ys)) / 2))
    bpy.ops.object.select_all(action="DESELECT")
    low.select_set(True)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_UNITS", mesh_smooth_type="FACE",
                             object_types={"MESH"}, path_mode="COPY", embed_textures=True)
    return tris, box


def write_config(path, boxes):
    lines = [
        "-- Generated by art/blender/meteors_build.py: do not edit by hand.",
        "-- Bounding box of each meteor mesh (Assets/Meteors/<id>) in units of its rock sphere's diameter,",
        "-- so MeteorVisual can size the mesh to match the core (the face sits on the sphere).",
        "",
        "return {",
    ]
    for name, b in boxes.items():
        v = lambda t: "Vector3.new(%.4f, %.4f, %.4f)" % t
        lines.append('\t["%s"] = { size = %s, center = %s },' % (name, v(b["size"]), v(b["center"])))
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
