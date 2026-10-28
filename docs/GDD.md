# METEOR GODS — Game Design Document (v0.1)

> Sei una piccola divinità ai confini dell'universo. Allevi meteoriti vivi con la faccia,
> li scagli contro i pianeti che passano nel vuoto e diventi sempre più divino.

---

## 1. Pilastri

1. **Il lancio è il momento più figo del gioco.** Corsa sul Ponte Stellare → salto nel vuoto → carica con l'aura → meteorite che parte velocissimo → impatto → il pianeta si sbriciola.
2. **I meteoriti sono personaggi.** Sfere infuocate con facce disegnate (felici, arrabbiate, assonnate, stordite). Si collezionano, crescono, si scambiano.
3. **Sali di rango e si vede.** Il Potere sale di +1 al secondo; le Evoluzioni Divine trasformano l'avatar (aureola, ali, corona, anelli, dimensioni).
4. **Il server distrugge insieme.** Un pianeta condiviso; quando esplode piove il bottino per tutti.
5. **Produzione minima.** Tutto è generato da codice: mondo, pianeti, facce, effetti. Zero animazioni del personaggio custom, zero mesh obbligatorie.

## 2. La mappa (stile Asgard, forma a serratura lungo l'asse del pianeta)

1. **Dietro — quartiere delle case**: mezzaluna di marmo e oro con le 8 case dei giocatori in arco, torri dorate
   affusolate e lo spawn.
2. **Al centro — Campo dei Meteoriti**: altopiano rotondo di roccia vulcanica con crepe arancioni e crateri; al centro
   l'Altare del Cielo con un raggio viola verso un vortice da cui piovono i meteoriti. Rampe verso le case.
3. **Davanti — Bifrost**: lungo ponte di vetro cosmico scuro pieno di "glitch" di luce (ciano, magenta, oro) che
   sfarfallano, con due torri dorate all'ingresso; finisce alla Piattaforma di Lancio (cupola dorata, 4 pad).

Sotto c'è solo il vuoto (cadere = respawn). Tutto il testo del gioco è in inglese.

## 3. Ciclo di gioco (5 minuti)

| Fase | Durata | Cosa succede |
|---|---|---|
| ☄️ Pioggia | 60 s | Meteoriti neonati cadono sulla cittadella. Chi li raccoglie per primo li tiene. |
| 🌈 Bombardamento | 240 s | Il pianeta è in tiro. I giocatori corrono sui ponti e lanciano i meteoriti dei propri altari. |

- Il pianeta **conserva la vita** tra un ciclo e l'altro finché non viene distrutto.
- Quando esplode: pioggia bonus di meteoriti con fortuna aumentata, Frammenti per tutti i contributori, arriva il pianeta successivo.
- In Studio i tempi sono accorciati (20 s / 60 s) per testare.

## 4. Il lancio

1. Il giocatore entra sul Pad di Lancio in fondo a un Ponte Stellare durante il Bombardamento.
2. **Decollo istantaneo** (0,3 s): si solleva sopra il vuoto, la camera inquadra il pianeta da sopra la spalla,
   il personaggio alza le braccia (posa procedurale visibile a tutti) e il meteorite appare sopra la testa.
3. **Mira**: un mirino segue il mouse (o il dito); una scia di puntini mostra la traiettoria. Il meteorite va
   esattamente dove miri; se manchi il pianeta finisce sul bordo più vicino.
4. **Carica**: tenendo premuto, l'anello attorno al mirino si riempie avanti e indietro. Rilasciare nei segmenti
   dorati (≥ 88%) = **CRITICO** (x2). Il meteorite si gonfia, la camera trema e stringe lo zoom.
5. **Volo**: camera che insegue il meteorite, poi inquadratura laterale cinematografica dell'impatto (click per saltarla).
6. **Impatto**: lampo, doppia onda d'urto sulla superficie, fuoco, fumo, scintille, rocce e le **placche della crosta
   che volano nello spazio** scoprendo il mantello incandescente. Numero di danno gigante.
7. Il giocatore torna all'inizio del ponte; il meteorite torna all'altare stordito (ricarica). `Q` annulla il lancio.

### Formula del danno

```
danno = DannoBase(tipo)
      × (0,4 + 0,6 × crescita)          -- crescita 0..1 sull'altare
      × Moltiplicatore mutazione
      × (0,5 + carica)                   -- carica 0..1
      × (2 se critico)
      × (1 + √Potere / 25)
      × (1 + 0,10 × livello upgrade Potenza)
      × Moltiplicatore Evoluzione
      × (3 se Ira Divina attiva)
```

## 5. Meteoriti

### Rarità (probabilità per meteorite caduto)

| Rarità | Peso | Colore |
|---|---|---|
| Comune | 60 | grigio |
| Non comune | 25 | verde |
| Raro | 10 | blu |
| Epico | 4 | viola |
| Leggendario | 0,9 | oro |
| Mitico | 0,1 | rosso/rosa |

### Tipi (v0.1)

| Tipo | Rarità | Faccia | Danno base | Crescita |
|---|---|---|---|---|
| Pebble | Comune | normale | 40 | 2 min |
| Ember | Comune | normale | 45 | 2 min |
| Frost | Non comune | normale | 70 | 4 min |
| Spark | Non comune | normale | 75 | 4 min |
| Venom | Raro | corna | 120 | 8 min |
| Crystal | Raro | normale | 130 | 8 min |
| Magma | Epico | corna | 220 | 15 min |
| Aurora | Epico | normale | 240 | 15 min |
| Solar | Leggendario | corona | 450 | 30 min |
| Royal Comet | Leggendario | corona | 500 | 30 min |
| Void | Mitico | ciclope | 1000 | 60 min |
| Supernova | Mitico | occhiali da sole | 1100 | 60 min |
| Blue Comet | Epico (esclusivo Starter Pack, non scambiabile) | occhiali da sole | 260 | 15 min |

### Mutazioni (tirate alla caduta)

| Mutazione | Probabilità | Moltiplicatore |
|---|---|---|
| Dorato | 4% | x2 |
| Arcobaleno | 0,8% | x3 |
| Eclissato | 0,2% | x5 |

### Crescita
- I meteoriti crescono **solo sull'altare**, anche offline (timestamp).
- Crescita 0 → 1 nel tempo indicato dal tipo. Più cresce, più è grande, arrabbiato e forte.
- Ogni meteorite sull'altare aumenta anche il guadagno di Potere al secondo.

### Espressioni
- `sleepy` (appena nato, crescita < 30%), `happy` (crescita < 100%), `angry` (adulto), `furious` (durante la carica), `dizzy` (in ricarica dopo un lancio).

## 6. Progressione

### Potere Divino (+1 al secondo)
`Potere/s = 1 × Evoluzione × (1 + 0,5 × Ascensioni) × (2 con Pass) × (2 con Boost) × (1,2 VIP) × (1 + bonus altare)`

### Evoluzioni Divine

| # | Nome | Potere richiesto | Pianeti | Moltiplicatore | Aspetto |
|---|---|---|---|---|---|
| 1 | Star Spirit | 0 | 0 | x1 | aura bianca |
| 2 | Minor Deity | 500 | 1 | x1,5 | aureola |
| 3 | Demigod | 5.000 | 5 | x2,5 | ali di luce |
| 4 | Titan | 50.000 | 15 | x4 | corona, avatar x1,2 |
| 5 | Cosmic God | 500.000 | 40 | x7 | anelli, avatar x1,3 |
| 6 | Supreme Deity | 5.000.000 | 100 | x12 | aura galattica, avatar x1,4 |

### Ascensione (rebirth)
- Disponibile dall'Evoluzione 4.
- Azzera Potere ed Evoluzione. +50% Potere/s permanente per ogni Ascensione.

### Upgrade (con i Frammenti Stellari)

| Upgrade | Effetto per livello | Max |
|---|---|---|
| Velocità | +2 velocità di corsa | 10 |
| Potenza | +10% danno | 10 |
| Ricarica | −8% tempo di ricarica | 10 |
| Fortuna | +2% probabilità che un meteorite raccolto salga di rarità | 10 |

### Valute
- **Potere**: statistica che cresce sempre, non si spende.
- **Frammenti Stellari**: guadagnati colpendo e distruggendo pianeti e vendendo meteoriti. Si spendono negli upgrade.

## 7. Pianeti

Pianeti grandi (raggio 420 stud) e lontani (~2.300 stud dai ponti), generati da codice:
- **Crosta**: icosfera di 320 placche tettoniche colorate per bioma (rumore + calotte polari + venature/lava al neon).
  Ogni impatto rimuove le placche più vicine (cratere vero) e scopre il mantello. Placche rimosse proporzionali alla vita persa.
- **Mantello**: sfera incandescente che si rimpicciolisce e si scurisce, poi esplode in schegge.
- **Nucleo**: pulsa; a zero → supernova con lampo accecante, onde d'urto e frammenti per tutto il server.
- **Atmosfera**: alone luminoso (materiale ForceField). Il Legendary Planet ha un anello.

Sequenza: Roccioso → Ghiaccio → Lava → Caramella → Crystal → Ombra; poi si ricomincia con vita ×2,5.
Vita = VitaBase × (0,6 + 0,4 × giocatori presenti all'arrivo). Quota vita: crosta 55%, mantello 35%, nucleo 10%.
Il server decide le placche rimosse; tutti gli effetti (detriti, esplosioni, voli) sono calcolati sui client.

## 8. Trading

- **Scambiabili**: meteoriti nel Deposito (non sull'altare), ottenuti giocando.
- **Non scambiabili**: Potere, Evoluzione, upgrade, meteoriti ottenuti con Robux (es. Blue Comet).
- **Flusso**: richiesta → finestra con le due offerte (max 8 oggetti a testa) → entrambi confermano → 3 secondi di conto alla rovescia → il server rivalida e scambia tutto insieme o niente → salvataggio immediato dei due profili.
- **Protezioni**: server autoritativo, cambio offerta = conferme annullate, richiesto almeno Evoluzione 2, cooldown tra richieste, cronologia ultimi 20 scambi nel profilo, session lock sul salvataggio.

## 9. Monetizzazione

### Game Pass
| Pass | Prezzo suggerito | Effetto |
|---|---|---|
| VIP | 299 | +20% Potere/s, tag VIP |
| 2x Potere | 199 | Potere/s ×2 |
| 2x Frammenti | 149 | Frammenti ×2 |
| Altare Extra | 149 | +1 slot altare (3 → 4) |

### Developer Products
| Prodotto | Prezzo suggerito | Effetto |
|---|---|---|
| Starter Pack | 99 | Blue Comet esclusiva + 5.000 Frammenti + Boost 2x Potere 1 h (una volta sola) |
| Potere S / M / L | 49 / 199 / 799 | 10 min / 1 h / 6 h di Potere al ritmo attuale |
| Boost 2x Potere 30 min | 79 | Potere ×2 per 30 minuti |
| Ira Divina | 249 | Tutto il server fa danno ×3 per 3 minuti, compratore annunciato |
| Evoca Legendary Planet | 599 | Arriva subito un pianeta leggendario per tutto il server |
| Ricarica Istantanea | 29 | Tutti i tuoi meteoriti tornano pronti |
| Evolvi Subito | 149 | Passi all'Evoluzione successiva |

### Regole
- Offerte mostrate nei momenti positivi (dopo il primo pianeta distrutto), mai dopo una sconfitta.
- Nessun acquisto casuale a pagamento nella v0.1 (niente casse): niente obblighi di probabilità né restrizioni di trading.
- Prezzi in chiaro, una sola valuta di gioco.

## 10. Interfaccia (stile simulator di successo)

- **In alto a sinistra**: contatori 🏆 Pianeti distrutti e 💎 Frammenti.
- **Sinistra**: griglia di pulsanti grandi: Meteoriti, Evoluzione (badge "!" quando puoi evolverti), Potenzia,
  Regalo (timer, poi "RISCATTA!"), Indice, Scambi.
- **In alto al centro**: fase del ciclo con timer + barra vita del pianeta.
- **In alto a destra**: Negozio (solo Robux, schede Offerte / Game Pass) e Menu a tendina
  (Giornaliero, Codici, Impostazioni, Nascondi HUD).
- **Destra**: offerte in evidenza (Pacchetto Iniziale, 2x Potere, Ira Divina) con "SOLO R$ X".
- **In basso**: Potere totale e Potere/s, barra dell'Evoluzione (MAX all'ultima), 4 acquisti rapidi di Potere/Boost.
- Pannelli separati: Evoluzione (attuale → prossima, requisiti, Evolvi / Salta Evoluzione R$ / Ascendi),
  Potenziamenti (Frammenti), Indice collezione, Premi giornalieri, Codici, Impostazioni.

## 11. Ritorno giornaliero

- **Premi giornalieri** (7 giorni, giorno 7 = grande ricompensa: meteorite Epico + 10.000 Frammenti).
  Saltare un giorno non azzera la serie. Il calendario si apre da solo quando c'è un premio.
- **Regalo a tempo**: ogni 10 minuti di gioco (45 s in Studio) un regalo di Frammenti.
- **Codici**: in `src/shared/Config/Rewards.lua` (RELEASE, METEORGODS).

## 12. Case dei giocatori

Ogni giocatore ha un Santuario sul suo spot. Con i modelli in `Assets/Houses/House1..6` il santuario
**cresce con l'Evoluzione** e i meteoriti fluttuano sugli slot del modello. Vedi `docs/ASSET_PIPELINE.md`.

## 13. Roadmap

- **v0.1 (questa)**: cittadella, ponti, ciclo, pioggia, altari e crescita, lancio, pianeti a strati, Potere +1, evoluzioni, ascensione, upgrade, negozio, trading, salvataggi.
- **Prossimo**: suoni e animazioni (ID in `Config/Assets.lua`), eventi cosmici (Eclissi → mutazioni), indice con ricompense, classifica globale, maxischermo replay nell'hub.
- **v0.2 (fatto)**: nuova interfaccia, premi giornalieri, regalo a tempo, codici, indice, hook per modelli/animazioni/suoni.
- **v0.3**: forziere gruppo, negozio facce a rotazione, Auto-Lancio, Pioggia di Meteoriti acquistabile.
- **Settimanale**: un pianeta nuovo + 1–2 meteoriti nuovi.
