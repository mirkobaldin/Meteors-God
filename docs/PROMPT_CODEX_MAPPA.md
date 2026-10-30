# Prompt per Codex: negozio, strutture, pezzi e props della mappa

Lista: `art/concepts/map/map_assets.json` (8 strutture, 5 pezzi ripetuti, 10 props).
Il problema delle immagini di prima: troppo oro, troppi ornamenti, stile da palazzo. Ora il riferimento
obbligatorio è lo stile delle ville che hai approvato (`art/concepts/houses/house3.png`): architettura vera di lusso,
pulita, quasi tutta bianca/crema, oro solo come fili sottili.

Consiglio: lancialo prima con `ONLY = shop, launch_pad, star_lamp` (una struttura, un pezzo, un prop), guardiamo il
risultato, poi `ONLY = all`.

```
ONLY = shop, launch_pad, star_lamp

Read art/concepts/map/map_assets.json. For every item listed in ONLY (or every item if ONLY = all) generate TWO
images, PNG with a fully transparent background, 1024x1024:
  art/concepts/map/<id>_34.png     3/4 view from above-left (about 30 degrees), like an isometric game asset
  art/concepts/map/<id>_front.png  front view
Overwrite files with the same name. Build exactly what the "look" field describes; "size_studs" is its size in
the game (a player is 5.5 studs tall): doors, steps, benches and railings must be sized for a player.

STYLE ANCHOR (mandatory): look at art/concepts/houses/house3.png and art/concepts/houses/house1.png: these
approved villas define the style of the whole map. Match their materials, colors, lighting and level of detail.
- Architecture: real high-end modern resort architecture (think luxury villas and boutique hotels): clean
  horizontal lines, flat or gently curved slabs, big glass, generous proportions. NOT baroque, NOT a palace,
  NOT a fantasy castle, NOT a temple, no columns with capitals, no scrolls, no crowns.
- Palette: warm white travertine (#EFE6D6) and pale marble (#F4F1EC) for most surfaces, warm light oak
  (#C08A5A), clear glass, brushed gold (#D6A860) ONLY as thin trims and frames (under 10% of the surface),
  small accents of cyan (#5AE6FF) and violet (#B47AFF) light. No black stone, no heavy gold.
- The cosmic touch is subtle and elegant: a glowing comet behind glass, thin light lines, a floating star,
  constellation patterns etched in stone.
- Render: premium stylized 3D (like the best Roblox showcase games): clean readable shapes, beveled edges,
  smooth materials with soft realistic reflections, soft daylight plus warm interior lights, gentle ambient
  occlusion. Same light and camera for every item so they look like one set.
- Pieces and props: simple, sturdy, readable from far away; one single object, complete and centered,
  nothing floating loose except what "look" asks for.

RULES: no text, no letters, no numbers, no logos, no watermarks (sign panels and screens stay blank); no people;
no background, no ground plane, no shadow plane (only the base the object itself has).

When done: git add art/concepts/map ; git commit -m "map concepts" ; git pull --rebase ; git push.
```
