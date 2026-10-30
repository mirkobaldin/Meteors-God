# Meteor base mesh (Blender 5.2, headless)

The base mesh is `../meteor_base.blend` / `../meteor_base.glb` (Rock 18k + Core 2k tris, diameter 1, face towards -Y).

- `render_compare.py` renders against the reference (clay overlay) or the final preview with the glowing core.
- `blender -b --factory-startup ../meteor_base.blend --python bake_meteor.py` - bakes the 200k sculpt into
  `../textures/meteor_rock_normal.png` + `meteor_rock_ao.png` (2048) on the 18k Rock (6 big UV islands, the whole
  face is one), keeps only Rock 18k + Core 2k (20k tris total) and re-exports `../meteor_base.glb`.

For Roblox: Rock and Core are two MeshParts; use the normal map in the Rock SurfaceAppearance
(Roblox downsizes textures to 1024).
