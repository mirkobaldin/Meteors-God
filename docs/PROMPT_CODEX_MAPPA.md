# Prompt per Codex: negozio, strutture, pezzi e props in DUE TEMI

Lista: `art/concepts/map/map_assets.json` (negozio, classifica, reattore, portale, forgia, piazza scambi, forziere,
statua, pedana, porta del ponte, piedistallo, leggio, lampione, 10 props). Basta bianco e oro: ogni elemento esce
in **due temi diversi**, poi scegli quello che ti piace e teniamo solo quello per tutta la mappa.

- **Tema A, "Sky Ruins"**: rovine di un antico tempio celeste che fluttua nel cielo: pietra arenaria calda e
  consumata, rame ossidato verde acqua, rune azzurre che brillano, muschio e piccole piante, pietre che fluttuano.
  Avventura, mistero, epico (tipo isole del cielo dei giochi d'avventura).
- **Tema B, "Starport"**: un porto spaziale futuristico: metallo blu notte e grafite, pannelli bianchi opachi, luci
  neon ciano e magenta, ologrammi, schermi, motori che brillano. Sci-fi pulito e colorato (tipo giochi spaziali
  cartoon di alto livello).

Prima prova: `ONLY = shop, launch_pad, star_lamp`. Poi `ONLY = all` con il tema scelto (`THEMES = A` oppure `B`).

```
ONLY = shop, launch_pad, star_lamp
THEMES = A, B

Read art/concepts/map/map_assets.json. For every item listed in ONLY (or every item if ONLY = all) and for every
theme in THEMES, generate TWO images, PNG with a fully transparent background, 1024x1024:
  art/concepts/map/<THEME>/<id>_34.png     3/4 view from above-left (about 30 degrees), like an isometric game asset
  art/concepts/map/<THEME>/<id>_front.png  front view
Overwrite files with the same name. The "look" field says WHAT the object is and what it does; restyle it fully in
the theme (keep its function and its parts, change materials, shapes and details). "size_studs" is its size in the
game (a player is 5.5 studs tall): doors, steps, counters and benches must be sized for a player.

GAME: "Meteor Gods" (Roblox): young gods on floating islands at the edge of the universe tame living comets and
throw them at giant planets. The map is islands floating in a purple nebula sky, linked by glowing bridges.

THEME A, "SKY RUINS": the ruins of an ancient celestial temple floating in the sky. Warm weathered sandstone
(#D9B98C) and darker stone (#8C7360), oxidized teal copper (#4FA3A0) for metal parts, glowing sky-blue runes
(#6FD8FF) carved in the stone, a little moss and small plants in the cracks, chunks of rock floating around the
bigger pieces. Chunky, carved, a bit broken, mysterious and epic. Not white, not gold.

THEME B, "STARPORT": a futuristic space port. Night-blue and graphite metal (#1E2440, #3A3F55), matte white
panels (#E8ECF2) only as accents, neon light strips in cyan (#33E5FF) and magenta (#FF4FD8), holographic
screens and signs (blank, no text), glowing engines and antennas, rounded industrial shapes. Clean, colorful,
high-tech. Not white-dominant, not gold.

RENDER (both themes): premium stylized 3D like the best Roblox showcase games: bold readable shapes, chunky
proportions, beveled edges, hand-painted PBR materials, soft studio light plus the object's own glowing lights,
gentle ambient occlusion. Same light and camera for every item of a theme so they look like one set. One single
object per image, complete and centered.

RULES: no text, no letters, no numbers, no logos, no watermarks (signs and screens stay blank); no people; no
background, no ground plane, no shadow plane (only the base the object itself has).

When done: git add art/concepts/map ; git commit -m "map concepts" ; git pull --rebase ; git push.
```
