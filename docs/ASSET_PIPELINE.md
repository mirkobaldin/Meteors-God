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
Le rocce delle isole e gli isolotti fluttuanti sono **Terrain**. Il codice li genera da solo
(`Game.World.GenerateTerrain = true`). Se preferisci scolpirlo tu con il **Terrain Editor** di Studio
(Generate / Add / Smooth), salvalo nel place: quando il terreno non è vuoto il codice non genera niente.
I modelli Blender vanno **sopra** il terreno: non serve modellare le rocce sotto le isole.

### `Assets/Map/Citadel` — la mappa (Model)
La mappa segue un unico asse verso il pianeta e, vista dall'alto, ha la forma di una **serratura** (non un cerchio):
1. **Dietro — quartiere delle case**: grande mezzaluna di marmo e oro con le 8 case in arco e torri dorate affusolate.
2. **Al centro — Campo dei Meteoriti**: altopiano rotondo di roccia scura (raggio ~115), un po' più alto e sovrapposto
   al fronte del quartiere, con l'Altare del Cielo al centro. **Qui cadono i meteoriti.** Rampe verso le case.
3. **Davanti — Bifrost**: lungo ponte dritto di vetro cosmico scuro con "glitch" di luce (~300 × 26), due torri dorate
   all'ingresso, fino alla **Piattaforma di Lancio** con cupola dorata e 4 pad rivolti verso il pianeta.

Marker richiesti (Part invisibili, `Anchored`, `CanCollide = false`, `Transparency = 1`) dentro `Markers/`:

| Marker | Cosa indica |
|---|---|
| `Markers/Spawn` | punto di spawn nella città |
| `Markers/House1` … `Markers/House8` | posizione e orientamento delle case (la faccia `-Z` guarda verso il centro della città) |
| `Markers/Field` | centro del Campo dei Meteoriti, con **attributi** `InnerRadius` (altare centrale, niente meteoriti) e `OuterRadius` (numeri, in stud) |
| `Markers/LaunchPad1` … `Markers/LaunchPad4` | centro dei pad sulla piattaforma di lancio |
| `Markers/Return1` … `Markers/Return4` | dove torna il giocatore dopo il lancio (inizio del Bifrost, `-Z` verso il pianeta) |
| `Markers/Planet` | centro del pianeta bersaglio (molto lontano, ~2.500 stud oltre la piattaforma) |

Un personaggio Roblox è alto ~5 stud.

### `Assets/Houses/House1` … `House6` — le case divine dei giocatori (Model)
Una casa per ogni Evoluzione (1 = Star Spirit … 6 = Supreme Deity): la casa cresce con il giocatore.
Se ne manca una si usa la più vicina disponibile.

| Elemento | Cosa indica |
|---|---|
| `PrimaryPart` | base della casa, pivot al centro del pavimento |
| `Slot1` … `Slot4` (Part o Attachment) | dove fluttuano i meteoriti dell'altare |
| `Sign` (Part) | dove appare il nome del proprietario |

Ingombro massimo: cerchio di raggio 14 stud. Altezza libera.

### `Assets/Planets/<NomePianeta>` — i pianeti (Model)
`<NomePianeta>` = il campo `name` in `src/shared/Config/Planets.lua` (es. `Rocky Planet`), oppure `Legendary`.
Pivot al centro. Diametro esterno ~320 stud.

| Elemento | Cosa indica |
|---|---|
| `Crust` (Folder) | 30–60 pezzi della crosta **già fratturati** (Blender: Cell Fracture). Si staccano agli impatti |
| `Mantle` (MeshPart o Part) | strato intermedio, diametro ~250 |
| `Core` (MeshPart o Part) | nucleo luminoso, diametro ~100 |
| altro (anelli, lune) | decorazioni, esplodono alla fine |

### `Assets/Meteors/<TipoMeteorite>` — corpi dei meteoriti (MeshPart)
`<TipoMeteorite>` = il campo `id` in `src/shared/Config/Meteors.lua` (es. `Pebble`, `Frost`, `Supernova`).
Un singolo **MeshPart** chiamato come il tipo, roccia/forma del meteorite **senza faccia**:
la faccia (occhi, bocca, espressioni) resta disegnata dal codice, così le espressioni cambiano.
Dimensione 1×1×1 stud circa: il codice lo scala. Pivot al centro. Se manca, `Assets/Meteors/Default`.

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
