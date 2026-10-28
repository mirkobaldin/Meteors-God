# Prompt per il Claude locale (Blender MCP): mesh base delle comete dalla reference

Da incollare nel Claude Code sul PC, con Blender aperto e il Blender MCP collegato.

## Setup (porta 9555, separata da DeadPlanet)

1. Blender: Edit → Preferences → Add-ons → (se non c'è già) Install from disk `addon.py` di blender-mcp
   (github.com/ahujasid/blender-mcp) e attivalo ("Interface: Blender MCP").
2. Nella vista 3D premi **N** → tab **BlenderMCP**: Port = **9555**, spunta **Use Hyper3D Rodin**
   (e "Use Hunyuan3D" se c'è), premi **Connect to MCP server** / Start.
3. Nel terminale, nella cartella Meteors-God:
   `claude mcp add blender-meteors -e BLENDER_PORT=9555 -- uvx blender-mcp`
   (su Windows, se non parte: `claude mcp add blender-meteors -e BLENDER_PORT=9555 -- cmd /c uvx blender-mcp`;
   serve `uv` installato: `pip install uv`).
4. Avvia `claude` in Meteors-God, scrivi `/mcp` e controlla che **blender-meteors** sia connesso.
5. `git pull`, poi incolla il prompt qui sotto.

```
Progetto Meteor Gods: C:\Users\mirko\Desktop\Meteors-God (fai git pull prima). Lavora SOLO in art/.
Obiettivo: la MESH BASE delle comete IDENTICA alla reference art/reference/meteor_base.png
(vista frontale a sinistra, vista 3/4 a destra, giri e silhouette sotto). Esempio finale colorato:
art/reference/meteor_supernova.png.

1. In Blender metti la reference come immagini di sfondo (Empty > Image) in vista frontale e laterale.
2. Genera la mesh con lo strumento image-to-3D del Blender MCP (Hyper3D Rodin, oppure Hunyuan3D se
   disponibile) partendo da art/reference/meteor_base.png. Se lo strumento non c'è, scolpiscila a mano
   (Sculpt mode) sopra le reference: prima i volumi, poi i dettagli.
3. Confronta con la reference (render frontale e 3/4 affiancati) e correggi: fai almeno 2 giri di
   revisione finché è identica. Dettagli che devono esserci: palla di grosse pietre scalpellate ammassate;
   SOPRACCIGLIA come quelle di Luffy Gear 5 (One Piece): due sopracciglia di pietra spesse e arrabbiate
   che all'interno, sopra il naso, si arricciano in una spirale e all'esterno salgono con una punta
   rivolta in su (NON sono corna: sono sopracciglia ricce scolpite nella roccia); orbite profonde;
   bocca larga con due zanne in alto e due denti in basso al centro; nessun cratere in cima.
4. Pulizia: una sola mesh, diametro 1 unità, centrata nell'origine, faccia verso -Y (vista frontale),
   circa 15.000-20.000 triangoli, normali corrette, niente colori.
   Gli OCCHI e la BOCCA devono essere BUCHI veri che attraversano la roccia (dietro ci sarà il nucleo
   luminoso), non incavi chiusi.
5. Esporta art/reference/meteor_base.glb, fai un render frontale in art/reference/meteor_base_render.png,
   commit solo di art/, git pull --rebase, push.

Il resto (nucleo luminoso, crepe, colori dei 13 elementi, mascella animata, pupille, texture, export per
Roblox) lo fa la sessione cloud partendo da quel .glb.
```
