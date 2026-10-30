# Prompt per Codex: le comete (roster v2)

Roster nuovo da zero (vedi `docs/COMETE_FAMIGLIE.md`). Ogni cometa ha un corpo e una faccia propri, e **nessuna scia**.
Prima prova con una per rarità: `ONLY = grumble, puffer, bastion, leviathan, eclipse, visitor`. Se ti piacciono,
rilancialo con `ONLY = all`.

```
ONLY = grumble, puffer, bastion, leviathan, eclipse, visitor

FORGET every comet image made before and do NOT use art/reference/meteor_base.png or any other reference image:
the old comets all had the same face and a trail, and both are wrong.

Read art/concepts/comets/comets.json. For every comet listed in ONLY (or all if ONLY = all) generate TWO images, PNG
with a fully transparent background, 1024x1024, overwriting files with the same name:
  art/concepts/comets/<id>_34.png     3/4 view, the creature looking at the camera
  art/concepts/comets/<id>_front.png  front view, face looking straight at the camera

GAME: "Meteor Gods" (Roblox). Young gods collect LIVING COMETS that rain from the sky, raise them, and hurl them at
giant planets to smash them. The comets are the collectibles of the game: each one is a little character with its own
personality, like the creatures of the best collectible creature games.

BODY: every comet is a COMPACT, ROUNDED creature (ball or egg shaped), something a god could throw like a
cannonball. Its features (horns, fins, spikes, crystals, ear tufts, folded wings, rings) grow from the body and stay
close to it, so the silhouette is still roughly round but instantly recognizable. Use the "look" field exactly.

NO TRAIL: absolutely no tail, trail, streak, motion lines, flames or smoke streaming behind, comet tail, speed lines
or particles. The creature is shown standing still.

FACE: use the "expression" field exactly; EVERY comet has a DIFFERENT face (eye shape, pupils, mouth, teeth,
mood). Do NOT give them the generic angry glowing eyes with a jagged-tooth grin unless the expression asks for it.
Always exactly two eyes. Eyes and mouth are part of the body (carved, grown, glowing from inside), never stuck-on
pieces. The expression must read clearly even when the image is small.

RARITY ("rarity" field) sets how spectacular it is: Common = simple, one main material, small and charming;
Rare = two materials, stronger shapes; Epic = armor, horns or striking materials, cool; Legendary = majestic,
precious materials, a crest or crown grown from the body; Mythic = cosmic and overwhelming, orbiting pieces, inner
light; Extraterrestrial = clearly ALIEN (strange metal, biomechanical, otherworldly green light), unlike anything else.

STYLE: premium stylized 3D render, like a high-end collectible toy or a top Roblox showcase game: chunky proportions,
bold readable silhouette, hand-painted PBR materials (real rock, real ice, glossy crystal, soft fur, slime), saturated
colors with strong contrast, soft studio light with a rim light. Same lighting, camera distance and size for every
comet, so they look like one set. Avoid washed-out colors and avoid making everything white and gold.

RULES: no accessories (no hats, glasses, jewelry, clothes); no text, letters, logos or watermarks; no background,
ground or shadow plane; one creature per image, centered, fully visible.

When done: git add art/concepts/comets ; git commit -m "comet concepts v2" ; git pull --rebase ; git push.
```
