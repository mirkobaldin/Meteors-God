# Prompt per Codex: interfaccia (cornici, pannelli, bottoni, icone) in DUE TEMI

Due temi, come per la mappa: A "Sky Ruins" (pietra scolpita, rame verde acqua, rune azzurre) e B "Starport"
(metallo blu notte, neon ciano/magenta, ologrammi). Prima prova con `ONLY = 1, 2, 6` (cornici, bottoni, icone),
poi scegli il tema e rilancia con `ONLY = all` e un solo tema.

Le immagini vanno in `art/ui/A/` e `art/ui/B/`. Poi in Studio le carichi (Asset Manager → Bulk Import) e metti gli ID in
`src/shared/Config/Assets.lua` (le icone hanno già i nomi giusti in `Assets.Icons`).

```
ONLY = 1, 2, 6
THEMES = A, B

Generate the UI art for the Roblox game "Meteor Gods" (young gods on floating islands at the edge of the
universe, living comets thrown at giant planets). For every theme in THEMES and every section in ONLY (or all),
save every file as PNG with a transparent background in art/ui/<THEME>/ with exactly these names. Overwrite
files with the same name.

THEME A, "SKY RUINS": carved weathered sandstone frames (#D9B98C, darker #8C7360) with oxidized teal copper
trims (#4FA3A0), glowing sky-blue runes (#6FD8FF) in the corners, panel centers of deep dusk-blue stone
(#1C2236, opaque or 85%). Chunky, carved, epic.
THEME B, "STARPORT": night-blue metal frames (#1E2440, #3A3F55) with rounded industrial corners, neon edge
lights in cyan (#33E5FF) with magenta accents (#FF4FD8), panel centers of dark translucent glass (#101426 at
85%) with a faint holographic grid. Clean, high-tech.
BOTH: readable and chunky enough for phones, strong contrast. NO text, no letters, no numbers anywhere (the game
writes the text) except the logo, no watermarks.

1. 9-SLICE FRAMES (the game stretches them, so: flat plain center, all decoration within 64 px of the edges,
   the four corners identical when mirrored, the middle of each edge a plain repeatable border):
   frame_window.png 512x512 (main window), frame_panel.png 512x512 (inner panel, lighter and simpler),
   frame_tooltip.png 256x256, frame_banner.png 1024x256 (wide announcement banner, ornaments only on the sides).
2. BUTTONS 512x160, 9-slice style (decoration within 48 px of the edges), each in 3 files: normal, hover
   (brighter), pressed (darker, 2 px lower): button_main_*.png (main action, the theme's brightest color), button_blue_*.png (secondary),
   button_red_*.png (cancel / close). Plus button_close.png 128x128 (round, with an X) and
   button_tab_on.png / button_tab_off.png 256x96.
3. CURRENCY PILLS 512x128, 9-slice, a round slot on the left for the icon: pill_shards.png (violet glow),
   pill_stardust.png (pink-violet), pill_power.png (gold).
4. BARS 512x64: bar_back.png (empty dark track with the theme's frame) and bar_fill.png (glowing fill, flat so it can be
   stretched), bar_fill_hp.png (red-orange, for planets).
5. RARITY CARD FRAMES 256x320 for the comet cards, same shape, one per rarity, the frame color and glow tells
   the rarity: card_common.png (grey-silver), card_rare.png (blue), card_epic.png (purple), card_legendary.png
   (gold, with small rays), card_mythic.png (pink-magenta, with sparkles), card_extraterrestrial.png (toxic
   green, alien, with strange symbols-like shapes but no letters).
6. ICONS 512x512, bold readable symbols in the theme's style (theme frame color as outline, glowing fill), each centered with
   padding: Meteors (a comet), Evolution (rising arrow with a star), Shop (bag with a star), Daily (gift),
   Trade (two arrows swapping), Upgrades (up arrow over a gem), Index (open book with a comet), Codes (ticket),
   Settings (gear), Menu (three lines), Power (lightning bolt), Shards (violet crystal shard), Stardust (pile of
   sparkling pink dust), Planets (planet with a ring), StarterPack (treasure chest), Wrath (fist of lightning),
   Boost (rocket), Hunt (portal ring), Fusion (three orbs merging), Weapons (crossed hammer and scythe),
   Collection (five small comets in a circle). File names: icon_<Name>.png.
7. LOGO: logo.png 2048x1024, the title "METEOR GODS" (this is the ONLY file with text), bold heavy letters of
   the theme's material (A: carved sandstone with glowing runes; B: metal with neon edges), a blazing comet
   crossing behind the letters, a few stars.
8. LOADING: loading_background.png 1920x1080 (not transparent): the floating islands in the theme's style, the
   glowing bridges and a giant planet in a purple nebula sky, no text.

When done: git add art/ui ; git commit -m "ui art" ; git pull --rebase ; git push.
```
