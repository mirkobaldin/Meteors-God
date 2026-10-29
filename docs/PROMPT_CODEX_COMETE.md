# Prompt per Codex: immagini delle 25 comete

Incollalo in Codex nella cartella `Meteors-God` (dopo `git pull`). Genera 2 immagini per cometa (50 in tutto).

```
Read art/concepts/comets/comets.json: it lists 25 living meteors for the Roblox game "Meteor Gods"
(5 families x 5 rarities). For EVERY comet in that file generate TWO images and save them as PNG with a fully
transparent background, 1024x1024:
  art/concepts/comets/<id>_front.png   front view, the face looking straight at the camera
  art/concepts/comets/<id>_34.png      3/4 view from the left, same comet, same lighting
(<id> is the "id" field, e.g. inferno_common). Overwrite existing files with the same name.

BASE SHAPE (mandatory, identical for all 25): use the reference images art/reference/meteor_base_render.png
(front) and art/reference/meteor_base_render_34.png (3/4) as the exact base model. Keep EXACTLY:
- the silhouette: a slightly wide ball made of big chiselled rock plates packed together, thin glowing cracks
  between the plates where the inner core shows;
- the face: two thick curly stone eyebrows like Luffy Gear 5 (each one ends in a spiral above the nose and rises
  to a hooked tip on the outside), two deep carved angry eye holes glowing from inside, a wide carved mouth with
  two fangs on the top and two square teeth on the bottom, all glowing from the core behind;
- the camera angle and framing of the reference (the comet fills ~80% of the image, centered).
Do NOT redesign the shape, do NOT add a different face, do NOT change the eyebrows.

WHAT CHANGES per comet (from its "look" field): the rock material and color, the color of the glowing core and
cracks, and features that GROW OUT OF THE ROCK (spikes, crystals, ice, lava, horns made of stone, crests, vines,
orbiting rock shards). Rarity must be readable at a glance:
Common = the base shape with the family colors only; Rare = first growths; Epic = heavy armor or big features;
Legendary = a regal crest/crown grown from the rock, richer materials; Mythic = transformed and spectacular
(split shell, floating fragments, intense core). For "Galaxy Singularity" follow the style of
art/reference/meteor_supernova.png.

RULES: NO accessories of any kind (no hats, no glasses, no jewelry, no clothes); two eyes for every comet; no
text, no letters, no logos, no watermarks; no motion blur, no flames or particles flying away from the body
(only things attached to it or orbiting close), no background, no ground, no shadow plane. Art style: high-end
stylized 3D game asset (like the best Roblox showcase games), clean readable shapes, rich materials, soft studio
light, the same lighting for all 25 so they look like one collection.

When done: git add art/concepts/comets ; git commit -m "comet concepts" ; git pull --rebase ; git push.
```
