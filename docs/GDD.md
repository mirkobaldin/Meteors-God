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

## 2. La mappa: il Bordo dell'Universo

- **Cittadella degli Dei**: piattaforma circolare fluttuante (raggio ~120 stud) sospesa nel vuoto. Notte stellata, luce viola/blu.
- **Altari** (8, uno per giocatore) disposti ad anello: mostrano i meteoriti del giocatore, che crescono qui.
- **Hub centrale**: punto di spawn.
- **Ponti Stellari** (4): piste di energia stile Bifrost che partono dal bordo e si interrompono nel vuoto. In fondo c'è il **Pad di Lancio**.
- **Il Vuoto**: oltre i ponti, il pianeta bersaglio fluttua lontano. Sotto la cittadella c'è il nulla (cadere = respawn).

## 3. Ciclo di gioco (5 minuti)

| Fase | Durata | Cosa succede |
|---|---|---|
| ☄️ Pioggia | 60 s | Meteoriti neonati cadono sulla cittadella. Chi li raccoglie per primo li tiene. |
| 🌈 Bombardamento | 240 s | Il pianeta è in tiro. I giocatori corrono sui ponti e lanciano i meteoriti dei propri altari. |

- Il pianeta **conserva la vita** tra un ciclo e l'altro finché non viene distrutto.
- Quando esplode: pioggia bonus di meteoriti con fortuna aumentata, Frammenti per tutti i contributori, arriva il pianeta successivo.
- In Studio i tempi sono accorciati (20 s / 60 s) per testare.

## 4. Il lancio

1. Il giocatore arriva sul Pad di Lancio in fondo a un Ponte Stellare durante il Bombardamento.
2. Il server sceglie il miglior meteorite **pronto** del suo altare e lo fa apparire sopra la sua testa.
3. Il giocatore si solleva in aria sopra il vuoto, l'aura si accende (colore = Evoluzione).
4. **Carica**: tenendo premuto, una barra oscilla 0 → 1 → 0. Rilasciare nella zona dorata (≥ 88%) = **CRITICO** (x2).
5. Il meteorite parte (volo ~1,2 s), la telecamera lo segue, impatto, numero di danno, cratere col nome.
6. Il giocatore torna all'inizio del ponte. Il meteorite torna all'altare **stordito** (ricarica).

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
| Sassolino | Comune | normale | 40 | 2 min |
| Brace | Comune | normale | 45 | 2 min |
| Gelo | Non comune | normale | 70 | 4 min |
| Scintilla | Non comune | normale | 75 | 4 min |
| Veleno | Raro | corna | 120 | 8 min |
| Cristallo | Raro | normale | 130 | 8 min |
| Magma | Epico | corna | 220 | 15 min |
| Aurora | Epico | normale | 240 | 15 min |
| Solare | Leggendario | corona | 450 | 30 min |
| Cometa Regale | Leggendario | corona | 500 | 30 min |
| Vuoto | Mitico | ciclope | 1000 | 60 min |
| Supernova | Mitico | occhiali da sole | 1100 | 60 min |
| Cometa Blu | Epico (esclusivo Starter Pack, non scambiabile) | occhiali da sole | 260 | 15 min |

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
| 1 | Spirito Stellare | 0 | 0 | x1 | aura bianca |
| 2 | Divinità Minore | 500 | 1 | x1,5 | aureola |
| 3 | Semidio | 5.000 | 5 | x2,5 | ali di luce |
| 4 | Titano | 50.000 | 15 | x4 | corona, avatar x1,2 |
| 5 | Dio Cosmico | 500.000 | 40 | x7 | anelli, avatar x1,3 |
| 6 | Divinità Suprema | 5.000.000 | 100 | x12 | aura galattica, avatar x1,4 |

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

Sequenza (v0.1): Pianeta Roccioso → Pianeta di Ghiaccio → Pianeta di Lava → Pianeta Caramella → Pianeta Cristallo → Pianeta Ombra; poi si ricomincia con vita ×2,5 per giro.

Ogni pianeta ha **3 strati**:
- **Crosta** (55% della vita): 42 blocchi che si staccano vicino agli impatti.
- **Mantello** (35%): si rimpicciolisce e si scurisce, poi esplode in frammenti.
- **Nucleo** (10%): pulsa; a zero → supernova.

Vita = VitaBase × (0,6 + 0,4 × giocatori presenti all'arrivo).

**Pianeta Leggendario**: evocabile con Developer Product, vita alta, ricompense ×3.

## 8. Trading

- **Scambiabili**: meteoriti nel Deposito (non sull'altare), ottenuti giocando.
- **Non scambiabili**: Potere, Evoluzione, upgrade, meteoriti ottenuti con Robux (es. Cometa Blu).
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
| Starter Pack | 99 | Cometa Blu esclusiva + 5.000 Frammenti + Boost 2x Potere 1 h (una volta sola) |
| Potere S / M / L | 49 / 199 / 799 | 10 min / 1 h / 6 h di Potere al ritmo attuale |
| Boost 2x Potere 30 min | 79 | Potere ×2 per 30 minuti |
| Ira Divina | 249 | Tutto il server fa danno ×3 per 3 minuti, compratore annunciato |
| Evoca Pianeta Leggendario | 599 | Arriva subito un pianeta leggendario per tutto il server |
| Ricarica Istantanea | 29 | Tutti i tuoi meteoriti tornano pronti |
| Evolvi Subito | 149 | Passi all'Evoluzione successiva |

### Regole
- Offerte mostrate nei momenti positivi (dopo il primo pianeta distrutto), mai dopo una sconfitta.
- Nessun acquisto casuale a pagamento nella v0.1 (niente casse): niente obblighi di probabilità né restrizioni di trading.
- Prezzi in chiaro, una sola valuta di gioco.

## 10. Roadmap

- **v0.1 (questa)**: cittadella, ponti, ciclo, pioggia, altari e crescita, lancio, pianeti a strati, Potere +1, evoluzioni, ascensione, upgrade, negozio, trading, salvataggi.
- **v0.2**: suoni (asset ID in config), eventi cosmici (Eclissi → mutazioni), indice con ricompense, classifica globale, maxischermo replay nell'hub.
- **v0.3**: calendario 7 giorni, codici, forziere gruppo, negozio facce a rotazione, Auto-Lancio, Pioggia di Meteoriti acquistabile.
- **Settimanale**: un pianeta nuovo + 1–2 meteoriti nuovi.
