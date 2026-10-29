# Prompt per Codex: negozio, strutture e oggetti della mappa

Lista: `art/concepts/map/map_assets.json` (23 elementi: 8 strutture di gioco, 5 pezzi ripetuti, 10 props).
Stile uguale alle ville di Codex: travertino bianco, marmo chiaro, oro spazzolato, vetro, legno caldo, luci
ciano/viola. Poi Meshy li trasforma in 3D (vedi `docs/PROMPT_MESHY.md`, sezione "Mappa").

| Struttura | A cosa serve nel gioco |
|---|---|
| Divine Shop | negozio (pass, boost, potenziamenti) |
| Leaderboard Monument | classifica dei pianeti distrutti |
| Fusion Reactor | 3 comete uguali → 1 più rara |
| Cosmic Hunt Portal | modalità volo nello spazio |
| Family Forge | dove si vedono le armi delle 5 famiglie |
| Trade Plaza | punto di scambio tra giocatori |
| Daily Star Chest | premio giornaliero |
| God Statue | centro dell'isola principale (spawn) |
| Launch Pad, Bifrost Gate, Comet Pedestal, House Lectern, Bridge Lamp | pezzi ripetuti sulla mappa |

```
Read art/concepts/map/map_assets.json: it lists the buildings, repeated pieces and props for the map of the
Roblox game "Meteor Gods" (young gods on floating islands at the edge of the universe, living comets, luxury
modern villas with glass walls). For EVERY item generate TWO images, PNG with a fully transparent background,
1024x1024:
  art/concepts/map/<id>_front.png   front view
  art/concepts/map/<id>_34.png      3/4 view from the left, same object, same lighting
(<id> is the "id" field). Overwrite existing files with the same name.

Each item: build exactly what its "look" field describes; "size_studs" is its real size in the game (a player
is 5.5 studs tall), so keep believable proportions (doors, steps and benches sized for a player).

STYLE (same family as the villas in art/concepts/houses/): elegant "celestial modern": white travertine and pale
marble, brushed gold, clear and frosted glass, warm light wood, warm lights and small soft cyan/violet
starlight accents; bright, premium and clean like a luxury resort in space; stylized for a Roblox game with
clear readable shapes and moderate detail (it will be turned into a 3D model by an image-to-3D AI, so: one
single object, complete, centered, nothing cut off, no thin floating wires). Soft studio light, the same for
all items.

RULES: no text, no letters, no numbers, no logos, no watermarks (sign panels and screens stay blank); no
characters or people; no background, no ground plane, no shadow plane; NO obsidian, NO black stone, NO gothic,
NOT cartoon-cute.

When done: git add art/concepts/map ; git commit -m "map concepts" ; git pull --rebase ; git push.
```
