# Meteor base mesh pipeline (Blender 5.2, headless)

1. `blender -b --factory-startup --python meshy_input.py` - square front-view crop of `../meteor_base.png` -> `meshy_front.png`
2. `set MESHY_API_KEY=...` then `python meshy_generate.py` - Meshy image-to-3D (symmetric, raw, untextured) -> `meshy_meteor.glb`
3. `blender -b --factory-startup --python process_meshy.py` - cavity map: seams between rocks sink into strips,
   inner Core layer, eye openings traced from the reference, mouth interior cleared -> `meshy_processed.blend`
4. `blender -b --factory-startup meshy_processed.blend --python finalize_meshy.py` - diameter 1, UVs,
   Roblox copies (Rock 18k + Core 2k tris) -> `../meteor_base.blend` and `../meteor_base.glb`

`render_compare.py` renders against the reference (clay overlay) or the final preview with the glowing core.
Tuning lives at the top of `process_meshy.py` (STRIP_T0/T1, FACE_EXTRA, STRIP_DEPTH, CORE_DEPTH).
5. `blender -b --factory-startup ../meteor_base.blend --python bake_meteor.py` - bakes the 200k sculpt into
   `../textures/meteor_rock_normal.png` + `meteor_rock_ao.png` (2048) on the 18k Rock (6 big UV islands, the whole
   face is one), keeps only Rock 18k + Core 2k (20k tris total) and re-exports `../meteor_base.glb`.

For Roblox: Rock and Core are two MeshParts; use the normal map in the Rock SurfaceAppearance
(Roblox downsizes textures to 1024).
