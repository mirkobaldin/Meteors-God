# Prompt per Codex: interfaccia (cornici, pannelli, bottoni, icone)

Le immagini vanno in `art/ui/`. Poi in Studio le carichi (Asset Manager → Bulk Import) e metti gli ID in
`src/shared/Config/Assets.lua` (le icone hanno già i nomi giusti in `Assets.Icons`).

```
Generate the UI art for the Roblox game "Meteor Gods" (young gods on floating islands at the edge of the
universe, living comets, luxury modern villas). Save every file as PNG with a transparent background in art/ui/
with exactly these names. Overwrite files with the same name.

STYLE for all files: a premium cosmic UI that matches the villas in art/concepts/houses/: deep night-blue
glass panels (#141633 at about 85% opacity) with a soft inner glow, thin brushed-gold borders (#D6A860) with
small elegant star-shaped corner ornaments, white text areas, accents of cyan (#5AE6FF) and violet (#B47AFF)
light. Clean, readable, chunky enough for phones. NO text, no letters, no numbers anywhere (the game writes the
text), no watermarks.

1. 9-SLICE FRAMES (the game stretches them, so: flat plain center, all decoration within 64 px of the edges,
   the four corners identical when mirrored, the middle of each edge a plain repeatable border):
   frame_window.png 512x512 (main window), frame_panel.png 512x512 (inner panel, lighter and simpler),
   frame_tooltip.png 256x256, frame_banner.png 1024x256 (wide announcement banner, ornaments only on the sides).
2. BUTTONS 512x160, 9-slice style (decoration within 48 px of the edges), each in 3 files: normal, hover
   (brighter), pressed (darker, 2 px lower): button_gold_*.png (main action), button_blue_*.png (secondary),
   button_red_*.png (cancel / close). Plus button_close.png 128x128 (round, with an X made of gold lines) and
   button_tab_on.png / button_tab_off.png 256x96.
3. CURRENCY PILLS 512x128, 9-slice, a round slot on the left for the icon: pill_shards.png (violet glow),
   pill_stardust.png (pink-violet), pill_power.png (gold).
4. BARS 512x64: bar_back.png (empty dark track with gold border) and bar_fill.png (glowing fill, flat so it can be
   stretched), bar_fill_hp.png (red-orange, for planets).
5. RARITY CARD FRAMES 256x320 for the comet cards, same shape, one per rarity, the frame color and glow tells
   the rarity: card_common.png (grey-silver), card_uncommon.png (green), card_rare.png (blue), card_epic.png
   (purple), card_legendary.png (gold, with small rays), card_mythic.png (pink-magenta, with sparkles).
6. ICONS 512x512, bold readable symbols in the same style (gold outline, glowing fill), each centered with
   padding: Meteors (a comet), Evolution (rising arrow with a star), Shop (bag with a star), Daily (gift),
   Trade (two arrows swapping), Upgrades (up arrow over a gem), Index (open book with a comet), Codes (ticket),
   Settings (gear), Menu (three lines), Power (lightning bolt), Shards (violet crystal shard), Stardust (pile of
   sparkling pink dust), Planets (planet with a ring), StarterPack (treasure chest), Wrath (fist of lightning),
   Boost (rocket), House (modern villa), Hunt (portal ring), Fusion (three orbs merging), Weapons (crossed
   hammer and scythe), Families (five small comets in a circle). File names: icon_<Name>.png.
7. LOGO: logo.png 2048x1024, the title "METEOR GODS" (this is the ONLY file with text), bold heavy letters of
   white stone with gold edges, a blazing comet crossing behind the letters, a few stars.
8. LOADING: loading_background.png 1920x1080 (not transparent): the floating islands with the villas, the
   glowing bridges and a giant planet in a purple nebula sky, no text.

When done: git add art/ui ; git commit -m "ui art" ; git pull --rebase ; git push.
```
