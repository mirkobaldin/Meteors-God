# Prompt per Codex: le comete "Comet Beasts"

Prima prova: lascia `ONLY = pebble, magma, obsidian, phoenix, galaxy, grey_visitor` (una per rarità). Se ti
piacciono, rilancialo con `ONLY = all`.

```
ONLY = pebble, magma, obsidian, phoenix, galaxy, grey_visitor

Read art/concepts/comets/comets.json. For every comet listed in ONLY (or all if ONLY = all) generate TWO images, PNG with a
fully transparent background, 1024x1024:
  art/concepts/comets/<id>_34.png     3/4 side view: the head on the left looking at the camera, the whole tail
                                       streaming back and up to the right, nothing cut off
  art/concepts/comets/<id>_front.png  front view, face looking straight at the camera, the tail visible behind
Overwrite files with the same name.

GAME: "Meteor Gods" (Roblox). Young gods tame LIVING COMETS and hurl them at giant planets. The comets are the
stars of the game and the thing players collect, so they must look like the coolest creatures in a collectible
creature game: badass, powerful, full of personality. NOT cute, NOT a rock with a face.

THE CONCEPT, "COMET BEASTS": every comet is a creature made of two parts.
1) The HEAD: the comet's core, a chunky rounded head of rock/crystal/metal (see "look"), with the face CARVED
   into it and lit from inside: two fierce glowing eyes with vertical snake-slit pupils, heavy brow ridges
   always frowning, a wide mouth full of jagged teeth. Two eyes, always.
2) The TAIL: the comet's tail made SOLID and sculpted, streaming backwards like a mane or a cape (see "tail"):
   it gives the silhouette and the sense of speed even when standing still. It is attached to the head and part
   of the same object (it is not loose VFX). The tail is made of what the comet is made of (fire, ice, water,
   wind, crystal, smoke, metal...).
EVERY COMET HAS ITS OWN STYLE: use the "look" field; no two comets may look alike. "rarity" tells how
spectacular it is: Common = simple and charming, small; Rare = more details, stronger shapes; Epic = armor, horns,
striking materials; Legendary = regal and majestic, precious materials, a crest; Mythic = cosmic and
overwhelming, orbiting fragments, the core shining through; Extraterrestrial = clearly ALIEN (strange metal,
biomechanical shapes, otherworldly green light), unlike anything else in the game.

STYLE: premium stylized 3D creature render, like the legendary creatures of the best collectible creature games
and the best Roblox showcase games: bold readable silhouette that works even when tiny, chunky proportions
(big head, strong shapes), hand-painted PBR materials (rough rock, glossy crystal, molten emissive cracks), strong
rim light, soft studio lighting, saturated colors with clear contrast between the dark rock and the glowing
parts. Same lighting and camera for all.

RULES: no accessories (no hats, glasses, jewelry, clothes: horns, crests and spikes grow from the body); no text,
no letters, no logos, no watermarks; no background, no ground, no shadow plane; one creature per image,
centered, fully visible.

When done: git add art/concepts/comets ; git commit -m "comet concepts" ; git pull --rebase ; git push.
```
