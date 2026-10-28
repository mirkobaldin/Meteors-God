# Prompt per Codex — case, props e strutture

Codex fa **solo immagini di concept** per le case dei giocatori, i props da spargere e le strutture di gioco. Le comete le farà il Claude in Blender (gli mandi i prompt di `docs/PROMPTS_ART.md` solo dopo che approvi queste immagini); la mappa e i pianeti sono generati dal codice.

Ogni prompt è **autonomo**: incollane uno alla volta in Codex, dentro la cartella `Meteors-God`. Le immagini finiscono in `art/concepts/` **senza sfondo** (PNG trasparente).

**Stile nuovo:** case **moderne di lusso** (vetrate a tutta altezza da cui si vede l'arredamento dentro, legno chiaro, travertino, marmo chiaro, dettagli in oro spazzolato), adattate a delle divinità con un tocco celeste elegante e luminoso. **Niente ossidiana, niente castelli, niente spuntoni.** Props e strutture seguono lo stesso stile, così tutta la base sembra un resort di lusso nello spazio.

Se un'immagine esce ancora troppo scura o "da castello", rigenerala aggiungendo in fondo: `Make it brighter and more like a real modern villa with glass walls.`

Quando hai finito: `git add art` → `git commit -m "art"` → `git pull --rebase` → `git push`.

---

## 1. Case dei giocatori (6 livelli, una per Evoluzione)

Ogni casa sta su un'isola di raggio 120 stud (ingombro massimo raggio 100); il fronte vetrato guarda verso il centro della mappa.

### 1.0 — Progressione dei 6 livelli
Salva in: `art/concepts/houses/00_progression.png`
```
Generate an image and save it to art/concepts/houses/00_progression.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Design sheet showing the evolution of a god's HOUSE in 6 tiers from left to right, same camera angle (3/4 view), each one clearly bigger and more luxurious than the previous one: tier 1 'Star Spirit': a compact one-storey glass pavilion: one living room fully glazed on three sides, a flat white roof slab overhanging a small wooden deck, a slim gold door frame, a meteor on a lit pedestal visible inside, two low garden lights; tier 2 'Minor Deity': a two-storey modern house: glass ground floor with lounge and kitchen visible, a wood-clad upper box cantilevered over the entrance, a small terrace with loungers, a shallow reflecting pool at the front; tier 3 'Demigod': a large modern villa on two levels with a wide infinity pool, double-height glass living room with a chandelier of tiny stars, a stone wall with a gold constellation inlay, a roof terrace with a fire pit; tier 4 'Titan': a big cliffside luxury villa with three stacked cantilevered floors, glass all around, a glowing infinity pool that spills over the island edge, a private observatory dome of glass on the roof, a meteor trophy room visible behind the glass; tier 5 'Cosmic God': a spectacular villa whose upper floor floats a few meters above the lower one, held by light, with two thin gold rings slowly orbiting around it, glass bridges between the levels, a sky garden with luminous trees; tier 6 'Supreme Deity': a palace-scale modern mansion: several glass pavilions around a huge central atrium, sweeping white roofs, a waterfall from the terraces, a captured small star glowing in a gold armillary frame above the atrium, a grand glass staircase to the entrance. All of them share the same architectural language so they read as one family.
Art style: a MODERN LUXURY VILLA made for a god, high-end architecture render look adapted to a stylized Roblox game: floor-to-ceiling glass walls so you SEE THE FURNISHED INTERIOR from outside (sofas, warm lamps, a meteor displayed on a pedestal in the living room, a star map on the ceiling), cantilevered flat slabs and terraces, clean horizontal lines, warm light wood cladding, white travertine and pale marble, thin brushed-gold frames and trims, warm interior lighting; the divine touch is elegant and luminous: soft cyan/violet starlight details, constellation patterns etched in the glass, gold rings or small floating rock pieces, never gothic. Bright, warm and aspirational, the kind of house every player wants to own. Clean readable shapes with moderate detail so it can be rebuilt in Blender with PBR materials (glass, wood, stone, metal). NOT a castle, NOT a fortress, NOT a temple, NO obsidian, NO black stone, NO spikes, NO horns, NO skulls, NO dark fantasy, NO towers. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO sky, NO scenery around it (only its own small garden/terrace footprint), fully transparent background, export as PNG.
```

### 1.1 — Livello 1: Star Spirit
Salva in: `art/concepts/houses/house1.png`
```
Generate an image and save it to art/concepts/houses/house1.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a god's HOUSE, tier 1 'Star Spirit': a compact one-storey glass pavilion: one living room fully glazed on three sides, a flat white roof slab overhanging a small wooden deck, a slim gold door frame, a meteor on a lit pedestal visible inside, two low garden lights. The front is mostly glass and faces the viewer so the furnished, warmly lit interior is clearly visible; a spot near the entrance for the owner's name plate. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: a MODERN LUXURY VILLA made for a god, high-end architecture render look adapted to a stylized Roblox game: floor-to-ceiling glass walls so you SEE THE FURNISHED INTERIOR from outside (sofas, warm lamps, a meteor displayed on a pedestal in the living room, a star map on the ceiling), cantilevered flat slabs and terraces, clean horizontal lines, warm light wood cladding, white travertine and pale marble, thin brushed-gold frames and trims, warm interior lighting; the divine touch is elegant and luminous: soft cyan/violet starlight details, constellation patterns etched in the glass, gold rings or small floating rock pieces, never gothic. Bright, warm and aspirational, the kind of house every player wants to own. Clean readable shapes with moderate detail so it can be rebuilt in Blender with PBR materials (glass, wood, stone, metal). NOT a castle, NOT a fortress, NOT a temple, NO obsidian, NO black stone, NO spikes, NO horns, NO skulls, NO dark fantasy, NO towers. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO sky, NO scenery around it (only its own small garden/terrace footprint), fully transparent background, export as PNG.
```

### 1.2 — Livello 2: Minor Deity
Salva in: `art/concepts/houses/house2.png`
```
Generate an image and save it to art/concepts/houses/house2.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a god's HOUSE, tier 2 'Minor Deity': a two-storey modern house: glass ground floor with lounge and kitchen visible, a wood-clad upper box cantilevered over the entrance, a small terrace with loungers, a shallow reflecting pool at the front. The front is mostly glass and faces the viewer so the furnished, warmly lit interior is clearly visible; a spot near the entrance for the owner's name plate. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: a MODERN LUXURY VILLA made for a god, high-end architecture render look adapted to a stylized Roblox game: floor-to-ceiling glass walls so you SEE THE FURNISHED INTERIOR from outside (sofas, warm lamps, a meteor displayed on a pedestal in the living room, a star map on the ceiling), cantilevered flat slabs and terraces, clean horizontal lines, warm light wood cladding, white travertine and pale marble, thin brushed-gold frames and trims, warm interior lighting; the divine touch is elegant and luminous: soft cyan/violet starlight details, constellation patterns etched in the glass, gold rings or small floating rock pieces, never gothic. Bright, warm and aspirational, the kind of house every player wants to own. Clean readable shapes with moderate detail so it can be rebuilt in Blender with PBR materials (glass, wood, stone, metal). NOT a castle, NOT a fortress, NOT a temple, NO obsidian, NO black stone, NO spikes, NO horns, NO skulls, NO dark fantasy, NO towers. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO sky, NO scenery around it (only its own small garden/terrace footprint), fully transparent background, export as PNG.
```

### 1.3 — Livello 3: Demigod
Salva in: `art/concepts/houses/house3.png`
```
Generate an image and save it to art/concepts/houses/house3.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a god's HOUSE, tier 3 'Demigod': a large modern villa on two levels with a wide infinity pool, double-height glass living room with a chandelier of tiny stars, a stone wall with a gold constellation inlay, a roof terrace with a fire pit. The front is mostly glass and faces the viewer so the furnished, warmly lit interior is clearly visible; a spot near the entrance for the owner's name plate. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: a MODERN LUXURY VILLA made for a god, high-end architecture render look adapted to a stylized Roblox game: floor-to-ceiling glass walls so you SEE THE FURNISHED INTERIOR from outside (sofas, warm lamps, a meteor displayed on a pedestal in the living room, a star map on the ceiling), cantilevered flat slabs and terraces, clean horizontal lines, warm light wood cladding, white travertine and pale marble, thin brushed-gold frames and trims, warm interior lighting; the divine touch is elegant and luminous: soft cyan/violet starlight details, constellation patterns etched in the glass, gold rings or small floating rock pieces, never gothic. Bright, warm and aspirational, the kind of house every player wants to own. Clean readable shapes with moderate detail so it can be rebuilt in Blender with PBR materials (glass, wood, stone, metal). NOT a castle, NOT a fortress, NOT a temple, NO obsidian, NO black stone, NO spikes, NO horns, NO skulls, NO dark fantasy, NO towers. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO sky, NO scenery around it (only its own small garden/terrace footprint), fully transparent background, export as PNG.
```

### 1.4 — Livello 4: Titan
Salva in: `art/concepts/houses/house4.png`
```
Generate an image and save it to art/concepts/houses/house4.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a god's HOUSE, tier 4 'Titan': a big cliffside luxury villa with three stacked cantilevered floors, glass all around, a glowing infinity pool that spills over the island edge, a private observatory dome of glass on the roof, a meteor trophy room visible behind the glass. The front is mostly glass and faces the viewer so the furnished, warmly lit interior is clearly visible; a spot near the entrance for the owner's name plate. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: a MODERN LUXURY VILLA made for a god, high-end architecture render look adapted to a stylized Roblox game: floor-to-ceiling glass walls so you SEE THE FURNISHED INTERIOR from outside (sofas, warm lamps, a meteor displayed on a pedestal in the living room, a star map on the ceiling), cantilevered flat slabs and terraces, clean horizontal lines, warm light wood cladding, white travertine and pale marble, thin brushed-gold frames and trims, warm interior lighting; the divine touch is elegant and luminous: soft cyan/violet starlight details, constellation patterns etched in the glass, gold rings or small floating rock pieces, never gothic. Bright, warm and aspirational, the kind of house every player wants to own. Clean readable shapes with moderate detail so it can be rebuilt in Blender with PBR materials (glass, wood, stone, metal). NOT a castle, NOT a fortress, NOT a temple, NO obsidian, NO black stone, NO spikes, NO horns, NO skulls, NO dark fantasy, NO towers. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO sky, NO scenery around it (only its own small garden/terrace footprint), fully transparent background, export as PNG.
```

### 1.5 — Livello 5: Cosmic God
Salva in: `art/concepts/houses/house5.png`
```
Generate an image and save it to art/concepts/houses/house5.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a god's HOUSE, tier 5 'Cosmic God': a spectacular villa whose upper floor floats a few meters above the lower one, held by light, with two thin gold rings slowly orbiting around it, glass bridges between the levels, a sky garden with luminous trees. The front is mostly glass and faces the viewer so the furnished, warmly lit interior is clearly visible; a spot near the entrance for the owner's name plate. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: a MODERN LUXURY VILLA made for a god, high-end architecture render look adapted to a stylized Roblox game: floor-to-ceiling glass walls so you SEE THE FURNISHED INTERIOR from outside (sofas, warm lamps, a meteor displayed on a pedestal in the living room, a star map on the ceiling), cantilevered flat slabs and terraces, clean horizontal lines, warm light wood cladding, white travertine and pale marble, thin brushed-gold frames and trims, warm interior lighting; the divine touch is elegant and luminous: soft cyan/violet starlight details, constellation patterns etched in the glass, gold rings or small floating rock pieces, never gothic. Bright, warm and aspirational, the kind of house every player wants to own. Clean readable shapes with moderate detail so it can be rebuilt in Blender with PBR materials (glass, wood, stone, metal). NOT a castle, NOT a fortress, NOT a temple, NO obsidian, NO black stone, NO spikes, NO horns, NO skulls, NO dark fantasy, NO towers. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO sky, NO scenery around it (only its own small garden/terrace footprint), fully transparent background, export as PNG.
```

### 1.6 — Livello 6: Supreme Deity
Salva in: `art/concepts/houses/house6.png`
```
Generate an image and save it to art/concepts/houses/house6.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a god's HOUSE, tier 6 'Supreme Deity': a palace-scale modern mansion: several glass pavilions around a huge central atrium, sweeping white roofs, a waterfall from the terraces, a captured small star glowing in a gold armillary frame above the atrium, a grand glass staircase to the entrance. The front is mostly glass and faces the viewer so the furnished, warmly lit interior is clearly visible; a spot near the entrance for the owner's name plate. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: a MODERN LUXURY VILLA made for a god, high-end architecture render look adapted to a stylized Roblox game: floor-to-ceiling glass walls so you SEE THE FURNISHED INTERIOR from outside (sofas, warm lamps, a meteor displayed on a pedestal in the living room, a star map on the ceiling), cantilevered flat slabs and terraces, clean horizontal lines, warm light wood cladding, white travertine and pale marble, thin brushed-gold frames and trims, warm interior lighting; the divine touch is elegant and luminous: soft cyan/violet starlight details, constellation patterns etched in the glass, gold rings or small floating rock pieces, never gothic. Bright, warm and aspirational, the kind of house every player wants to own. Clean readable shapes with moderate detail so it can be rebuilt in Blender with PBR materials (glass, wood, stone, metal). NOT a castle, NOT a fortress, NOT a temple, NO obsidian, NO black stone, NO spikes, NO horns, NO skulls, NO dark fantasy, NO towers. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO sky, NO scenery around it (only its own small garden/terrace footprint), fully transparent background, export as PNG.
```

## 2. Props da spargere per la mappa

Oggetti da mettere nei giardini delle case, sull'isola centrale e lungo i ponti.

### 2.1 — star_lamp
Salva in: `art/concepts/props/star_lamp.png`
```
Generate an image and save it to art/concepts/props/star_lamp.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a slim garden lamp post in brushed gold with a frosted glass orb holding a tiny star. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.2 — meteor_sculpture
Salva in: `art/concepts/props/meteor_sculpture.png`
```
Generate an image and save it to art/concepts/props/meteor_sculpture.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a rough glowing meteor fragment displayed on a white marble plinth with a gold ring around it. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.3 — glass_gazebo
Salva in: `art/concepts/props/glass_gazebo.png`
```
Generate an image and save it to art/concepts/props/glass_gazebo.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a small round gazebo with a thin white roof disk, glass panels and two wooden benches inside. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.4 — reflecting_pool
Salva in: `art/concepts/props/reflecting_pool.png`
```
Generate an image and save it to art/concepts/props/reflecting_pool.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a rectangular shallow reflecting pool in travertine with stepping stones and soft underwater light. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.5 — armillary_sphere
Salva in: `art/concepts/props/armillary_sphere.png`
```
Generate an image and save it to art/concepts/props/armillary_sphere.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a large gold armillary sphere on a marble base, with a small glowing planet in the middle. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.6 — crystal_planter
Salva in: `art/concepts/props/crystal_planter.png`
```
Generate an image and save it to art/concepts/props/crystal_planter.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a white stone planter with luminous cosmic plants and small cyan crystals. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.7 — lounge_set
Salva in: `art/concepts/props/lounge_set.png`
```
Generate an image and save it to art/concepts/props/lounge_set.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: two modern wooden sun loungers with white cushions and a small glass side table. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.8 — fire_pit
Salva in: `art/concepts/props/fire_pit.png`
```
Generate an image and save it to art/concepts/props/fire_pit.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a round travertine fire pit with violet-blue cosmic flames and a curved wooden bench. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.9 — telescope_deck
Salva in: `art/concepts/props/telescope_deck.png`
```
Generate an image and save it to art/concepts/props/telescope_deck.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a small wooden deck with a big elegant brass and white telescope pointing at the sky. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.10 — floating_stones
Salva in: `art/concepts/props/floating_stones.png`
```
Generate an image and save it to art/concepts/props/floating_stones.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a path of five flat white stepping stones floating at different heights with soft glow under them. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.11 — cosmic_tree
Salva in: `art/concepts/props/cosmic_tree.png`
```
Generate an image and save it to art/concepts/props/cosmic_tree.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a sculptural tree with a pale trunk and canopy of soft glowing violet leaves, in a round stone bed. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.12 — pergola
Salva in: `art/concepts/props/pergola.png`
```
Generate an image and save it to art/concepts/props/pergola.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a modern wooden pergola with thin gold beams and hanging warm lights over an outdoor dining table. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.13 — name_pillar
Salva in: `art/concepts/props/name_pillar.png`
```
Generate an image and save it to art/concepts/props/name_pillar.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: an elegant entrance pillar of pale marble with a gold frame for a name plate and a small light on top. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.14 — water_fountain
Salva in: `art/concepts/props/water_fountain.png`
```
Generate an image and save it to art/concepts/props/water_fountain.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a minimalist fountain: a stack of three offset marble slabs with water falling between them. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.15 — god_statue
Salva in: `art/concepts/props/god_statue.png`
```
Generate an image and save it to art/concepts/props/god_statue.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a modern white marble statue of a young god throwing a meteor, smooth stylized forms, on a gold base. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 2.16 — bridge_lamps
Salva in: `art/concepts/props/bridge_lamps.png`
```
Generate an image and save it to art/concepts/props/bridge_lamps.png (1024x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a decorative PROP for the islands: a pair of tall slim light pylons in glass and gold to place along the cosmic glass bridges. Show a 3/4 view, plus a small front and top view.
Art style: same world as the gods' modern villas: elegant "celestial modern" design, white travertine and pale marble, warm light wood, brushed gold, clear and frosted glass, warm lights and small soft cyan/violet starlight accents; bright, premium and clean like a luxury resort in space, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

## 3. Strutture di gioco (da rifare in Blender al posto di quelle generate dal codice)

### 3.1 — fusion_reactor
Salva in: `art/concepts/structures/fusion_reactor.png`
```
Generate an image and save it to art/concepts/structures/fusion_reactor.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a gameplay STRUCTURE: the FUSION REACTOR where players fuse 3 meteors into a rarer one: a circular white marble platform with three glass capsules holding meteors, curved gold arms meeting above a central glass sphere full of swirling cyan-violet energy, thin light conduits running on the floor. Big and readable from far away, a landmark of the base. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: "divine high-tech": the elegance of a modern luxury villa and a sci-fi research center built for gods: white marble and travertine, large glass surfaces, brushed gold and chrome, glowing cyan/violet energy, clean curves and strong horizontal lines, bright and premium, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.2 — hunt_portal
Salva in: `art/concepts/structures/hunt_portal.png`
```
Generate an image and save it to art/concepts/structures/hunt_portal.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a gameplay STRUCTURE: the COSMIC HUNT PORTAL that sends players into deep space: a tall elegant ring of white stone and gold standing on a stepped marble base, its inside a swirling blue "quantum" vortex, floating ring segments around it. Big and readable from far away, a landmark of the base. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: "divine high-tech": the elegance of a modern luxury villa and a sci-fi research center built for gods: white marble and travertine, large glass surfaces, brushed gold and chrome, glowing cyan/violet energy, clean curves and strong horizontal lines, bright and premium, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.3 — shop_stall
Salva in: `art/concepts/structures/shop_stall.png`
```
Generate an image and save it to art/concepts/structures/shop_stall.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a gameplay STRUCTURE: the DIVINE SHOP: a modern glass boutique pavilion with a curved white roof, illuminated display shelves with meteors and potions visible through the glass, a gold-framed entrance. Big and readable from far away, a landmark of the base. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: "divine high-tech": the elegance of a modern luxury villa and a sci-fi research center built for gods: white marble and travertine, large glass surfaces, brushed gold and chrome, glowing cyan/violet energy, clean curves and strong horizontal lines, bright and premium, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.4 — leaderboard_monument
Salva in: `art/concepts/structures/leaderboard_monument.png`
```
Generate an image and save it to art/concepts/structures/leaderboard_monument.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a gameplay STRUCTURE: the LEADERBOARD: a tall monolith of white marble with a huge glass screen panel framed in gold, three podium steps in front, small floating planets orbiting the top. Big and readable from far away, a landmark of the base. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: "divine high-tech": the elegance of a modern luxury villa and a sci-fi research center built for gods: white marble and travertine, large glass surfaces, brushed gold and chrome, glowing cyan/violet energy, clean curves and strong horizontal lines, bright and premium, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.5 — launch_pad
Salva in: `art/concepts/structures/launch_pad.png`
```
Generate an image and save it to art/concepts/structures/launch_pad.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a gameplay STRUCTURE: a LAUNCH PAD at the end of a bridge where a god levitates to throw a meteor: a round floating platform of white stone with a glowing cyan ring inlaid in the floor, a thin gold railing on the back half, energy rising softly. Big and readable from far away, a landmark of the base. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: "divine high-tech": the elegance of a modern luxury villa and a sci-fi research center built for gods: white marble and travertine, large glass surfaces, brushed gold and chrome, glowing cyan/violet energy, clean curves and strong horizontal lines, bright and premium, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```

### 3.6 — bridge_gate
Salva in: `art/concepts/structures/bridge_gate.png`
```
Generate an image and save it to art/concepts/structures/bridge_gate.png (1536x1024).
Game: "Meteor Gods" (Roblox). Players are young gods living on floating islands at the edge of the universe: they tame living meteors and hurl them at giant planets. The islands are green lawns, light rock cliffs and bridges of glowing cosmic glass, under a purple nebula sky.
Concept of a gameplay STRUCTURE: the GATE at the start of a cosmic glass bridge: two slender white pylons with gold inlays joined by a floating glass arch with a glowing constellation, light strips leading onto the bridge. Big and readable from far away, a landmark of the base. Show a 3/4 hero view big on the left, plus small orthographic front, side and top views on the right, ready to be modeled in Blender.
Art style: "divine high-tech": the elegance of a modern luxury villa and a sci-fi research center built for gods: white marble and travertine, large glass surfaces, brushed gold and chrome, glowing cyan/violet energy, clean curves and strong horizontal lines, bright and premium, stylized for a Roblox game with clear readable shapes and moderate detail, easy to rebuild in Blender with PBR materials. NO obsidian, NO black stone, NO spikes, NO gothic, NO dark fantasy, NOT cartoon-cute. Soft daylight. No text, no letters, no logos, no watermarks, no existing brands. IMPORTANT: isolated subject only, NO background, NO scenery, NO sky, NO floor shadow plane: fully transparent background, export as PNG.
```
