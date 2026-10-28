# Prompt per la parte grafica (da dare al Claude locale)

Tre prompt da incollare, **uno alla volta**, nel Claude Code che hai sul PC (quello di DeadPlanet).
Il codice del gioco lo gestisce la sessione cloud: il Claude locale lavora **solo** su `art/` e `assets/`.

---

## PROMPT 1 — Concept art con Codex

```
Lavoriamo su un SECONDO progetto, separato da DeadPlanet. Non toccare niente di DeadPlanet.
Cartella: C:\Users\mirko\Desktop\Meteors-God (repo GitHub mirkobaldin/Meteors-God).
Prima di tutto leggi docs/GDD.md e docs/ASSET_PIPELINE.md in quella cartella.
Lavora SOLO dentro art/ (non modificare src/: ci lavora un'altra sessione).

Il gioco: "Meteor Gods", Roblox. Sei una piccola divinità ai confini dell'universo. Allevi meteoriti VIVI
con la faccia, li lanci dai Ponti Stellari (stile Bifrost) contro pianeti giganti che si sbriciolano.

Usa Codex (o lo strumento di generazione immagini che hai a disposizione) per creare i CONCEPT ART.
Stile unico per tutto: cartoon/toon Roblox moderno, colori saturi, forme morbide e grosse, contorni leggibili,
luci al neon; palette: marmo bianco e oro + viola/magenta + ciano su cielo stellato blu-viola.
Riferimento di "pulizia e leggibilità" (NON da copiare): i giochi Roblox simulator più curati del 2025-2026.
Niente personaggi o marchi esistenti; le facce dei meteoriti NON devono ricordare Calcifer (Il castello errante di Howl).

Crea queste tavole, salvale come PNG in art/concepts/<categoria>/ con nomi chiari:

1. MAPPA (art/concepts/map/): 3 varianti della "Cittadella degli Dei": piattaforma circolare fluttuante nel vuoto
   ai confini dell'universo (raggio ~120 stud), spawn al centro, 8 case dei giocatori ad anello,
   4 Ponti Stellari arcobaleno che partono da un lato e finiscono nel nulla con un pad di LANCIO,
   un pianeta gigante sullo sfondo. Per ognuna: vista dall'alto + vista prospettica da un giocatore.

2. METEORITI (art/concepts/meteors/): un foglio per ogni tipo in src/shared/Config/Meteors.lua
   (Pebble, Ember, Frost, Spark, Venom, Crystal, Magma, Aurora, Solar, Royal Comet, Void,
   Supernova, Blue Comet). Ogni meteorite è una palla-roccia infuocata carina con faccia semplice
   (occhi grandi, bocca, guance), capelli/aura di fiamme del colore dell'elemento, leggibile anche piccolissima.
   Per ognuno: 5 espressioni (assonnato, felice, arrabbiato, furioso, stordito con occhi a spirale)
   + versione "Dorata", "Arcobaleno", "Eclissata". La rarità deve vedersi dalla forma (comune = sasso semplice,
   mitico = forma unica e spettacolare).

3. CASE DIVINE (art/concepts/houses/): il "Santuario" del giocatore in 6 livelli, uno per Evoluzione
   (Star Spirit → Minor Deity → Demigod → Titan → Cosmic God → Supreme Deity):
   da piccolo altare di pietra a tempio fluttuante con anelli che orbitano. Ogni santuario ha 3-4 piedistalli
   dove fluttuano i meteoriti e un'insegna con il nome del giocatore. Ingombro massimo raggio 14 stud.

4. PIANETI (art/concepts/planets/): Rocky Planet, di Ghiaccio, di Lava, Caramella, Crystal, Ombra
   + Legendary Planet dorato. Per ognuno: vista intera + spaccato con 3 strati (crosta a pezzi, mantello, nucleo luminoso).

5. INTERFACCIA (art/concepts/ui/): un mockup dell'HUD in stile "+1 Venom Evolution" come STRUTTURA
   (bottoni grandi a griglia a sinistra, offerte a destra, barra del Potere in basso con bottoni di acquisto rapido,
   menu a tendina in alto a destra), ma con la NOSTRA grafica cosmica. Poi le ICONE singole, PNG 512x512
   sfondo trasparente, in art/icons/: Meteors, Evolution, Shop, Daily, Trade, Upgrades, Index, Codes,
   Settings, Menu, Power, Shards, Planets, StarterPack, Wrath, Boost (nomi file = questi nomi).

Alla fine scrivi art/concepts/README.md con l'elenco delle immagini e 2 righe di descrizione per ognuna,
fai commit (solo art/), "git pull --rebase" e push su main. Poi dimmi quali varianti consigli per la mappa.
```

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
1. Meteors/Default + i 13 meteoriti: SOLO il corpo roccioso, SENZA faccia (la faccia la disegna il gioco).
   Circa 1x1x1, pivot al centro, < 3000 triangoli.
2. Houses/House1 … House6: i 6 santuari, con le Part/Empty Slot1..Slot4 e Sign come da contratto.
3. Planets/<Nome>: un pianeta alla volta, iniziando da "Rocky Planet". Crosta fratturata con Cell Fracture
   (30-60 pezzi, ognuno < 1500 triangoli) dentro una collection "Crust", poi Mantle e Core separati.
4. Map/Citadel: SOLO i pezzi sopra il terreno (pavimenti, torri dorate, Altare del Cielo, Bifrost, piattaforma di lancio)
   con TUTTI i marker (Spawn, House1-8, Field, LaunchPad1-4, Return1-4, Planet). Le rocce sotto le isole sono Terrain:
   non modellarle (vedi "Terreno" in docs/ASSET_PIPELINE.md).

Regole: 1 unità Blender = 1 stud, Apply All Transforms prima di esportare, fronte verso -Z di Roblox,
max 20.000 triangoli per mesh, texture palette unica 1024x1024 stile toon, nomi ESATTI come nel contratto.

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
