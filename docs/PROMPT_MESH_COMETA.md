# Prompt per il Claude locale (Blender MCP): mesh base delle comete dalla reference

Da incollare nel Claude Code sul PC, con Blender aperto e il Blender MCP collegato.

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
   revisione finché è identica. Dettagli che devono esserci: palla di grosse pietre scalpellate ammassate,
   sopracciglia-corna spesse con la spirale sopra il naso e il corno corto che punta in su, orbite
   profonde, bocca larga con due zanne in alto e due denti in basso al centro, nessun cratere in cima.
4. Pulizia: una sola mesh, diametro 1 unità, centrata nell'origine, faccia verso -Y (vista frontale),
   circa 15.000-20.000 triangoli, normali corrette, niente colori.
   Gli OCCHI e la BOCCA devono essere BUCHI veri che attraversano la roccia (dietro ci sarà il nucleo
   luminoso), non incavi chiusi.
5. Esporta art/reference/meteor_base.glb, fai un render frontale in art/reference/meteor_base_render.png,
   commit solo di art/, git pull --rebase, push.

Il resto (nucleo luminoso, crepe, colori dei 13 elementi, mascella animata, pupille, texture, export per
Roblox) lo fa la sessione cloud partendo da quel .glb.
```
