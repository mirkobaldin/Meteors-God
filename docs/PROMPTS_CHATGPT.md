# Prompt per ChatGPT (generazione immagini) — Meteor Gods

Incolla **un prompt alla volta** in una chat di ChatGPT con la generazione immagini.
Prima incolla il **BLOCCO STILE** una volta sola all'inizio della chat, poi i prompt della categoria che ti serve.
I prompt sono in inglese perché i modelli di immagini rendono meglio così.

Dove serve uno **sfondo trasparente**, scrivilo anche a voce nella chat se ChatGPT non lo fa:
"make the background transparent, export as PNG".

---

## 0. BLOCCO STILE (incollalo per primo, una volta)

```
You are the art director of "Meteor Gods", a Roblox game. The player is a small god living on a floating
citadel at the very edge of the universe. Gods raise LIVING METEORS (cute fiery rocks with faces) and throw
them from rainbow star-bridges at giant planets, which shatter into fragments.

Global art style for every image in this chat:
- Stylized but premium: semi-realistic lighting and materials, chunky readable shapes, slightly cartoony proportions
  (think high-end stylized game art, Fortnite / Sea of Thieves level of polish), NOT flat vector, NOT pixel art.
- Palette: white marble and warm gold for divine architecture; deep space navy/indigo backgrounds;
  accents of cyan, magenta and violet nebula light; meteors glow with their element color.
- Always cinematic rim lighting, soft bloom on emissive parts, clean silhouettes readable at small size.
- No text, no logos, no watermarks, no existing characters or brands.
Confirm you understood with one line, then wait for my requests.
```

---

## 1. MAPPA — la Cittadella degli Dei

**1A — vista d'insieme**
```
Concept art, wide establishing shot: a circular floating citadel made of white marble and gold, hovering in
deep space at the edge of the universe. Below it there is nothing but stars and nebula. The citadel is a flat
round plaza (about 240 meters across) with a glowing golden spawn circle in the center and 8 small divine
shrines arranged in a ring around it. From one side of the plaza, 4 long parallel rainbow "star bridges"
(like the Bifrost) stretch out into the void and simply END in empty space; at the end of each bridge there is a
glowing circular launch pad. Far beyond the bridges, a gigantic realistic planet fills a third of the sky.
Epic scale, sense of height and vertigo, cinematic lighting.
```

**1B — vista dall'alto (pianta)**
```
Top-down orthographic map layout of the same floating citadel, clean and readable, for a level designer:
round plaza, central spawn circle, 8 shrine plots evenly spaced on a ring (leaving free the side where the
bridges start), 4 parallel rainbow bridges leaving from that side, launch pads at their ends.
Soft shadows, no perspective, no text.
```

**1C — punto di vista del giocatore sul pad di lancio**
```
Third-person view from behind a small Roblox-style character standing at the end of a glowing rainbow
star-bridge, nothing below but the void. A huge realistic planet with atmosphere glow and clouds hangs ahead in
the distance. Above the character's head floats a fiery meteor with a cute angry face, ready to be thrown.
Dramatic, the planet looks enormous and far away.
```

**1D — dettagli della cittadella (kit modulare)**
```
Modular environment kit sheet for the floating citadel, isolated pieces on a neutral dark background:
marble floor tiles with gold inlays, broken marble pillars with floating gold rings, crystal braziers with
cosmic fire, decorative golden arches, edge railings, floating rock islands under the platform, glowing runes.
Each piece separated with space around it, consistent scale, game asset sheet.
```

---

## 2. METEORITI — personaggi

**2A — foglio di design di un meteorite** (ripeti cambiando NOME / ELEMENTO / COLORI / FORMA)
```
Character design sheet for a LIVING METEOR named "<NOME>", element <ELEMENTO>.
A round fiery space rock with a cute expressive cartoon face (big glossy eyes, small mouth, blush),
flames/aura rising from its top like hair, color <COLORI>, shape <FORMA>.
Show: front view, 3/4 view, and 5 expressions in a row: sleepy, happy, angry, furious (screaming, flames bigger),
dizzy (spiral eyes). Clean dark navy background, consistent lighting, game character turnaround.
The face must stay readable even very small. Do not resemble Calcifer from Howl's Moving Castle.
```
Valori da usare:
| NOME | ELEMENTO | COLORI | FORMA |
|---|---|---|---|
| Sassolino | rock | grey stone, orange flames | small simple pebble |
| Brace | ember | dark red rock, orange-red flames | cracked glowing coal |
| Gelo | ice | icy blue crystal rock, pale cyan flames | rock with frost spikes |
| Scintilla | electric | yellow rock, white-yellow sparks | rock crackling with lightning |
| Veleno | poison | toxic green rock, lime flames | dripping slimy rock with small horns |
| Cristallo | crystal | pink-purple crystal, magenta flames | faceted gem rock |
| Magma | lava | black basalt with lava cracks, orange flames | jagged volcanic rock with horns |
| Aurora | aurora | teal rock, green-violet aurora flames | smooth rock with flowing aurora ribbons |
| Solare | sun | golden glowing rock, white-gold flames | rock wearing a small golden crown |
| Cometa Regale | comet | white-blue rock, long blue comet tail | regal rock with crown and icy tail |
| Vuoto | void | black rock, violet flames, starry inside | rock with ONE big cyclops eye |
| Supernova | star | blinding white rock, pink-white flames | rock wearing cool sunglasses, star burst halo |
| Cometa Blu | blue comet | deep blue rock, cyan flames | rock with sunglasses, sleek comet tail |

**2B — mutazioni**
```
Show the meteor "<NOME>" in three special variants side by side: GOLDEN (polished gold rock, golden sparkles),
RAINBOW (rainbow shifting flames and rainbow particles), ECLIPSED (pitch black rock, violet eclipse corona,
glowing violet eyes). Same pose and expression for comparison, dark background.
```

**2C — icone dei meteoriti per l'inventario**
```
Game inventory icons, one per meteor: <ELENCA I NOMI>. Each icon is the meteor's happy face, centered,
filling 85% of the frame, strong outline glow of its element color. Square 512x512, transparent background,
consistent lighting and size across all icons.
```

---

## 3. CASE DIVINE — il Santuario del giocatore (6 livelli)

**3A — progressione**
```
Design sheet: the evolution of a player's divine SHRINE in 6 tiers, left to right, same camera angle:
1 "Star Spirit": small round stone altar with 3 pedestals and a few floating pebbles.
2 "Minor Deity": marble altar with a golden halo ring floating above.
3 "Demigod": small open temple with 4 marble columns, light wings sculpted on the sides.
4 "Titan": bigger temple, golden dome, crown motif, braziers with cosmic fire.
5 "Cosmic God": temple floating on its own rock, planetary rings orbiting around it.
6 "Supreme Deity": majestic floating sanctum with a galaxy swirling above, crystal spires.
Every tier has 3-4 floating pedestals where living meteors hover, and a front plaque for the owner's name.
Footprint stays inside a circle; tiers grow mostly in height and detail. Dark space background.
```

**3B — singolo livello in dettaglio** (ripeti per 1..6)
```
Detailed concept of the tier <N> shrine "<NOME LIVELLO>" from the previous sheet: front view, side view,
top view, plus a close-up of a meteor pedestal. Clear readable shapes, ready to be modeled in Blender.
```

---

## 4. PIANETI — realistici e frammentabili

**4A — concept del pianeta** (ripeti per ogni pianeta)
```
Realistic stylized planet concept for a game, seen from space: "<NOME PIANETA>" — <DESCRIZIONE>.
Show the full planet with atmosphere glow and clouds, then a CUTAWAY of the same planet showing 3 layers:
a cracked crust made of large tectonic plates (the plates will break off when hit), a glowing molten mantle,
and a bright luminous core. Add a third image of the planet mid-destruction: huge plates flying away,
mantle exposed, debris and a shockwave. Deep space background with distant stars.
```
| NOME PIANETA | DESCRIZIONE |
|---|---|
| Pianeta Roccioso | rocky desert world, ochre and brown plates, deep canyons, thin dusty atmosphere |
| Pianeta di Ghiaccio | frozen world, white and pale blue ice sheets, blue crevasses, cyan atmosphere |
| Pianeta di Lava | black basalt crust with rivers of glowing lava, smoky orange atmosphere |
| Pianeta Caramella | whimsical candy planet, pastel pink and mint plates, swirl patterns, pink atmosphere |
| Pianeta Cristallo | crystalline world, violet glass plates with glowing veins, magenta atmosphere |
| Pianeta Ombra | dark shadow planet, near-black plates with violet energy cracks, eerie purple glow |
| Pianeta Leggendario | golden divine planet, polished gold plates with white light veins, golden ring around it |

**4B — texture del pianeta (per i nuclei/mantelli e future skin)**
```
Seamless equirectangular planet surface texture (2:1 aspect ratio, 2048x1024), flat lighting, no shadows,
no atmosphere, for wrapping on a sphere: <DESCRIZIONE DEL PIANETA>. The left and right edges must tile seamlessly
and the poles must not be distorted.
```

---

## 5. EFFETTI (VFX) — texture per le particelle

Queste servono davvero: le particelle di Roblox con le texture di default sono brutte.
Tutte: **PNG 512x512, sfondo trasparente (o nero puro se non riesce), soggetto bianco/chiaro** (il colore lo dà il gioco).

```
Game VFX particle texture sheet, each element as a SEPARATE square image, white/grayscale on transparent
background, soft edges, centered, no text:
1. soft round glow (radial gradient)
2. fire flame wisp
3. thick smoke puff
4. sharp 4-point star sparkle
5. shockwave ring (thin bright ring with soft falloff)
6. rock debris chunk silhouette
7. energy swirl / vortex
8. lightning bolt crackle
9. impact burst (radial spikes)
10. meteor trail streak (horizontal, fading to the right)
```

**5B — riferimento per l'impatto (non serve caricarlo, è per me)**
```
Storyboard of 4 frames of a giant fiery meteor hitting a planet seen from space: 1) the meteor approaching with a
long fiery trail, 2) the blinding white flash at contact, 3) a ring shockwave spreading across the planet surface
while tectonic plates are blasted out into space, 4) a glowing crater revealing molten mantle with debris
floating away. Cinematic, epic.
```

---

## 6. INTERFACCIA — icone e stile dei menu

**6A — stile dei pannelli**
```
UI style guide for a cosmic divine Roblox game (original style, not copying other games): dark navy glass panels
with subtle star-field texture, thin warm-gold borders with small ornamental corners, rounded but elegant shapes,
circular "orb" buttons with a glowing ring, pill-shaped currency counters, gold and cyan highlights.
Show: a window with title bar and round close button, a primary button, a secondary button, a tab bar,
a progress bar, a currency pill, a circular menu button. No readable text (use blank shapes).
```

**6B — icone** (chiedi ogni icona come immagine separata se le unisce)
```
Set of game UI icons, each a SEPARATE 512x512 PNG with transparent background, glossy stylized 3D look,
gold and cosmic colors, consistent lighting and perspective, no text:
Meteors (a cute fiery meteor), Evolution (rising divine star with wings), Shop (golden chest with stars),
Daily (calendar with a star), Trade (two hands exchanging a glowing orb), Upgrades (upward golden arrow with
sparkles), Index (open ancient book with constellations), Codes (golden key), Settings (golden gear),
Menu (three golden bars), Power (lightning bolt in an orb), Shards (cluster of cyan crystals),
Planets (small cracked planet), StarterPack (gift box with a comet), Wrath (fiery divine fist),
Boost (glowing potion flask).
```
Nomi file da usare (servono per il caricamento): `Meteors, Evolution, Shop, Daily, Trade, Upgrades, Index, Codes,
Settings, Menu, Power, Shards, Planets, StarterPack, Wrath, Boost`.

---

## Cosa fare con le immagini

- **Concept (mappa, meteoriti, case, pianeti)** → mettili in `art/concepts/<categoria>/` e passali al Claude locale per Blender.
- **Icone e texture VFX** → caricale su Roblox (Creator Hub → Development Items → Decals/Images, o Asset Manager in Studio),
  poi incolla gli ID in `src/shared/Config/Assets.lua` (`Icons` e `Particles`) — o mandali a me e li inserisco io.
- **Texture dei pianeti** → caricale come immagini e incolla gli ID in `Assets.PlanetTextures`.
