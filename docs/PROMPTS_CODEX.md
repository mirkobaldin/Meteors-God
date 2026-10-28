# Prompt per Codex — case dei giocatori e props

Codex fa **solo** le case dei giocatori e i props da spargere per la mappa (i meteoriti e le facce li facciamo in
Blender, la mappa e i pianeti sono generati dal codice). Ogni prompt è **autonomo**: incollane uno alla volta in Codex,
dentro la cartella `Meteors-God`. Le immagini finiscono in `art/concepts/`, **senza sfondo** (PNG trasparente).
Stile: **cazzuto ed epico**, non puccioso (ossidiana, pietra scura, oro brunito, rune luminose solo come accento).

Quando hai finito: `git add art` → `git commit -m "art"` → `git pull --rebase` → `git push`.

---

## 1. Case dei giocatori (6 livelli, una per Evoluzione)

La casa sta su un'isola di raggio 120 stud (ingombro massimo raggio 100), il fronte guarda verso il centro della mappa.

### 1.0 — Progressione dei 6 livelli
Salva in: `art/concepts/houses/00_progression.png`
```
Generate an image and save it to art/concepts/houses/00_progression.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Design sheet showing the evolution of a warrior god's HOUSE in 6 tiers from left to right, same camera angle, each one clearly bigger and more imposing than the previous one: tier 1 'Star Spirit': a small but proud shrine of black obsidian blocks with a burnished gold rim, a short heavy doorway and two glowing rune pillars at the entrance; tier 2 'Minor Deity': a fortified stone temple with thick sloped walls, a heavy bronze door, gold-capped corner buttresses and a rune-lit roof crest; tier 3 'Demigod': a temple-fortress with two tall angular towers flanking a massive gate, obsidian walls with gold bands, war banners of dark cloth; tier 4 'Titan': a dark citadel with a colossal statue of an armored god holding a meteor above the gate, heavy battlements, golden horns on the towers; tier 5 'Cosmic God': a floating dark citadel on its own chunk of rock, with two huge bronze rings orbiting around its central spire and chains anchoring it; tier 6 'Supreme Deity': a colossal obsidian palace with crown-shaped gold spires, a captured blazing star caged in a gold frame at its top, an imposing stair to the gate. Each tier is built from big bold shapes, heavy and intimidating.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 1.1 — Livello 1: Star Spirit
Salva in: `art/concepts/houses/house1.png`
```
Generate an image and save it to art/concepts/houses/house1.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Concept of a warrior god's HOUSE, tier 1 'Star Spirit': a small but proud shrine of black obsidian blocks with a burnished gold rim, a short heavy doorway and two glowing rune pillars at the entrance. Built from big bold shapes, heavy and intimidating, a spot on the front for the owner's name plate. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 1.2 — Livello 2: Minor Deity
Salva in: `art/concepts/houses/house2.png`
```
Generate an image and save it to art/concepts/houses/house2.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Concept of a warrior god's HOUSE, tier 2 'Minor Deity': a fortified stone temple with thick sloped walls, a heavy bronze door, gold-capped corner buttresses and a rune-lit roof crest. Built from big bold shapes, heavy and intimidating, a spot on the front for the owner's name plate. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 1.3 — Livello 3: Demigod
Salva in: `art/concepts/houses/house3.png`
```
Generate an image and save it to art/concepts/houses/house3.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Concept of a warrior god's HOUSE, tier 3 'Demigod': a temple-fortress with two tall angular towers flanking a massive gate, obsidian walls with gold bands, war banners of dark cloth. Built from big bold shapes, heavy and intimidating, a spot on the front for the owner's name plate. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 1.4 — Livello 4: Titan
Salva in: `art/concepts/houses/house4.png`
```
Generate an image and save it to art/concepts/houses/house4.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Concept of a warrior god's HOUSE, tier 4 'Titan': a dark citadel with a colossal statue of an armored god holding a meteor above the gate, heavy battlements, golden horns on the towers. Built from big bold shapes, heavy and intimidating, a spot on the front for the owner's name plate. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 1.5 — Livello 5: Cosmic God
Salva in: `art/concepts/houses/house5.png`
```
Generate an image and save it to art/concepts/houses/house5.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Concept of a warrior god's HOUSE, tier 5 'Cosmic God': a floating dark citadel on its own chunk of rock, with two huge bronze rings orbiting around its central spire and chains anchoring it. Built from big bold shapes, heavy and intimidating, a spot on the front for the owner's name plate. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 1.6 — Livello 6: Supreme Deity
Salva in: `art/concepts/houses/house6.png`
```
Generate an image and save it to art/concepts/houses/house6.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Concept of a warrior god's HOUSE, tier 6 'Supreme Deity': a colossal obsidian palace with crown-shaped gold spires, a captured blazing star caged in a gold frame at its top, an imposing stair to the gate. Built from big bold shapes, heavy and intimidating, a spot on the front for the owner's name plate. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

## 2. Props da spargere per la mappa

Oggetti singoli da mettere sulle isole, lungo i ponti e intorno ai pianeti per riempire il mondo.

### 2.1 — obelisk
Salva in: `art/concepts/props/obelisk.png`
```
Generate an image and save it to art/concepts/props/obelisk.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a tall black obsidian obelisk with a gold tip and a vertical line of glowing cyan runes. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.2 — ruined_pillars
Salva in: `art/concepts/props/ruined_pillars.png`
```
Generate an image and save it to art/concepts/props/ruined_pillars.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a group of three broken ancient stone pillars of different heights, cracked, with gold bands and fallen chunks at the base. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.3 — brazier
Salva in: `art/concepts/props/brazier.png`
```
Generate an image and save it to art/concepts/props/brazier.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a heavy bronze brazier on three clawed legs, holding a violet cosmic fire. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.4 — crystal_cluster
Salva in: `art/concepts/props/crystal_cluster.png`
```
Generate an image and save it to art/concepts/props/crystal_cluster.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a cluster of large sharp dark-violet crystals growing out of a rock, faint inner glow. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.5 — meteor_rock
Salva in: `art/concepts/props/meteor_rock.png`
```
Generate an image and save it to art/concepts/props/meteor_rock.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a half-buried smoking meteorite rock with glowing orange cracks inside a small scorched crater. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.6 — rune_stones
Salva in: `art/concepts/props/rune_stones.png`
```
Generate an image and save it to art/concepts/props/rune_stones.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a ring of five floating carved rune stones around a small stone base, runes glowing cyan. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.7 — warrior_statue
Salva in: `art/concepts/props/warrior_statue.png`
```
Generate an image and save it to art/concepts/props/warrior_statue.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a large statue of an armored warrior god in dark stone, holding a meteor raised above the head, gold trims. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.8 — gate_arch
Salva in: `art/concepts/props/gate_arch.png`
```
Generate an image and save it to art/concepts/props/gate_arch.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a massive ancient stone gate arch with gold inlays and two horn-shaped tips, broken on one side. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.9 — banner
Salva in: `art/concepts/props/banner.png`
```
Generate an image and save it to art/concepts/props/banner.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a tall war standard pole of bronze with a long dark-violet banner showing a gold meteor emblem (symbol only, no text). Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.10 — sword_in_rock
Salva in: `art/concepts/props/sword_in_rock.png`
```
Generate an image and save it to art/concepts/props/sword_in_rock.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a giant broken divine sword stuck into a boulder, blade of dark metal with glowing runes. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.11 — chained_meteor
Salva in: `art/concepts/props/chained_meteor.png`
```
Generate an image and save it to art/concepts/props/chained_meteor.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a captured meteor bound by thick gold chains to four stone posts, the meteor cracked and smoking. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.12 — star_anvil
Salva in: `art/concepts/props/star_anvil.png`
```
Generate an image and save it to art/concepts/props/star_anvil.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a star-forge anvil of black iron on a stone block, with a hammer leaning against it and sparks. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.13 — lantern_post
Salva in: `art/concepts/props/lantern_post.png`
```
Generate an image and save it to art/concepts/props/lantern_post.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a heavy stone lantern post with a caged blue flame, for lining the bridges. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.14 — observatory
Salva in: `art/concepts/props/observatory.png`
```
Generate an image and save it to art/concepts/props/observatory.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a bronze star-gazing telescope device on a rotating stone platform, pointing at the sky. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.15 — cosmic_tree
Salva in: `art/concepts/props/cosmic_tree.png`
```
Generate an image and save it to art/concepts/props/cosmic_tree.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a twisted dead tree with dark bark and small glowing star-fruits hanging from it. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.16 — weapon_rack
Salva in: `art/concepts/props/weapon_rack.png`
```
Generate an image and save it to art/concepts/props/weapon_rack.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Single environment PROP for the game: a rack of oversized divine weapons (spears, axes) of bronze and dark iron. Show a front 3/4 view and a side view on the same sheet.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

## 3. Strutture di gioco (da rifare in Blender al posto di quelle generate dal codice)

### 3.1 — fusion_reactor
Salva in: `art/concepts/structures/fusion_reactor.png`
```
Generate an image and save it to art/concepts/structures/fusion_reactor.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Game STRUCTURE: the FUSION REACTOR where 3 meteors are fused into a stronger one: a heavy round machine on a stone base, four dark iron pylons with glass tubes feeding a glass containment sphere with a raging violet energy core, two bronze rings orbiting the sphere. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.2 — hunt_portal
Salva in: `art/concepts/structures/hunt_portal.png`
```
Generate an image and save it to art/concepts/structures/hunt_portal.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Game STRUCTURE: the COSMIC HUNT PORTAL: a giant upright ring of burnished gold and obsidian segments on a stone base, a swirling violet rift inside the ring. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.3 — shop_stall
Salva in: `art/concepts/structures/shop_stall.png`
```
Generate an image and save it to art/concepts/structures/shop_stall.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Game STRUCTURE: the SHOP: a celestial market stall of dark stone and bronze with a heavy canopy, shelves of glowing meteor eggs and crystals. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.4 — leaderboard_monument
Salva in: `art/concepts/structures/leaderboard_monument.png`
```
Generate an image and save it to art/concepts/structures/leaderboard_monument.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Game STRUCTURE: the LEADERBOARD MONUMENT: a tall dark stone slab framed in gold with a blank glowing panel for names, two guardian statues at its sides. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.5 — launch_pad
Salva in: `art/concepts/structures/launch_pad.png`
```
Generate an image and save it to art/concepts/structures/launch_pad.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Game STRUCTURE: a LAUNCH PAD: a round stone platform with a glowing ring of runes and a bronze rim, where gods stand to hurl meteors. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.6 — bridge_gate
Salva in: `art/concepts/structures/bridge_gate.png`
```
Generate an image and save it to art/concepts/structures/bridge_gate.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are warrior gods at the edge of the universe who tame living meteors and hurl them at giant planets to shatter them. The world is floating islands of grass and dark rock in deep space, with bridges of dark cosmic glass.
Game STRUCTURE: a BRIDGE GATE: two tall angular gold-and-obsidian towers joined by a heavy beam, at the entrance of a glass bridge. Show an orthographic front view, side view and top view, ready to be modeled in Blender.
Art style: EPIC and TOUGH, not cute: stylized 3D game asset like the best Roblox showcase games, dark fantasy meets cosmic: heavy chunky shapes, sharp angular silhouettes, battle-worn divine architecture, black obsidian, dark weathered stone, burnished gold and bronze, small glowing cyan or violet runes as accents; NOT cartoon, NOT cuddly, NO pastel colors, NO big friendly shapes. Clear readable forms with moderate detail so it can be rebuilt in Blender with PBR materials. Neutral soft studio lighting. No text, no letters, no logos, no watermarks, no existing characters or brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO stars, NO nebula, NO floor shadow plane: fully transparent background, export as PNG.
```

