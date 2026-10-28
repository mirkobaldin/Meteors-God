# Asset Pipeline — Meteor Gods

Come entrano nel gioco modelli 3D, icone, animazioni e suoni.
Il codice usa l'asset se c'è; se manca, usa la versione generata da codice (fallback).
Quindi si può sostituire un pezzo alla volta senza rompere niente.

---

## 1. Dove vanno i modelli

Tutti i modelli stanno in **`ReplicatedStorage.Assets`** (cartella sincronizzata da `assets/` con Rojo).

La cartella ha `ignoreUnknownInstances = true`, quindi ci sono due modi equivalenti:

- **A — dentro la repository (consigliato):** importa il modello in Studio, sistemalo secondo il contratto qui sotto,
  tasto destro → **Save to File…** → salvalo come `.rbxm` in `assets/<Categoria>/<Nome>.rbxm`. Rojo lo sincronizza.
- **B — solo nel place:** trascina il modello in `ReplicatedStorage.Assets/<Categoria>/` direttamente in Studio
  e salva il place. Rojo non lo cancella. (Però non finisce su GitHub.)

## 2. Contratto dei nomi

### Terreno (Roblox Terrain)
Le isole, gli isolotti e **i pianeti** sono **Terrain** generato dal codice. Colori dei materiali in
`src/shared/Config/Terrain.lua` (ogni materiale ha un solo uso, perché Roblox colora un materiale uguale ovunque).
Se vuoi scolpire tu le isole con il **Terrain Editor** di Studio, metti `Game.World.GenerateTerrain = false`:
il codice genera solo le parti (ponti, piedistalli, case segnaposto, pad). I pianeti restano sempre generati.

### `Assets/Map/Citadel` — decorazioni della mappa (Model, opzionale)
Pezzi Blender **sopra** il terreno: torri dorate, archi, l'Altare/vortice del campo, rifiniture del Bifrost, rocce
decorative. Viene messo in `workspace.World` così com'è (coordinate del mondo, vedi `Game.World` per le posizioni:
isola centrale in 0,0,0 raggio 480; lotti dietro; Shop a −720,0,420; Classifica a 720,0,420; tre piattaforme a 1.250 stud dal centro a −32°, 0°, +32°).
Il gameplay (lotti, piedistalli, pad, campo) è sempre generato dal codice, quindi non servono marker.

### `Assets/Houses/House1` … `House6` — le case divine dei giocatori (Model)
Una casa per ogni Evoluzione (1 = Star Spirit … 6 = Supreme Deity): la casa cresce con il giocatore e sostituisce
il tempio segnaposto sull'Isola della Casa. Se ne manca una si usa la più vicina disponibile.

| Elemento | Cosa indica |
|---|---|
| `PrimaryPart` | base della casa, pivot al centro del pavimento; il fronte (−Z) guarda verso l'isola centrale |
| `Sign` (Part, opzionale) | dove appare il nome del proprietario |

Ingombro massimo: cerchio di raggio 100 stud (l'isola ha raggio 120). Altezza libera.
I meteoriti non stanno più nella casa: fluttuano sui piedistalli dell'Isoletta delle Comete.

### `Assets/Meteors/<TipoMeteorite>` — corpi dei meteoriti (MeshPart)
`<TipoMeteorite>` = il campo `id` in `src/shared/Config/Meteors.lua` (es. `Pebble`, `Frost`, `Supernova`).
Un singolo **MeshPart** chiamato come il tipo, roccia/forma del meteorite **senza faccia**:
la faccia (occhi, pupille, sopracciglia, bocca, guance) è fatta di **parti 3D saldate al corpo** dal codice sul lato
−Z, così le espressioni cambiano. Lascia il fronte (−Z) abbastanza liscio e tondo per ospitarla.
Dimensione 1×1×1 stud circa: il codice lo scala. Pivot al centro. Se manca, `Assets/Meteors/Default`.

**Le 13 comete sono già fatte** da `art/blender/meteors_build.py` (Blender, procedurale): FBX in
`art/export/meteors/<Nome>.fbx` (nome senza spazi, es. `RoyalComet.fbx`; in Studio rinomina il MeshPart con l'`id`
esatto, es. `Royal Comet`), render in `art/renders/meteors/`. Lo script scrive anche
`src/shared/Config/MeteorMeshes.lua` con il riquadro di ogni mesh: serve al codice per far combaciare la sfera della
roccia con la faccia anche se ci sono corna o creste. Se rifai una cometa a mano, riesegui lo script con `--config`
o aggiorna quel file. Niente accessori: corna, creste, cristalli e pinne fanno parte della roccia.
**Stile scelto: due strati.** Dentro un **nucleo luminoso** del colore dell'elemento; sopra un **guscio di roccia a
placche bombate** con le crepe (stile lava raffreddata) che scendono sotto il nucleo, così la luce esce dalle crepe.
La **faccia è scavata** nel guscio (occhi arrabbiati e bocca con le zanne, lato −Z) e si vede il nucleo dai buchi.
L'FBX contiene **solo il guscio** (+ corna/cristalli): il nucleo in Roblox è la sfera Neon `InnerGlow` (0,86 del
diametro) che il codice mette dentro quando c'è la mesh; in quel caso niente faccia a pezzi. I colori sono cotti in
una texture 2048 (`<Nome>.png`, inclusa nell'FBX). ~16.000 triangoli per cometa.

## 3. Regole tecniche per i modelli (Blender → Roblox)

- Esporta **FBX** (o OBJ). In Studio: **Avatar / 3D Importer** (`File → Import 3D`).
- **1 unità Blender = 1 stud.** Controlla le misure dopo l'import e riscala in Studio se serve.
- Triangoli: massimo **20.000 per MeshPart** (limite Roblox). Obiettivo: < 5.000 per pezzo, < 1.500 per pezzo di crosta.
- Texture: PNG **1024×1024** al massimo, meglio un'unica **palette texture** condivisa (stile toon, colori pieni).
- Pivot al centro, nessuna trasformazione non applicata (`Ctrl+A → All Transforms` prima dell'export).
- Fronte del modello verso **-Z** in Roblox.
- Nomi esattamente come nel contratto (maiuscole comprese).

## 4. Icone, animazioni, suoni → `src/shared/Config/Assets.lua`

Questi sono **asset ID** caricati su Roblox (Creator Hub → Development Items, oppure Asset Manager in Studio).
Si incollano in `src/shared/Config/Assets.lua`. `0` = non configurato.

- **Icone UI**: PNG 512×512 con sfondo trasparente → caricate come **Decal/Image** → ID immagine.
- **Animazioni R15**: create con l'Animation Editor di Studio (o Moon Animator) → **Publish to Roblox** → ID.
  Devono essere pubblicate dallo stesso account/gruppo proprietario del gioco.
- **Suoni**: caricati come Audio → ID.
