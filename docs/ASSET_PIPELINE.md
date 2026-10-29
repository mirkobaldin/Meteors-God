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
Una casa per ogni **livello casa** (1 = Star Pavilion … 6 = Supreme Palace, si comprano al leggio davanti alla casa,
vedi GDD): sostituisce il tempio segnaposto sull'Isola della Casa. Se ne manca una si usa la più vicina disponibile.

**Import delle case di Codex** (`art/export/houses/HouseN.fbx`): File → Import 3D → Model chiamato `House1` … `House6`
in `ReplicatedStorage/Assets/Houses/`. Il codice fa il resto da solo:
- **scala**: ridimensiona ogni casa alla sua misura di Blender (dai `HouseN_manifest.json`, copiati in
  `Game.House.Models`) × `Game.House.Scale` (1,5), qualunque scala abbia usato l'importatore;
- **posizione**: pivot sul centro del pavimento (origine di Blender), facciata verso l'isola centrale;
- **isola**: se la casa è più grande, l'isola della casa si allarga (raggio casa + `IslandMargin`); il leggio si
  sposta davanti alla facciata;
- **materiali**: ogni mesh si chiama come il suo materiale (es. `House3_Warm_Oak_01`); `Game.House.Materials` dà a
  ognuno materiale Roblox, colore, trasparenza e collisioni (vetro, acqua e luci senza collisione, si può entrare);
  le 3 texture di Codex (rovere, marmo, travertino) restano dove ci sono. `Sign` porta il nome del proprietario.

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
Ogni FBX contiene **due mesh**: `Body` (guscio + corna/cristalli) e `Jaw` (la mascella, che il codice apre e chiude).
Il nucleo in Roblox è la sfera Neon `InnerGlow` (0,86 del diametro) e le **pupille** sono due sfere create dal codice
dentro i buchi degli occhi (guardano la telecamera). Le animazioni (mascella che mastica/digrigna/ruggisce/russa
secondo l'espressione, pupille che si muovono) sono nel controller client `MeteorAnim`. I colori sono cotti in due
texture (`<Nome>.png` e `<Nome>_Jaw.png`, incluse nell'FBX). ~16.000 triangoli per cometa.

**Import in Studio:** File → Import 3D → scegli `art/export/meteors/<Nome>.fbx` → ottieni un Model con le MeshPart
`Body` e `Jaw`. Rinomina il Model con l'`id` esatto (es. `Royal Comet`, con lo spazio) e mettilo in
`ReplicatedStorage/Assets/Meteors/`. Non spostare né ridimensionare i pezzi: il codice li posiziona da solo con
`Config/MeteorMeshes.lua`.

**Scegliere i materiali:** in `src/shared/Config/Meteors.lua` ogni cometa può avere `rockMaterial` (materiale
Roblox di guscio e mascella, es. `Enum.Material.Basalt`, `Slate`, `Glacier`, `Marble`, `Foil`...) e `glowColor`
(colore del nucleo che brilla). I colori della roccia e delle crepe nel modello si cambiano in cima a
`art/blender/meteors_build.py` (`rock1`, `rock2`, `glow` di ogni cometa) e poi si rilancia lo script.

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
