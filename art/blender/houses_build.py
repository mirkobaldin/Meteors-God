"""Meteor Gods: six editable modern villas, Blender 4.4+.

Run: blender -b -P art/blender/houses_build.py -- [--only 1 2] [--no-render]
Coordinates: 1 Blender unit = 1 stud; front = Blender -Y (FBX Roblox -Z).
Outputs: art/blender/houses, art/export/houses, art/renders/houses.
"""

import argparse
import json
import math
import random
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
BLENDS = ROOT / "art/blender/houses"
EXPORTS = ROOT / "art/export/houses"
RENDERS = ROOT / "art/renders/houses"
TEXTURES = EXPORTS / "textures"
for directory in (BLENDS, EXPORTS, RENDERS, TEXTURES):
    directory.mkdir(parents=True, exist_ok=True)

NAMES = ["Star Spirit", "Minor Deity", "Demigod", "Titan", "Cosmic God", "Supreme Deity"]
M = {}
COL = None
HOUSE_ROOT = None
RNG = random.Random(121)


def link(obj):
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)
    COL.objects.link(obj)
    obj.parent = HOUSE_ROOT
    return obj


def material(name, color, rough=.45, metal=0, emit=0, transmission=0, alpha=1):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*color, alpha)
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Transmission Weight"].default_value = transmission
    bsdf.inputs["IOR"].default_value = 1.45
    bsdf.inputs["Alpha"].default_value = alpha
    if emit:
        bsdf.inputs["Emission Color"].default_value = (*color, 1)
        bsdf.inputs["Emission Strength"].default_value = emit
    if alpha < 1:
        mat.surface_render_method = "DITHERED"
    M[name] = mat
    return mat


def texture_material(name, base, kind):
    mat = material(name, base, .48)
    n = 512
    y, x = np.mgrid[0:n, 0:n].astype(np.float32) / n
    rng = np.random.default_rng(51)
    if kind == "wood":
        grain = np.sin((x * 50 + .32 * np.sin(y * 13) + .12 * np.sin(y * 31)) * math.pi)
        grain += .24 * np.sin(x * 366 + y * 7)
        variation = .9 + .09 * grain + .02 * rng.random((n, n))
    else:
        veins = np.abs(np.sin(x * 12 + y * 8 + np.sin(x * 8 - y * 13) * 1.1))
        variation = .97 - .09 * np.exp(-veins * 18) + .025 * rng.random((n, n))
    rgba = np.ones((n, n, 4), dtype=np.float32)
    rgba[:, :, :3] = np.clip(np.array(base)[None, None, :] * variation[:, :, None], 0, 1)
    image = bpy.data.images.new(name + "_BaseColor", width=n, height=n)
    image.pixels.foreach_set(rgba.ravel())
    image.filepath_raw = str(TEXTURES / (name + ".png"))
    image.file_format = "PNG"
    image.save()
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    mat.node_tree.links.new(tex.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    return mat


def make_materials():
    texture_material("White_Travertine", (.87, .83, .73), "stone")
    texture_material("Pale_Marble", (.94, .93, .88), "stone")
    texture_material("Warm_Oak", (.57, .32, .14), "wood")
    material("White_Roof", (.94, .935, .9), .28)
    material("Brushed_Gold", (.73, .46, .13), .24, .82)
    material("Clear_Glass", (.91, .98, 1), .045, transmission=1)
    material("Pool_Water", (.055, .52, .65), .13, transmission=.5)
    material("Waterfall", (.18, .72, .88), .2, emit=.16, transmission=.42, alpha=.76)
    material("Linen_Ivory", (.8, .74, .62), .85)
    material("Cushion_Blue", (.19, .32, .45), .8)
    material("Rug_Sand", (.48, .4, .3), .95)
    material("Warm_Light", (1, .65, .29), .25, emit=3)
    material("Cyan_Starlight", (.12, .72, 1), .22, emit=3)
    material("Violet_Starlight", (.48, .22, 1), .22, emit=2.5)
    material("Light_Beam", (.28, .57, 1), .25, emit=1.5, alpha=.14)
    material("Meteor_Stone", (.22, .19, .29), .62)
    material("Meteor_Ember", (.4, .21, .1), .58)
    material("Pale_Cliff", (.63, .61, .53), .94)
    material("Lawn", (.13, .26, .07), .98)
    material("Leaves", (.09, .22, .055), .85)
    material("Leaf_Light", (.26, .72, .84), .65, emit=.65)
    material("Leaf_Violet", (.52, .31, .84), .65, emit=.65)
    material("Trunk", (.25, .14, .07), .9)
    material("Ceiling_Night", (.045, .075, .16), .62)


def finish(obj, name, mat, bevel=0):
    obj.name = name
    link(obj)
    obj.data.materials.append(M[mat])
    if bevel:
        modifier = obj.modifiers.new("Soft architectural edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier = obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
        modifier.keep_sharp = True
    return obj


def box(name, center, size, mat="White_Travertine", bevel=.06):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, min(bevel, min(size) * .22))


def cylinder(name, center, radius, height, mat="Brushed_Gold", vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=height, location=center)
    obj = finish(bpy.context.object, name, mat)
    for poly in obj.data.polygons:
        poly.use_smooth = len(poly.vertices) == 4
    return obj


def ico(name, center, radius, mat, scale=(1, 1, 1), subdivisions=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=radius, location=center)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat)


def rod(name, a, b, radius=.045, mat="Brushed_Gold", vertices=8):
    a, b = Vector(a), Vector(b)
    obj = cylinder(name, (a + b) * .5, radius, (b - a).length, mat, vertices)
    obj.rotation_euler = (b - a).to_track_quat("Z", "Y").to_euler()
    return obj


def path(name, points, radius=.045, mat="Brushed_Gold", closed=False):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth = radius
    curve.resolution_v = 0
    curve.bevel_resolution = 1
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for p, co in zip(spline.points, points):
        p.co = (*co, 1)
    spline.use_cyclic_u = closed
    obj = bpy.data.objects.new(name, curve)
    COL.objects.link(obj)
    obj.parent = HOUSE_ROOT
    curve.materials.append(M[mat])
    return obj


def ring(name, center, radius, tilt=(0, 0, 0), tube=.075, mat="Brushed_Gold"):
    from mathutils import Euler
    rotation = Euler(tilt).to_matrix()
    points = [Vector(center) + rotation @ Vector((radius * math.cos(a), radius * math.sin(a), 0))
              for a in np.linspace(0, math.tau, 97)[:-1]]
    return path(name, points, tube, mat, True)


def area(name, location, energy, size, color=(1, .76, .52), target=None):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    data.color = color
    obj = bpy.data.objects.new(name, data)
    COL.objects.link(obj)
    obj.parent = HOUSE_ROOT
    obj.location = location
    if target:
        obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    return obj


def frame_panel(name, x, y, z, width, height, axis="front", door=False):
    # Thin closed pane; independent mullions remain editable and survive FBX export.
    thickness = .035
    if axis == "front":
        box(name + "_Glass", (x, y, z + height / 2), (width, thickness, height), "Clear_Glass", 0)
        for u in (-width / 2, width / 2):
            box(name + "_Mullion", (x + u, y, z + height / 2), (.1, .16, height), "Brushed_Gold", .015)
        for v in (0, height):
            box(name + "_Rail", (x, y, z + v), (width + .12, .16, .1), "Brushed_Gold", .015)
        if door:
            rod("Entrance_Handle", (x + width * .35, y - .15, z + height * .4),
                (x + width * .35, y - .15, z + height * .62), .06)
    else:
        obj = frame_panel(name, 0, 0, z, width, height, "front", door)
        # For side panes construct directly to retain positions and parent coordinates.
        return obj


def side_glazing(name, x, y, z, depth, height):
    box(name + "_Glass", (x, y, z + height / 2), (.035, depth, height), "Clear_Glass", 0)
    for u in (-depth / 2, depth / 2):
        box(name + "_Mullion", (x, y + u, z + height / 2), (.16, .1, height), "Brushed_Gold", .015)
    for v in (0, height):
        box(name + "_Rail", (x, y, z + v), (.16, depth, .1), "Brushed_Gold", .015)


def wood_wall(name, x, y, z, width, height, side=False):
    size = (.28, width, height) if side else (width, .28, height)
    box(name, (x, y, z + height / 2), size, "Warm_Oak")
    # Large boards, restrained readable rhythm.
    count = int(width / .65)
    for i in range(count + 1):
        t = -width / 2 + width * i / max(count, 1)
        pos = (x + .17, y + t, z + height / 2) if side else (x + t, y - .17, z + height / 2)
        box(name + "_Batten", pos, (.07, .07, height), "Warm_Oak", .01)


def rail(name, a, b, z, height=2.3):
    a, b = Vector((*a, z)), Vector((*b, z))
    length = (b - a).length
    obj = box(name + "_Glass", (a + b) / 2 + Vector((0, 0, height / 2)),
              (length, .045, height), "Clear_Glass", 0)
    obj.rotation_euler.z = math.atan2(b.y - a.y, b.x - a.x)
    rod(name + "_Handrail", a + Vector((0, 0, height)), b + Vector((0, 0, height)), .05)
    for point in (a, b):
        rod(name + "_Post", point, point + Vector((0, 0, height)), .05)


def sofa(x, y, z, width=7, angle=0):
    parts = []
    parts.append(box("Sofa_Platform", (x, y, z + .5), (width, 2.7, .6), "Warm_Oak", .15))
    parts.append(box("Sofa_Back", (x, y + 1.1, z + 1.7), (width, .65, 2), "Linen_Ivory", .2))
    for s in (-1, 1):
        parts.append(box("Sofa_Arm", (x + s * (width / 2 - .22), y, z + 1.45), (.65, 2.7, 1.6), "Linen_Ivory", .2))
    for i in range(3):
        parts.append(box("Sofa_Seat", (x - width / 3 + i * width / 3, y - .1, z + 1.05),
                         (width / 3 - .15, 2, .65), "Linen_Ivory", .2))
    parts.append(box("Sofa_Cushion", (x - width * .28, y + .65, z + 1.85),
                     (1.15, .45, 1.25), "Cushion_Blue", .18))
    if angle:
        from mathutils import Matrix
        rot = Matrix.Rotation(angle, 3, "Z")
        for obj in parts:
            obj.location = Vector((x, y, z)) + rot @ (obj.location - Vector((x, y, z)))
            obj.rotation_euler.z += angle


def lamp(x, y, z):
    cylinder("Lamp_Foot", (x, y, z + .09), .55, .18)
    cylinder("Lamp_Stem", (x, y, z + 2.3), .055, 4.4)
    ico("Lamp_Glow", (x, y, z + 4.5), .65, "Warm_Light", subdivisions=2)


def meteor(x, y, z, size=1.25, color="Violet_Starlight", stand=True):
    if stand:
        cylinder("Meteor_Plinth", (x, y, z + .12), size * .95, .24, "Brushed_Gold", 24)
        cylinder("Meteor_Pedestal", (x, y, z + .95), size * .8, 1.6, "Pale_Marble", 24)
        cylinder("Meteor_Pedestal_Light", (x, y, z + 1.82), size * .86, .12, color, 24)
    center = Vector((x, y, z + 3.3))
    ico("Displayed_Meteor_Core", center, size * .83, color, subdivisions=2)
    body = ico("Displayed_Meteor", center, size, "Meteor_Stone", subdivisions=2)
    for vertex in body.data.vertices:
        vertex.co *= RNG.uniform(.91, 1.06)
    # Illuminated cracks represented as short inset facets instead of dense filigree.
    for i in range(7):
        a = i * 2.399
        co = center + Vector((math.cos(a) * size * .92, -size * .38, math.sin(a) * size * .9))
        ico("Meteor_Light_Facet", co, size * .12, color)
    ring("Meteor_Gold_Ring", center, size * 1.4, (math.radians(30), .3, .1), .035)


def constellation(center, width, plane="ceiling", glow=True):
    cx, cy, cz = center
    coords = [(-.42, .1), (-.2, -.25), (0, .18), (.2, .05), (.42, .3)]
    points = [(cx + a * width, cy + b * width, cz) if plane == "ceiling"
              else (cx + a * width, cy, cz + b * width) for a, b in coords]
    path("Constellation_Inlay", points, .035, "Brushed_Gold")
    for p in points:
        ico("Constellation_Star", p, .105, "Warm_Light" if glow else "Brushed_Gold")


def living_room(x, y, z, width, depth, height=9.2, featured=True):
    box("Living_Rug", (x - width * .14, y, z + .04), (width * .56, depth * .62, .06), "Rug_Sand", 0)
    sofa(x - width * .12, y + depth * .23, z, min(8.5, width * .55))
    cylinder("Coffee_Table", (x - width * .1, y - .4, z + .9), 1.65, .2, "Pale_Marble", 24)
    cylinder("Coffee_Table_Base", (x - width * .1, y - .4, z + .45), 1.15, .8, "Brushed_Gold", 16)
    lamp(x - width * .38, y + depth * .22, z)
    if featured:
        meteor(x + width * .28, y - depth * .12, z, min(1.45, width * .085))
    # Back bookcase and large warm niches.
    bx, by = x + width * .32, y + depth * .41
    for shelf_z in (1.3, 3.2, 5.1):
        box("Display_Shelf", (bx, by, z + shelf_z), (width * .24, 1, .15), "Warm_Oak")
    for i in range(5):
        box("Shelf_Book", (bx - 1.1 + i * .46, by, z + 3.7), (.24, .55, .85),
            "Linen_Ivory" if i % 2 else "Cushion_Blue", .02)
    ring("Ceiling_Star_Map_Frame", (x, y, z + height - .17), min(width, depth) * .31,
         tube=.045, mat="Warm_Light")
    constellation((x, y, z + height - .12), min(width, depth) * .55)
    area("Interior_Warm_Area", (x, y, z + height - .3), width * depth * 3.2, min(width, depth) * .7)


def kitchen(x, y, z, width=9):
    box("Kitchen_Cabinets", (x, y + 2, z + 1.6), (width, 2.4, 3.2), "Warm_Oak")
    box("Kitchen_Counter", (x, y + 2, z + 3.3), (width + .2, 2.6, .2), "Pale_Marble")
    box("Kitchen_Island", (x, y - 2, z + 1.6), (width * .7, 2.8, 3.2), "White_Travertine")
    box("Island_Counter", (x, y - 2, z + 3.3), (width * .7 + .3, 3.1, .2), "Pale_Marble")
    for i in (-1, 0, 1):
        cylinder("Bar_Stool_Seat", (x + i * 2, y - 4, z + 2.3), .65, .25, "Linen_Ivory")
        for dx in (-.35, .35):
            rod("Stool_Leg", (x + i * 2 + dx, y - 4, z), (x + i * 2 + dx, y - 4, z + 2.2), .05)
    rod("Kitchen_Tap", (x, y + 2, z + 3.4), (x, y + 2, z + 4.4), .06)
    rod("Kitchen_Tap_Head", (x, y + 2, z + 4.4), (x, y + 1.6, z + 4.4), .06)


def planter(x, y, z, size=2, luminous=False):
    box("Planter", (x, y, z + .65), (size, size, 1.3), "White_Travertine")
    ico("Garden_Foliage", (x, y, z + 1.55), size * .56, "Leaf_Light" if luminous else "Leaves", (1, 1, .8), 1)


def tree(x, y, z, height=7, luminous=False):
    planter(x, y, z, 2.8)
    rod("Tree_Trunk", (x, y, z + 1), (x, y, z + height * .7), .16, "Trunk")
    for i in range(6):
        a = i * 2.4
        end = Vector((x + math.cos(a) * height * .27, y + math.sin(a) * height * .27,
                      z + height * (.67 + .15 * (i % 2))))
        rod("Tree_Branch", (x, y, z + height * .4), end, .07, "Trunk")
        mat = ("Leaf_Light" if i % 2 else "Leaf_Violet") if luminous else "Leaves"
        ico("Tree_Canopy", end, height * .25, mat, (1, .85, .8), 1)


def garden_light(x, y, z):
    box("Garden_Light_Base", (x, y, z + .14), (.8, .8, .28), "Brushed_Gold")
    box("Garden_Light_Glow", (x, y, z + 1.05), (.48, .48, 1.65), "Warm_Light")
    box("Garden_Light_Cap", (x, y, z + 1.92), (.75, .75, .13), "Brushed_Gold")


def deck(x, y, z, width, depth):
    box("Deck_Foundation", (x, y, z - .19), (width, depth, .38), "White_Travertine")
    for i in range(max(1, int(depth / .7))):
        count = max(1, int(depth / .7))
        yy = y - depth / 2 + (i + .5) * depth / count
        box("Deck_Oak_Board", (x, yy, z + .035), (width - .2, depth / count - .035, .08), "Warm_Oak", .01)


def lounger(x, y, z):
    box("Lounger_Frame", (x, y, z + .55), (2.1, 5.2, .3), "Warm_Oak")
    box("Lounger_Cushion", (x, y - .4, z + .83), (1.9, 3.8, .4), "Linen_Ivory", .15)
    back = box("Lounger_Back", (x, y + 1.65, z + 1.3), (1.9, 1.8, .4), "Linen_Ivory", .15)
    back.rotation_euler.x = .5


def pool(x, y, z, width, depth, drop=0):
    box("Pool_Basin", (x, y, z - .8), (width + .7, depth + .7, 1.6), "White_Travertine")
    box("Pool_Interior", (x, y, z - .12), (width, depth, .15), "Cyan_Starlight", 0)
    box("Pool_Surface", (x, y, z + .08), (width, depth, .2), "Pool_Water", .01)
    # Restrained ripple highlights, the broad surface stays easy to read.
    for i in range(7):
        xx = x - width * .4 + i * width * .12
        path("Pool_Ripple", [(xx - .5, y - .15, z + .2), (xx, y, z + .2), (xx + .7, y + .13, z + .2)],
             .015, "Cyan_Starlight")
    if drop > 0:
        waterfall(x, y - depth / 2 - .12, z, width * .83, drop)


def waterfall(x, y, z, width, drop):
    # Low-poly undulating ribbon with closed side/back to export as a mesh.
    verts, faces = [], []
    columns, rows = 20, 8
    for j in range(rows + 1):
        for i in range(columns + 1):
            zz = z - drop * j / rows
            yy = y - .2 - .15 * math.sin(i * 2.1 + j * .7)
            verts.append((x - width / 2 + width * i / columns, yy, zz))
    for j in range(rows):
        for i in range(columns):
            k = j * (columns + 1) + i
            faces.append((k, k + 1, k + columns + 2, k + columns + 1))
    mesh = bpy.data.meshes.new("Waterfall_Ribbon")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Waterfall_Ribbon", mesh)
    COL.objects.link(obj)
    obj.parent = HOUSE_ROOT
    mesh.materials.append(M["Waterfall"])
    for i in range(12):
        xx = x - width * .48 + width * i / 11
        path("Waterfall_Streak", [(xx, y - .4, z), (xx + .08, y - .45, z - drop * .45),
                                  (xx - .05, y - .4, z - drop)], .025, "Cyan_Starlight")


def stairs(x, front_y, base_z, width, rise, run, glass=False, steps=10):
    for i in range(steps):
        y = front_y + (i + .5) * run / steps
        z = base_z + (i + .5) * rise / steps
        box("Glass_Entrance_Tread" if glass else "Entrance_Tread", (x, y, z),
            (width, run / steps + .05, .22 if glass else rise / steps),
            "Clear_Glass" if glass else "White_Travertine", .02)
        if glass:
            box("Glass_Stair_Gold_Nosing", (x, y - run / steps / 2, z + .13),
                (width, .07, .05), "Brushed_Gold", .01)
    for s in (-1, 1):
        a, b = (x + s * width / 2, front_y, base_z), (x + s * width / 2, front_y + run, base_z + rise)
        rod("Stair_Stringer", a, b, .1, "Brushed_Gold")
        rod("Stair_Handrail", Vector(a) + Vector((0, 0, 2.3)), Vector(b) + Vector((0, 0, 2.3)), .055)
        for t in (0, .5, 1):
            p = Vector(a).lerp(Vector(b), t)
            rod("Stair_Baluster", p, p + Vector((0, 0, 2.3)), .045)


def sign(x, y, z):
    obj = box("Sign", (x, y, z), (2.4, .16, .95), "Brushed_Gold")
    obj["roblox_role"] = "Owner nameplate; blank, front normal -Y"
    return obj


def pavilion(name, x, y, z, width, depth, height=9.2, roof=True, floor=True, glass_front=True):
    if floor:
        box(name + "_Floor", (x, y, z - .3), (width + 1.6, depth + 1.4, .6), "White_Travertine")
        box(name + "_Interior_Floor", (x, y, z + .025), (width - .3, depth - .3, .05), "Pale_Marble", 0)
    if roof:
        box(name + "_Roof", (x, y, z + height + .35), (width + 2.7, depth + 2.4, .7), "White_Roof")
        box(name + "_Roof_Warm_Strip", (x, y - depth / 2 - .3, z + height - .05),
            (width, .08, .06), "Warm_Light", .01)
    if glass_front:
        count = max(2, int(width / 5))
        for i in range(count):
            xx = x - width / 2 + (i + .5) * width / count
            frame_panel(name + "_Front", xx, y - depth / 2, z, width / count, height, door=i == count - 1)
    for s in (-1, 1):
        side_glazing(name + "_Side", x + s * width / 2, y, z, depth, height)
    wood_wall(name + "_Rear_Oak", x, y + depth / 2, z, width, height)
    for xx in (x - width / 2, x + width / 2):
        box(name + "_Corner", (xx, y, z + height / 2), (.3, .3, height), "Brushed_Gold")


def ground(width, depth, elevated=0):
    base = box("Base", (0, 0, -.5), (width, depth, 1), "White_Travertine", .16)
    base["roblox_role"] = "PrimaryPart; model pivot is floor center at (0,0,0)"
    for s in (-1, 1):
        box("Garden_Lawn", (s * (width / 2 - 2.4), 0, .08), (3, depth - 2.4, .16), "Lawn")
    if elevated:
        # Stylized faceted pale cliff restricted to building's own footprint.
        for i in range(20):
            a = i * math.tau / 20
            x = math.cos(a) * width * .43
            y = math.sin(a) * depth * .43
            ico("Pale_Cliff_Facet", (x, y, -elevated * .5), 3.4, "Pale_Cliff",
                (1.1, 1, elevated / 5.1), 1)
    return base


def terrace_rail(width, depth, z, center=(0, 0), front=True):
    x, y = center
    rail("Terrace_Side", (x - width / 2, y - depth / 2), (x - width / 2, y + depth / 2), z)
    rail("Terrace_Side", (x + width / 2, y - depth / 2), (x + width / 2, y + depth / 2), z)
    if front:
        rail("Terrace_Front", (x - width / 2, y - depth / 2), (x + width / 2, y - depth / 2), z)


def firepit(x, y, z):
    cylinder("Firepit_Stone", (x, y, z + .55), 1.45, 1.1, "White_Travertine", 24)
    cylinder("Firepit_Gold_Rim", (x, y, z + 1.13), 1.5, .12, "Brushed_Gold", 24)
    for i in range(7):
        a = i * 2.4
        ico("Firepit_Flame", (x + .55 * math.cos(a), y + .55 * math.sin(a), z + 1.5),
            .43, "Warm_Light", (.55, .55, 1.8))


def star_chandelier(x, y, roof_z, drop=5.5):
    ring("Star_Chandelier_Crown", (x, y, roof_z), 2.7, tube=.06)
    for i in range(17):
        a = i * 2.399
        radius = .8 + (i % 4) * .6
        end = (x + math.cos(a) * radius, y + math.sin(a) * radius,
               roof_z - drop * (.4 + (i % 5) * .15))
        rod("Star_Chandelier_Wire", (end[0], end[1], roof_z), end, .015)
        ico("Chandelier_Tiny_Star", end, .14 + (i % 2) * .06, "Warm_Light")


def glass_stair_link(x, y, base_z, target_z, width=3.2):
    stairs(x, y, base_z, width, target_z - base_z, 12, glass=True, steps=20)
    box("Glass_Bridge_Landing", (x, y + 13.5, target_z), (width, 3, .16), "Clear_Glass", 0)
    rail("Glass_Bridge", (x - width / 2, y + 12), (x - width / 2, y + 15), target_z)
    rail("Glass_Bridge", (x + width / 2, y + 12), (x + width / 2, y + 15), target_z)


def observatory(x, y, z, radius=5.2):
    cylinder("Observatory_Base", (x, y, z + .12), radius + .3, .24, "White_Travertine", 48)
    # Hemisphere, no hidden complete sphere below the roof.
    verts, faces = [], []
    segments, rows = 40, 12
    for j in range(rows + 1):
        phi = (j / rows) * math.pi / 2
        for i in range(segments):
            a = i * math.tau / segments
            verts.append((x + radius * math.cos(phi) * math.cos(a),
                          y + radius * math.cos(phi) * math.sin(a), z + radius * math.sin(phi)))
    for j in range(rows):
        for i in range(segments):
            ni = (i + 1) % segments
            faces.append((j * segments + i, j * segments + ni,
                          (j + 1) * segments + ni, (j + 1) * segments + i))
    mesh = bpy.data.meshes.new("Observatory_Glass")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(M["Clear_Glass"])
    obj = bpy.data.objects.new("Observatory_Glass", mesh)
    COL.objects.link(obj)
    obj.parent = HOUSE_ROOT
    for p in mesh.polygons:
        p.use_smooth = True
    for i in range(10):
        a = i * math.tau / 10
        points = [(x + radius * math.cos(phi) * math.cos(a),
                   y + radius * math.cos(phi) * math.sin(a), z + radius * math.sin(phi))
                  for phi in np.linspace(0, math.pi / 2, 20)]
        path("Observatory_Gold_Rib", points, .045)
    for k in (0, .38, .72):
        ring("Observatory_Latitude", (x, y, z + radius * k), radius * math.sqrt(1 - k * k), tube=.035)
    # A real, modeled telescope on a tripod.
    scope_a, scope_b = Vector((x, y, z + 2)), Vector((x - 2.4, y - 1.4, z + 3.4))
    rod("Observatory_Telescope", scope_a, scope_b, .42, "Brushed_Gold", 24)
    rod("Telescope_Lens", scope_b, scope_b + (scope_b - scope_a).normalized() * .1,
        .36, "Cyan_Starlight", 24)
    for i in range(3):
        a = i * math.tau / 3
        rod("Telescope_Tripod", (x + math.cos(a) * 1.4, y + math.sin(a) * 1.4, z + .2),
            scope_a, .065)


def house1():
    ground(29, 26)
    deck(0, -1, .6, 26, 23)
    pavilion("Starter", 0, 2, .7, 22, 16, 9.1)
    living_room(0, 2, .76, 19, 13, 8.9)
    sign(9, -6.15, 4.4)
    for s in (-1, 1):
        garden_light(s * 11.5, -11, .7)
        planter(s * 12.2, 4, .7, 2.3)
    stairs(7, -14, -.1, 5, .8, 2, steps=3)


def house2():
    ground(41, 36)
    deck(0, -3, .6, 35, 29)
    pavilion("Ground", 0, 2, .7, 31, 23, 9.3, roof=False)
    living_room(-7, 1, .76, 14, 17, 9.1)
    kitchen(9, 4, .76, 10)
    # Cantilevered oak upper box shifted over the entrance.
    upper_z = 10.8
    pavilion("Upper", 1.5, 2, upper_z, 30, 22, 9.3)
    wood_wall("Upper_Wood_Cladding", 16.7, 5, upper_z, 16, 9.3, side=True)
    living_room(2, 4, upper_z + .04, 23, 15, 9.1, featured=False)
    box("Upper_Terrace", (-5, -13, upper_z - .2), (22, 7, .5), "White_Roof")
    terrace_rail(22, 7, upper_z + .1, (-5, -13))
    for x in (-11, -5):
        lounger(x, -13, upper_z + .1)
    pool(-3, -13, .9, 23, 5.2)
    sign(13.6, -9.7, 4.5)
    stairs(14, -18, -.1, 5.5, .8, 3, steps=4)
    for s in (-1, 1):
        tree(s * 17.5, 10, .6, 5.5)
        garden_light(s * 16, -16, .6)


def house3():
    ground(56, 43)
    # Double-height central volume and two side wings. No mid slab through living room.
    pavilion("Double_Height_Atrium", -1, 2, .7, 22, 25, 19.5)
    living_room(-2, 1, .76, 19, 20, 19.2)
    star_chandelier(-2, 0, 19.8, 7.3)
    for i, x in enumerate((-18.5, 17.5)):
        pavilion("Lower_Wing", x, 3, .7, 12, 26, 9.3, roof=False)
        pavilion("Upper_Wing", x, 3, 10.7, 12, 26, 9.5)
        if i:
            kitchen(x, 4, .76, 9)
        else:
            living_room(x, 3, .76, 10, 19, 9.1, featured=False)
        living_room(x, 3, 10.76, 10, 19, 9.2, featured=False)
    # A pale stone wall with actual gold constellation geometry.
    box("Constellation_Stone_Wall", (-12.6, -11, 10.5), (4.2, .42, 19.5), "Pale_Marble")
    constellation((-12.6, -11.24, 12), 3.6, "wall")
    for k in range(4):
        ico("Wall_Constellation_Star", (-13.5 + (k % 2) * 1.5, -11.3, 4 + k * 3.6), .14, "Warm_Light")
    path("Wall_Constellation_Inlay", [(-13.5 + (k % 2) * 1.5, -11.29, 4 + k * 3.6) for k in range(4)], .045)
    roof_z = 20.9
    terrace_rail(49, 28, roof_z, (-.5, 3))
    firepit(-3, 2, roof_z)
    sofa(-3, 7, roof_z, 10)
    for x in (-20, 20):
        planter(x, 12, roof_z, 3)
    pool(-2, -16.8, 1, 44, 7.4, .85)
    sign(20.5, -10.35, 4.5)
    stairs(23.4, -21.5, -.15, 5, .85, 4, steps=5)
    for x in (-24, 24):
        garden_light(x, -18, .6)
        planter(x, 14, .6, 2.8)


def house4():
    ground(65, 49, elevated=11)
    for level in range(3):
        z = .7 + level * 10.5
        # Each floor shifts slightly, giving a distinct stacked cantilever silhouette.
        x = (level - 1) * 1.2
        y = level * 1.2 + 2
        pavilion("Level_%d" % (level + 1), x, y, z, 51, 32, 9.7)
        box("Cantilever_Terrace", (x, y - 4, z - .2), (57, 41, .55), "White_Roof")
        terrace_rail(57, 41, z + .1, (x, y - 4), front=level > 0)
        if level == 2:
            for i, color in enumerate(("Warm_Light", "Cyan_Starlight", "Violet_Starlight", "Cyan_Starlight")):
                meteor(-17 + i * 10, -4, z + .05, 1.8, color)
            sofa(0, 10, z + .05, 10)
            area("Trophy_Gallery_Light", (0, 0, z + 9.1), 3000, 22)
        else:
            living_room(-10, 2, z + .05, 23, 24, 9.4)
            kitchen(14, 5, z + .05, 13)
        for xx in (x - 25, x + 25):
            planter(xx, y - 17, z + .1, 2.7)
    roof_z = .7 + 2 * 10.5 + 10.4
    observatory(0, 5, roof_z, 6.7)
    terrace_rail(54, 34, roof_z + .1, (1.2, 4.4))
    for x in (-20, 20):
        lounger(x, 7, roof_z + .1)
        planter(x, -9, roof_z + .1, 3)
    pool(-6, -19.7, 1, 37, 7.3, 11.1)
    stairs(27.2, -22, -9.8, 5.5, 10.5, 16, steps=22)
    sign(23.2, -14.3, 4.8)
    for x in (-28, 29):
        tree(x, 14, .5, 6)


def house5():
    ground(74, 55)
    lower_z, upper_z = .7, 21.5
    pavilion("Lower_Glass_Pavilion", 0, 3, lower_z, 53, 33, 9.5)
    living_room(-10, 1, lower_z + .05, 25, 25, 9.2)
    kitchen(16, 6, lower_z + .05, 13)
    upper_before = set(COL.objects)
    pavilion("Floating_Upper_Pavilion", 0, 3, upper_z, 54, 34, 9.5)
    living_room(-9, 3, upper_z + .05, 25, 25, 9.2, featured=False)
    # Bedroom with simple editable upholstered geometry.
    box("Upper_Bed_Frame", (16, 3, upper_z + .55), (8, 10, 1.1), "Warm_Oak")
    box("Upper_Bed_Linen", (16, 3, upper_z + 1.25), (7.6, 9.5, .7), "Linen_Ivory", .22)
    for x in (14, 18):
        box("Bed_Pillow", (x, 6.5, upper_z + 1.8), (3, 1.8, .6), "Linen_Ivory", .2)
    sky_z = upper_z + 10.2
    box("Sky_Garden_Lawn", (0, 3, sky_z + .09), (50, 30, .18), "Lawn")
    terrace_rail(55, 35, sky_z + .1, (0, 3))
    for x in (-20, 20):
        for y in (-7, 13):
            tree(x, y, sky_z + .2, 7, luminous=True)
    deck(0, 3, sky_z + .2, 18, 16)
    sofa(0, 7, sky_z + .25, 9)
    firepit(0, 0, sky_z + .25)
    floating_parts = set(COL.objects) - upper_before
    floating = bpy.data.objects.new("Floating_Level_Control", None)
    COL.objects.link(floating)
    floating.parent = HOUSE_ROOT
    floating["feature"] = "Upper floor held by light; open gap 10.6 studs"
    for obj in floating_parts:
        obj.parent = floating
    # Light supports stay luminous and translucent, never solid architectural pillars.
    for x in (-23, 23):
        for y in (-10, 16):
            cylinder("Levitation_Light_Beam", (x, y, (10.9 + upper_z) / 2), .4,
                     upper_z - 10.9, "Light_Beam", 12)
            path("Levitation_Inner_Light", [(x, y, 10.9), (x, y, upper_z)], .045, "Violet_Starlight")
            ring("Levitation_Emitter", (x, y, 10.98), .8, tube=.05, mat="Cyan_Starlight")
    for x in (-30.5, 30.5):
        glass_stair_link(x, -13, .7, upper_z, 3.7)
    for i, (z, tilt) in enumerate(((15.2, (.16, -.2, .05)), (31.7, (-.15, .14, -.1)))):
        orbit = ring("Orbital_Gold_Ring_%d" % (i + 1), (0, 3, z), 40.5, tilt, .13)
        # Move geometry to its own origin before keyframing a complete orbit.
        for spline in orbit.data.splines:
            for point in spline.points:
                point.co.x -= 0
                point.co.y -= 3
                point.co.z -= z
        orbit.location = (0, 3, z)
        orbit.rotation_euler.z = 0
        orbit.keyframe_insert("rotation_euler", frame=1, index=2)
        orbit.rotation_euler.z = math.tau * (1 if i == 0 else -1)
        orbit.keyframe_insert("rotation_euler", frame=241, index=2)
        if orbit.animation_data:
            for fc in orbit.animation_data.action.fcurves:
                for k in fc.keyframe_points:
                    k.interpolation = "LINEAR"
        orbit.rotation_euler.z = 0
    for x in (-32, 32):
        tree(x, 18, .6, 6.2, luminous=True)
        garden_light(x, -20, .6)
    sign(22.5, -13.8, 4.9)
    stairs(0, -27.5, -.1, 10, .8, 4, steps=4)


def sweeping_roof(name, x, y, z, width, depth, lift=1.6):
    # Rounded rectangular perimeter with a gently rising swept edge.
    points = []
    r = min(3, depth * .15)
    for cx, cy, start in ((width / 2 - r, depth / 2 - r, 0),
                          (-width / 2 + r, depth / 2 - r, 90),
                          (-width / 2 + r, -depth / 2 + r, 180),
                          (width / 2 - r, -depth / 2 + r, 270)):
        for angle in np.linspace(start, start + 90, 7):
            a = math.radians(angle)
            xx, yy = cx + r * math.cos(a), cy + r * math.sin(a)
            zz = z + lift * (xx / (width / 2)) ** 2 + .25 * math.sin(yy * .2)
            points.append((x + xx, y + yy, zz))
    n = len(points)
    verts = points + [(a, b, c + .65) for a, b, c in points]
    faces = [tuple(reversed(range(n))), tuple(range(n, n * 2))]
    faces.extend((i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(M["White_Roof"])
    obj = bpy.data.objects.new(name, mesh)
    COL.objects.link(obj)
    obj.parent = HOUSE_ROOT
    path("Sweeping_Roof_Gold_Edge", [(a, b, c - .04) for a, b, c in points], .045,
         "Brushed_Gold", True)


def house6():
    ground(105, 77, elevated=4)
    # Ground datum .7, elevated entry/atrium floor 4.2.
    z = 4.2
    box("Grand_Foundation", (0, 4, 1.7), (96, 63, 4.4), "White_Travertine", .25)
    pavilion("Grand_Central_Atrium", 0, 4, z, 27, 35, 28, roof=False)
    living_room(0, 4, z + .05, 23, 28, 27.7)
    star_chandelier(0, 1, z + 27.5, 10)
    sweeping_roof("Atrium_Sweeping_Roof", 0, 4, z + 28.2, 32, 41, 1.9)
    # Four contemporary glass pavilions make an accessible continuous house.
    for i, x in enumerate((-31, 31)):
        for level in range(2):
            pz = z + level * 11
            pavilion("Mansion_Wing", x, 5, pz, 28, 36, 10.1, roof=False)
            box("Wing_Terrace", (x, 1, pz - .2), (32, 48, .6), "White_Roof")
            terrace_rail(32, 48, pz + .1, (x, 1), front=level > 0)
            if level == 0 and i:
                kitchen(x, 7, pz + .05, 18)
                sofa(x, -6, pz + .05, 10)
            else:
                living_room(x, 4, pz + .05, 23, 27, 9.9, featured=level == 0)
            if level == 1:
                for px in (x - 12, x + 12):
                    planter(px, -20, pz + .1, 2.5)
        sweeping_roof("Wing_Sweeping_Roof", x, 5, z + 21.5, 34, 43, 1.8)
        # Roof terrace garden on rear of each wing.
        for yy in (0, 15):
            tree(x, yy, z + 23, 5.5)
        waterfall(x, -23.2, z + 10.8, 12, 14.5)
        pool(x, -25.5, .4, 15, 4)
    # Readable exterior glass entrance steps; interior glass stairs lead to mezzanine.
    stairs(0, -37, -.25, 13, 4.5, 15, glass=True, steps=16)
    for s in (-1, 1):
        glass_stair_link(s * 10, 5, z + .1, z + 11, 3.2)
        garden_light(s * 9, -33, .8)
        garden_light(s * 43, -27, .8)
        tree(s * 44, 24, z, 7)
    sign(12.8, -13.7, z + 4)
    # Captured star in an open gold armillary, positioned above central atrium.
    center = (0, 4, z + 39)
    ico("Captured_Star", center, 3.4, "Cyan_Starlight", subdivisions=3)
    ico("Star_Inner_Light", center, 2.4, "Warm_Light", subdivisions=2)
    for i, tilt in enumerate(((0, .3, 0), (1.3, .1, .2), (.6, 1.1, .4))):
        ring("Gold_Armillary_%d" % (i + 1), center, 6.6 + i * .35, tilt, .13)
    for s in (-1, 1):
        rod("Armillary_Support", (s * 7, 4, z + 29.3), (s * 5.7, 4, z + 37), .13)
    for i in range(12):
        a = i * math.tau / 12
        direction = Vector((math.cos(a), math.sin(a) * .5, math.sin(a)))
        direction.normalize()
        rod("Captured_Star_Ray", Vector(center) + direction * 3.1,
            Vector(center) + direction * (4.2 + (i % 2) * .7), .045, "Warm_Light")


BUILDERS = [house1, house2, house3, house4, house5, house6]


def configure_render():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 40
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 8
    scene.cycles.transmission_bounces = 8
    scene.cycles.transparent_max_bounces = 12
    prefs = bpy.context.preferences.addons["cycles"].preferences
    try:
        prefs.compute_device_type = "OPTIX"
        prefs.get_devices()
        for device in prefs.devices:
            device.use = device.type == "OPTIX"
        if any(d.use for d in prefs.devices):
            scene.cycles.device = "GPU"
    except Exception as exc:
        print("GPU fallback:", exc, flush=True)
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.7, .79, 1, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .35
    scene.render.resolution_percentage = 100
    scene.render.image_settings.compression = 25
    scene.frame_start, scene.frame_end = 1, 240
    scene.frame_set(1)
    # Gentle glare is composited over alpha; background remains transparent.
    scene.use_nodes = True
    nt = scene.node_tree
    nt.nodes.clear()
    render = nt.nodes.new("CompositorNodeRLayers")
    glow = nt.nodes.new("CompositorNodeGlare")
    glow.glare_type = "FOG_GLOW"
    glow.threshold = 2
    glow.quality = "MEDIUM"
    glow.mix = -.93
    composite = nt.nodes.new("CompositorNodeComposite")
    nt.links.new(render.outputs["Image"], glow.inputs["Image"])
    nt.links.new(glow.outputs["Image"], composite.inputs["Image"])


def model_bounds(objects):
    points = [obj.matrix_world @ Vector(corner) for obj in objects
              if obj.type in {"MESH", "CURVE"} for corner in obj.bound_box]
    return (Vector(tuple(min(p[i] for p in points) for i in range(3))),
            Vector(tuple(max(p[i] for p in points) for i in range(3))))


def presentation(objects):
    global COL, HOUSE_ROOT
    old_col, old_root = COL, HOUSE_ROOT
    COL = bpy.data.collections.new("Presentation")
    bpy.context.scene.collection.children.link(COL)
    HOUSE_ROOT = None
    lo, hi = model_bounds(objects)
    span = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
    center = (lo + hi) / 2
    data = bpy.data.cameras.new("Hero_Camera")
    data.type = "ORTHO"
    data.lens = 50
    data.clip_start = .01
    data.clip_end = 10000
    camera = bpy.data.objects.new("Hero_Camera", data)
    COL.objects.link(camera)
    bpy.context.scene.camera = camera
    area("Studio_Key", center + Vector((span * .3, -span * .7, span * 1.1)),
         span * span * 48, span * .85, (1, .91, .8), center)
    area("Studio_Fill", center + Vector((-span, -span * .4, span * .5)),
         span * span * 27, span * .8, (.7, .83, 1), center)
    area("Studio_Rim", center + Vector((span * .3, span * .8, span)),
         span * span * 40, span * .7, (1, .84, .65), center)
    COL, HOUSE_ROOT = old_col, old_root
    return camera


def aim_camera(camera, objects, direction, resolution):
    bpy.context.view_layer.update()
    lo, hi = model_bounds(objects)
    center = (lo + hi) / 2
    span = (hi - lo).length
    camera.location = center + Vector(direction).normalized() * span * 2.5
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    inverse = camera.matrix_world.inverted()
    points = [inverse @ (obj.matrix_world @ Vector(c)) for obj in objects
              if obj.type in {"MESH", "CURVE"} for c in obj.bound_box]
    width = max(p.x for p in points) - min(p.x for p in points)
    height = max(p.y for p in points) - min(p.y for p in points)
    # ortho_scale spans the horizontal dimension in Blender landscape cameras.
    aspect = resolution[0] / resolution[1]
    camera.data.ortho_scale = max(width, height * aspect) * 1.11
    # Center on projected silhouette rather than just the axis-aligned box center.
    dx = (max(p.x for p in points) + min(p.x for p in points)) / 2
    dy = (max(p.y for p in points) + min(p.y for p in points)) / 2
    camera.location += camera.rotation_euler.to_matrix() @ Vector((dx, dy, 0))
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.camera = camera


def render_view(camera, objects, direction, resolution, filepath, samples=40):
    aim_camera(camera, objects, direction, resolution)
    bpy.context.scene.cycles.samples = samples
    bpy.context.scene.render.filepath = str(filepath)
    print("RENDER", filepath.name, flush=True)
    bpy.ops.render.render(write_still=True)


def reference_sheet(tier, camera, objects):
    outputs = []
    specs = [("hero", (.95, -1.9, .75), (1024, 1024)),
             ("front", (0, -1, .0001), (512, 342)),
             ("side", (1, 0, .0001), (512, 341)),
             ("top", (0, -.0001, 1), (512, 341))]
    canvas = np.zeros((1024, 1536, 4), dtype=np.float32)
    for i, (label, direction, resolution) in enumerate(specs):
        filename = RENDERS / ("House%d_%s.png" % (tier, label))
        render_view(camera, objects, direction, resolution, filename, samples=28)
        image = bpy.data.images.load(str(filename), check_existing=False)
        pixels = np.empty(resolution[0] * resolution[1] * 4, dtype=np.float32)
        image.pixels.foreach_get(pixels)
        pixels = pixels.reshape((resolution[1], resolution[0], 4))
        if i == 0:
            canvas[:, :1024, :] = pixels
        else:
            # Blender image buffers begin at bottom-left.
            y = {1: 682, 2: 341, 3: 0}[i]
            canvas[y:y + resolution[1], 1024:, :] = pixels
        bpy.data.images.remove(image)
        outputs.append(filename)
    sheet = bpy.data.images.new("House%d_Modeling_Sheet" % tier, width=1536, height=1024, alpha=True)
    sheet.pixels.foreach_set(canvas.ravel())
    sheet.filepath_raw = str(RENDERS / ("House%d_sheet.png" % tier))
    sheet.file_format = "PNG"
    sheet.save()
    bpy.data.images.remove(sheet)
    return outputs


def export_house(tier, source_objects):
    """Evaluate modifiers and batch by material, retaining Base and Sign separately.

    Each export mesh stays under 12k triangles. Editable .blend objects are untouched.
    UVs are copied to exports; shared color textures are real PNG files, not noise nodes.
    """
    scene = bpy.context.scene
    # Blender requires globally unique object names, including objects outside selection.
    # Temporarily free contract names so FBX/glTF contain Base/Sign, not Base.001/Sign.001.
    reserved = {"House%d" % tier, "Base", "Sign"}
    renamed = [(obj, obj.name) for obj in source_objects if obj.name in reserved]
    for obj, name in renamed:
        obj.name = name + "_Editable"
    temp = bpy.data.collections.new("EXPORT_TEMP")
    scene.collection.children.link(temp)
    root = bpy.data.objects.new("House%d" % tier, None)
    temp.objects.link(root)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    batches = {}
    for obj in source_objects:
        if obj.type not in {"MESH", "CURVE"}:
            continue
        mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph),
                                              preserve_all_data_layers=True, depsgraph=depsgraph)
        mesh.transform(obj.matrix_world)
        mesh.calc_loop_triangles()
        original_name = next((name for item, name in renamed if item == obj), obj.name)
        key = original_name if original_name in {"Base", "Sign"} else mesh.materials[0].name
        batches.setdefault(key, []).append(mesh)
    created, manifest_meshes = [], []
    for key, meshes in batches.items():
        chunk, count, number = [], 0, 0
        chunks = []
        for mesh in meshes:
            tri = len(mesh.loop_triangles)
            if chunk and count + tri > 12000:
                chunks.append(chunk)
                chunk, count = [], 0
            chunk.append(mesh)
            count += tri
        if chunk:
            chunks.append(chunk)
        for chunk in chunks:
            number += 1
            vertices, faces, uv_values, smooth = [], [], [], []
            material_ref = chunk[0].materials[0]
            for mesh in chunk:
                offset = len(vertices)
                vertices.extend(tuple(v.co) for v in mesh.vertices)
                uv = mesh.uv_layers.active
                for poly in mesh.polygons:
                    faces.append(tuple(offset + v for v in poly.vertices))
                    smooth.append(poly.use_smooth)
                    uv_values.extend(tuple(uv.data[l].uv) if uv else (0, 0) for l in poly.loop_indices)
            merged = bpy.data.meshes.new(key + "_Export")
            merged.from_pydata(vertices, [], faces)
            merged.materials.append(material_ref)
            merged.update()
            layer = merged.uv_layers.new(name="UVMap")
            for dst, src in zip(layer.data, uv_values):
                dst.uv = src
            for poly, value in zip(merged.polygons, smooth):
                poly.use_smooth = value
            name = key if key in {"Base", "Sign"} else "House%d_%s_%02d" % (tier, key, number)
            obj = bpy.data.objects.new(name, merged)
            temp.objects.link(obj)
            obj.parent = root
            obj["material_role"] = material_ref.name
            if key == "Sign":
                # BillboardGui attaches at the Part's position, not at offset vertices.
                # Keep the sign origin on the entrance plaque instead of at house center.
                from mathutils import Matrix
                source_sign = next(item for item, old_name in renamed if old_name == "Sign")
                position = source_sign.matrix_world.translation.copy()
                merged.transform(Matrix.Translation(-position))
                obj.location = position
                obj["roblox_role"] = "Owner nameplate"
            elif key == "Base":
                obj["roblox_role"] = "PrimaryPart"
            merged.calc_loop_triangles()
            manifest_meshes.append({"name": name, "triangles": len(merged.loop_triangles),
                                    "material": material_ref.name})
            created.append(obj)
        for mesh in meshes:
            bpy.data.meshes.remove(mesh)
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for obj in created:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    fbx_path = EXPORTS / ("House%d.fbx" % tier)
    bpy.ops.export_scene.fbx(filepath=str(fbx_path), use_selection=True,
                             object_types={"EMPTY", "MESH"}, axis_forward="Z", axis_up="Y",
                             global_scale=1, apply_unit_scale=False, add_leaf_bones=False,
                             bake_anim=False, path_mode="COPY", embed_textures=True,
                             mesh_smooth_type="FACE", use_custom_props=True)
    glb_path = EXPORTS / ("House%d.glb" % tier)
    bpy.ops.export_scene.gltf(filepath=str(glb_path), export_format="GLB", use_selection=True,
                              export_animations=False, export_yup=True, export_cameras=False,
                              export_lights=False, export_extras=True)
    for obj in list(temp.objects):
        data = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        if data and isinstance(data, bpy.types.Mesh):
            bpy.data.meshes.remove(data)
    bpy.data.collections.remove(temp)
    for obj, name in renamed:
        obj.name = name
    return {"fbx": str(fbx_path.relative_to(ROOT)), "glb": str(glb_path.relative_to(ROOT)),
            "export_meshes": len(manifest_meshes),
            "triangles": sum(m["triangles"] for m in manifest_meshes), "meshes": manifest_meshes}


def save_blend(filepath):
    # Pack the small shared PBR color maps so the .blend is portable.
    for screen in bpy.data.screens:
        for area_ui in screen.areas:
            if area_ui.type == "VIEW_3D":
                area_ui.spaces.active.region_3d.view_perspective = "CAMERA"
                area_ui.spaces.active.clip_end = 10000
                area_ui.spaces.active.shading.type = "MATERIAL"
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(filepath), compress=True)


def build_one(tier, render=True):
    global COL, HOUSE_ROOT, M, RNG
    print("BUILD_HOUSE", tier, NAMES[tier - 1], flush=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    M = {}
    RNG = random.Random(120 + tier)
    scene = bpy.context.scene
    scene.world = bpy.data.worlds.new("Soft_Daylight")
    scene.unit_settings.system = "NONE"
    scene["units"] = "1 Blender unit = 1 Roblox stud"
    scene["front"] = "Blender -Y; FBX axis_forward Z, axis_up Y"
    COL = bpy.data.collections.new("House%d" % tier)
    scene.collection.children.link(COL)
    HOUSE_ROOT = bpy.data.objects.new("House%d" % tier, None)
    COL.objects.link(HOUSE_ROOT)
    HOUSE_ROOT["tier"] = tier
    HOUSE_ROOT["evolution"] = NAMES[tier - 1]
    HOUSE_ROOT["primary_part"] = "Base"
    HOUSE_ROOT["concept"] = "art/concepts/houses/house%d.png" % tier
    make_materials()
    BUILDERS[tier - 1]()
    scene.frame_set(1)
    bpy.context.view_layer.update()
    objects = list(COL.objects)
    lo, hi = model_bounds(objects)
    radial = max(math.hypot((obj.matrix_world @ Vector(c)).x, (obj.matrix_world @ Vector(c)).y)
                 for obj in objects if obj.type in {"MESH", "CURVE"} for c in obj.bound_box)
    if radial > 100:
        raise ValueError("House exceeds 100 stud plot radius: %.2f" % radial)
    export_info = export_house(tier, objects)
    if any(m["triangles"] > 20000 for m in export_info["meshes"]):
        raise ValueError("Export mesh exceeds repository triangle limit")
    configure_render()
    camera = presentation(objects)
    if render:
        reference_sheet(tier, camera, objects)
        render_view(camera, objects, (.95, -1.9, .75), (1536, 1024),
                    RENDERS / ("House%d.png" % tier), 40)
    else:
        aim_camera(camera, objects, (.95, -1.9, .75), (1536, 1024))
    scene.cycles.samples = 40
    # Material preview and camera view are immediately useful when the file is opened.
    bpy.ops.object.select_all(action="DESELECT")
    base = next(obj for obj in COL.objects if obj.name == "Base")
    base.select_set(True)
    bpy.context.view_layer.objects.active = base
    for screen in bpy.data.screens:
        for area_ui in screen.areas:
            if area_ui.type == "VIEW_3D":
                area_ui.spaces.active.region_3d.view_perspective = "CAMERA"
                area_ui.spaces.active.clip_end = 10000
                area_ui.spaces.active.shading.type = "MATERIAL"
    blend = BLENDS / ("House%d.blend" % tier)
    save_blend(blend)
    info = {"tier": tier, "name": NAMES[tier - 1], "blend": str(blend.relative_to(ROOT)),
            "concept": "art/concepts/houses/house%d.png" % tier,
            "render": "art/renders/houses/House%d.png" % tier,
            "sheet": "art/renders/houses/House%d_sheet.png" % tier,
            "bounds_min": list(lo), "bounds_max": list(hi), "footprint_radius": radial,
            "editable_objects": len(objects), **export_info}
    (EXPORTS / ("House%d_manifest.json" % tier)).write_text(json.dumps(info, indent=2), encoding="utf-8")
    print("HOUSE_COMPLETE", tier, export_info["triangles"], "triangles", flush=True)
    return info


def overview(render=True):
    global COL, HOUSE_ROOT
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.world = bpy.data.worlds.new("Soft_Daylight")
    scene["units"] = "1 unit = 1 stud. Each house root is at floor-center; offsets are display only."
    all_objects = []
    right_edge = 0
    for tier in range(1, 7):
        with bpy.data.libraries.load(str(BLENDS / ("House%d.blend" % tier)), link=False) as (src, dst):
            dst.collections = ["House%d" % tier]
        collection = dst.collections[0]
        scene.collection.children.link(collection)
        root = next(obj for obj in collection.objects if obj.parent is None and obj.type == "EMPTY")
        bpy.context.view_layer.update()
        meshes = [obj for obj in collection.all_objects if obj.type in {"MESH", "CURVE"}]
        lo, hi = model_bounds(meshes)
        root.location.x = right_edge - lo.x
        right_edge += hi.x - lo.x + 14
        all_objects.extend(meshes)
    scene.frame_set(1)
    bpy.context.view_layer.update()
    configure_render()
    camera = presentation(all_objects)
    if render:
        render_view(camera, all_objects, (.12, -1.8, .95), (2400, 1200),
                    RENDERS / "Houses_Progression.png", 36)
    else:
        aim_camera(camera, all_objects, (.12, -1.8, .95), (2400, 1200))
    save_blend(BLENDS / "Houses_Collection.blend")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="+", type=int, choices=range(1, 7))
    parser.add_argument("--no-render", action="store_true")
    parser.add_argument("--overview-only", action="store_true")
    parser.add_argument("--export-only", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    if args.export_only:
        for tier in args.only or range(1, 7):
            bpy.ops.wm.open_mainfile(filepath=str(BLENDS / ("House%d.blend" % tier)))
            objects = list(bpy.data.collections["House%d" % tier].all_objects)
            info = export_house(tier, objects)
            path = EXPORTS / ("House%d_manifest.json" % tier)
            manifest = json.loads(path.read_text(encoding="utf-8"))
            manifest.update(info)
            path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        print("HOUSES_EXPORT_COMPLETE", flush=True)
        return
    if not args.overview_only:
        for tier in args.only or range(1, 7):
            build_one(tier, render=not args.no_render)
    if args.overview_only or not args.only:
        overview(render=not args.no_render)
    print("HOUSES_BUILD_COMPLETE", flush=True)


if __name__ == "__main__":
    main()

