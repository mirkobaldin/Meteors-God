# Prompt per la parte grafica (da dare al Claude locale)

Tre prompt da incollare, **uno alla volta**, nel Claude Code che hai sul PC (quello di DeadPlanet).
Il codice del gioco lo gestisce la sessione cloud: il Claude locale lavora **solo** su `art/` e `assets/`.

---

## PROMPT 1 — Concept art

I concept (case, props, strutture) li fa **Codex** con i prompt di `docs/PROMPTS_CODEX.md`. Manda i prompt qui sotto
al Claude locale **solo dopo** aver approvato le immagini.

---

## PROMPT 2 — Modelli 3D in Blender

```
Continuiamo su Meteor Gods (C:\Users\mirko\Desktop\Meteors-God), separato da DeadPlanet.
Rileggi docs/ASSET_PIPELINE.md: è il contratto che il codice del gioco si aspetta (nomi, marker, misure, limiti).
Usa i concept in art/concepts/ (per la mappa usa la variante: <SCRIVI QUI QUALE HAI SCELTO>).
Lavora SOLO in art/ e assets/.

Usa Blender (tramite il Blender MCP se è collegato, altrimenti scrivimi gli script Python da eseguire in Blender).
File sorgente in art/blender/*.blend, export FBX in art/export/<categoria>/.

Ordine di lavoro (fermati dopo ogni punto e mostrami un render):
1. GIÀ FATTO dalla sessione cloud: le 13 comete sono in art/export/meteors/*.fbx (con texture) e si rigenerano con
   art/blender/meteors_build.py. Tu devi solo IMPORTARLE in Studio (vedi docs/ASSET_PIPELINE.md). Se vuoi
   rifinirne una a mano, tieni le stesse regole:
   Meteors/Default + i 13 meteoriti: SOLO il corpo roccioso, SENZA faccia (occhi, bocca e sopracciglia sono
   parti 3D aggiunte dal codice sul lato -Z: lascia quel lato liscio e tondo). Circa 1x1x1, pivot al centro,
   < 3000 triangoli. Devono essere CAZZUTI, non pucciosi: rocce dure e taglienti, spigoli, spuntoni, corna,
   crepe di lava luminose (materiale con emissione), cristalli trasparenti, parti di metallo; usa i materiali
   migliori di Blender. Ogni rarità ha una silhouette diversa: Common = sasso grezzo, Mythic = forma unica e
   spaventosa. Elementi: Pebble roccia, Ember brace, Frost ghiaccio, Spark elettrico, Venom tossico con corna,
   Crystal gemme, Magma basalto e lava con corna, Aurora, Solar con corona, Royal Comet, Void (un solo occhio),
   Supernova, Blue Comet.
   I concept delle case, dei props e delle strutture sono in art/concepts/ (fatti con Codex).
2. Houses/House1 … House6: le 6 ville moderne dei concept approvati, ingombro max raggio 100 stud, fronte vetrato
   -Z verso l'isola centrale, Part "Sign" opzionale per il nome. Vetrate vere (materiale Glass, trasparenza ~0.4)
   e INTERNI arredati semplici ma leggibili (divani, lampade calde, tavolo, piedistallo con meteorite, scale):
   si deve vedere dentro. Legno chiaro, travertino, marmo chiaro, oro spazzolato; niente ossidiana.
   Niente slot: i meteoriti stanno sui piedistalli dell'isoletta.
   Poi i props (Props/<nome>) e le strutture (Structures/<nome>) con i nomi dei file in art/concepts/props e
   art/concepts/structures.
3. Map/Citadel (opzionale): SOLO decorazioni sopra il terreno (torri dorate, archi, rifiniture del Bifrost,
   rocce decorative) alle coordinate di Game.World. Le isole e i PIANETI sono Terrain generato dal codice:
   non modellarli (vedi "Terreno" in docs/ASSET_PIPELINE.md).

Regole: 1 unità Blender = 1 stud, Apply All Transforms prima di esportare, fronte verso -Z di Roblox,
max 20.000 triangoli per mesh, materiali PBR (vetro, legno, pietra, metallo), nomi ESATTI come nel contratto.

Dopo ogni export scrivimi i passi per importarlo in Roblox Studio (File > Import 3D), come raggrupparlo
con i nomi giusti e come salvarlo con "Save to File" in assets/<Categoria>/<Nome>.rbxm.
Se hai il Roblox Studio MCP collegato e il place di Meteor Gods è aperto, puoi farlo tu,
ma ATTENZIONE a non agire sulla finestra di Studio di DeadPlanet.
Commit solo di art/ e assets/, "git pull --rebase" prima del push.
```

---

## PROMPT 3 — Animazioni del personaggio

```
Meteor Gods (C:\Users\mirko\Desktop\Meteors-God), separato da DeadPlanet.
Servono 5 animazioni R15 per il personaggio-divinità. Nomi e uso sono in src/shared/Config/Assets.lua
(tabella Assets.Animations) — NON modificare quel file, dammi solo gli ID alla fine.

1. Charge (loop, ~1 s): sospeso in aria sopra il vuoto, gambe raccolte, braccia alzate sopra la testa
   come se reggesse una palla di fuoco che cresce, leggero tremolio di potenza.
2. Throw (singola, ~0.5 s): lancio potente sopra la testa verso avanti, con anticipazione e follow-through.
3. Hover (loop, ~2 s): fluttuare tranquillo a mezz'aria, mantello/vesti immaginari che ondeggiano.
4. Celebrate (singola, ~1.5 s): esultanza divina dopo un colpo critico (pugno al cielo, piccola rotazione).
5. Pickup (singola, ~0.4 s): si china e afferra un meteorite da terra.

Se hai il Roblox Studio MCP collegato e il place di Meteor Gods è aperto (NON quello di DeadPlanet),
crea le animazioni con l'Animation Editor (KeyframeSequence) su un rig R15 standard e pubblicale.
Altrimenti guidami passo passo nell'Animation Editor di Studio.
Le animazioni vanno pubblicate dallo stesso account/gruppo proprietario del gioco.
Alla fine dammi la lista: Charge = <id>, Throw = <id>, Hover = <id>, Celebrate = <id>, Pickup = <id>.
```
