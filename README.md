# Meteor Gods ☄️

Gioco Roblox: sei una divinità ai confini dell'universo. Allevi meteoriti vivi con la faccia,
li lanci dai Ponti Stellari contro i pianeti e diventi sempre più divino.

Design completo: [`docs/GDD.md`](docs/GDD.md)

---

## Come aprirlo in Roblox Studio (Rojo)

Il codice vive in questa repository e si sincronizza in Studio con **Rojo**.

### 1. Installa Rojo (una volta sola)
- **VS Code**: installa l'estensione **Rojo** (di evaera). Include il server Rojo.
- **Plugin per Studio**: dall'estensione VS Code usa il comando *"Rojo: Install Roblox Studio plugin"*,
  oppure installa il plugin "Rojo" dal Creator Store.
- In alternativa da terminale: [Rokit](https://github.com/rojo-rbx/rokit) → `rokit install` nella cartella del progetto
  (usa le versioni in `rokit.toml`).

### 2. Sincronizza
1. `git clone` / `git pull` di questa repository.
2. Apri la cartella in VS Code ed esegui *"Rojo: Open menu" → Start* (oppure `rojo serve` da terminale).
3. In Roblox Studio apri un place **Baseplate** nuovo, apri il plugin Rojo e premi **Connect**.
4. Il codice viene inserito in `ReplicatedStorage.Shared`, `ServerScriptService.Server` e
   `StarterPlayer.StarterPlayerScripts.Client`. La mappa viene generata da codice quando premi **Play**.

### 3. Impostazioni del gioco (Game Settings in Studio)
- **Security → Enable Studio Access to API Services**: ON (serve per i salvataggi; senza, i dati restano in memoria).
- **Places → Max Players**: **8** (ci sono 8 altari).
- **Avatar**: R15 consigliato (le evoluzioni fanno crescere l'avatar).

In Studio i tempi del ciclo sono accorciati (Pioggia 20 s, Bombardamento 60 s) per testare velocemente.
Nel gioco pubblicato sono 60 s / 240 s. Si cambia in `src/shared/Config/Game.lua`.

### 4. Game Pass e Developer Products
1. Creator Hub → la tua esperienza → **Monetization** → crea i Pass e i Developer Products elencati in `docs/GDD.md`.
2. Incolla gli ID in `src/shared/Config/Monetization.lua`.
3. Finché un ID è `0` il negozio lo mostra come "Presto" e non succede nulla.

---

## Struttura

```
src/
  shared/            -> ReplicatedStorage.Shared
    Config/          Meteoriti, pianeti, evoluzioni, economia, monetizzazione (tutto il bilanciamento è qui)
    Util/            Formule condivise (danno, crescita) e formattazione numeri
    MeteorVisual.lua Meteoriti con la faccia generati da codice
    Remotes.lua      Elenco di tutti i RemoteEvent / RemoteFunction
  server/            -> ServerScriptService.Server
    Main.server.lua  Avvia i servizi
    Services/        Data, World, Player, Meteor, Cycle, Shower, Planet, Launch, Shop, Trade
  client/            -> StarterPlayerScripts.Client
    Main.client.lua  Avvia i controller
    Controllers/     HUD, Lancio, Meteoriti, Negozio, Scambi, Notifiche
```

### Aggiungere contenuti
- **Nuovo meteorite**: una voce in `src/shared/Config/Meteors.lua` (colori, faccia, danno, crescita).
- **Nuovo pianeta**: una voce in `src/shared/Config/Planets.lua`.
- **Nuova evoluzione**: una voce in `src/shared/Config/Evolutions.lua`.

## Stato
Versione **0.1**: prima versione giocabile, scritta senza poterla provare in Studio.
Se qualcosa non funziona, copia l'errore dalla finestra **Output** di Studio e mandalo.
