# Prompt per il Claude Code locale: modelli 3D delle comete con Meshy

Prima: crea una chiave su meshy.ai (Settings → API) e mettila in una variabile d'ambiente, **non nel repo**:
PowerShell: `setx MESHY_API_KEY "msy_..."` (poi riapri il terminale). Usa i crediti: ogni modello ne consuma.

```
Progetto Meteor Gods: C:\Users\mirko\Desktop\Meteors-God (fai git pull). Lavora SOLO in art/.
Obiettivo: i modelli 3D delle 25 comete di art/concepts/comets/comets.json, generati con l'API di Meshy
(image-to-3D) dalle immagini approvate art/concepts/comets/<id>_front.png e <id>_34.png.

1. Scrivi uno script Python art/meshy/meshy_comets.py (usa requests) che legge la chiave da os.environ["MESHY_API_KEY"]
   (MAI scriverla in un file) e per ogni cometa:
   - manda le due immagini come data URI base64 a POST https://api.meshy.ai/openapi/v1/multi-image-to-3d
     (header Authorization: Bearer <key>) con: image_urls = [front, 34], should_texture = true, enable_pbr = true,
     should_remesh = true, topology = "triangle", target_polycount = 20000, symmetry_mode = "on";
     se l'endpoint multi-image non è disponibile, usa POST /openapi/v1/image-to-3d con image_url = front;
   - fa polling di GET .../multi-image-to-3d/<task_id> ogni 10 s finché status è SUCCEEDED (o FAILED: segnalalo e
     passa alla prossima);
   - scarica model_urls.glb in art/meshy/<id>.glb e salva la risposta JSON in art/meshy/<id>.json;
   - salta le comete che hanno già il .glb (così si può riprendere).
   Se un parametro viene rifiutato, controlla la documentazione aggiornata su docs.meshy.ai e adatta lo script.
2. Prima prova SOLO inferno_common e mostrami un render (Blender, vista frontale e 3/4). Aspetta il mio ok.
3. Poi lancia tutte le altre. Per ognuna fai un render frontale in art/meshy/renders/<id>.png e confrontalo con
   l'immagine di Codex: se la forma base non è rispettata (sopracciglia ricce, occhi e bocca scavati, placche di
   roccia), rigenerala una volta.
4. Non modificare i modelli oltre a questo: niente scala, niente pulizia (la fa la sessione cloud).
5. Commit di art/meshy (glb, json, render, script; NON la chiave), git pull --rebase, push.
```

Dopo il push la sessione cloud prende i `.glb`, li normalizza (diametro 1, faccia verso −Z), aggiunge il nucleo
luminoso, separa la mascella, posiziona le pupille, esporta per Roblox e collega le 25 comete al gioco.

## Mappa (negozio, strutture, props)

Dopo le comete, stesso script con la lista della mappa. Incolla al Claude locale:

```
Riusa art/meshy/meshy_comets.py rendendolo generico: aggiungi le opzioni --list (file JSON) e --images
(cartella delle immagini) e --out (cartella di uscita). Poi lancialo con
  --list art/concepts/map/map_assets.json --images art/concepts/map --out art/meshy/map
(nel JSON la chiave è "items" invece di "comets"; per ogni elemento usa <id>_front.png e <id>_34.png).
Per gli elementi di tipo "structure" usa target_polycount 40000, per "piece" e "prop" 15000.
Prima prova solo "shop" e mostrami un render, aspetta il mio ok, poi fai gli altri.
Render frontale di ognuno in art/meshy/map/renders/<id>.png. Commit di art/meshy/map (NON la chiave), pull --rebase, push.
```

La sessione cloud poi li scala a `size_studs`, li mette al posto delle strutture fatte a mano nel codice (negozio,
classifica, reattore, portale, pedane, porte dei ponti, piedistalli, leggio) e sparge i props sulle isole.
