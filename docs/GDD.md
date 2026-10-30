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

## 2. La mappa (dallo schizzo del proprietario, scala ×3)

Vista dall'alto, i pianeti sono davanti (+Z). Altezze: case 88 > isolette delle comete 40 > tutto il resto 0.
1. **Isola Centrale** (raggio 480): in mezzo il **Campo di Magma** (raggio 220): crosta di basalto con crepe di lava
   che partono da una pozza centrale (con la scultura della cometa), anello di lava intorno. **Ogni cometa che cade
   scava un cratere** con il fondo fuso che si raffredda in 40 s; il campo si richiude a ogni nuova pioggia.
   Sopra, il vortice da cui piovono. Spawn sul retro, rivolto verso il campo.
2. **Dietro — 12 lotti a ventaglio (200°)**: ponte → **Isoletta delle Comete** (raggio 75, 4 piedistalli dove fluttuano i
   meteoriti dell'altare) → ponte → **Isola della Casa** (raggio 120, tempio segnaposto finché non ci sono i modelli).
   **Imposta Max Players del server = 12** (`Game.World.HouseCount`).
3. **Isole dello Shop e della Classifica** (raggio 180), ognuna con una **montagna alta 420** con cime secondarie e neve.
4. **Davanti — tre Bifrost separati** (a −50°, 0°, +50°), larghi 44, con portale e requisito del tier. Ognuno finisce
   su un hub da cui partono 4 ponticelli verso **4 isolette separate, ognuna con un pad** rivolto al pianeta.
   Shop e Classifica stanno tra i ponti. Sui ponti si corre ×2,2 (velocità base 30).
5. **Sull'isola centrale**: il **Reattore a Fusione** (−330, −150) e il **portale della Cosmic Hunt** (330, −150).

Le isole sono **Terrain** (erba sopra, roccia sotto, coste ondulate), con ~26 isolotti decorativi intorno.
`Game.World.GenerateTerrain = false` se vuoi scolpire tu il terreno nel Terrain Editor di Studio.
I colori dei materiali sono in `Config/Terrain.lua`.

- **Cielo**: il codice cerca lo Sky "Purple Nebula" ovunque l'hai messo (Lighting, Workspace, dentro un modello) e lo
  rende attivo in Lighting. In Output scrive `using skybox: <nome>`, oppure un avviso se non lo trova.
- **Luce**: luce diurna (ClockTime 14,5, sole nascosto) per vedere bene tutto sotto lo skybox.
- **Classifica**: top 10 pianeti distrutti (tutti i server, OrderedDataStore, ogni 2 minuti).
- **Tema "Sky Ruins"** (uguale alla UI): arenaria consumata, rame verde acqua, rune azzurre. Ponti di lastre di pietra
  con cordoli di rame e lanterne a runa; piattaforme di lancio = altari di pietra con cerchio di rune del colore del
  tier e 4 obelischi.
- **Props** (`Assets/Map`): posizioni fisse in `Game.Props.Layout` (statua del dio dietro lo spawn, fontana e lampioni
  sul viale, due giardini ai lati, scultura della cometa nella pozza di lava, lampioni intorno al campo, telescopi
  verso i pianeti, lampade e pilastro del nome su ogni isoletta). Dimensione per prop in `Game.Props.Size`, rotazione
  extra in `Game.Props.Yaw` se un modello è girato.

## 3. Ciclo di gioco (5 minuti)

| Fase | Durata | Cosa succede |
|---|---|---|
| ⏳ Via! | 4 s | Tutti vengono teletrasportati sulla **propria Isoletta delle Comete** e restano fermi: partono tutti dalla stessa distanza. |
| ☄️ Pioggia | 40 s | ~12 comete cadono sul Campo di Magma (una ogni 3,2 s). Chi la prende **la trasporta**: è sua solo quando la riporta sulla sua isola. |
| 🌙 Calma | 256 s | Fino alla prossima pioggia. |

### Portare a casa le comete
- La cometa raccolta fluttua sopra la testa; **diventa tua solo quando metti piede sulla tua Isoletta delle Comete o
  sull'Isola della Casa** (una scia azzurra indica la strada).
- Capienza **1** (Game Pass **Big Bag**: +2). Ogni cometa trasportata rallenta del 10% (minimo 60%).
- Raccogliere richiede di tenere premuto più a lungo per le più rare (0,4 s Comune → 3 s Extraterrestre).
- Chi ti colpisce (**Star Slap** per tutti, armi di rarità più forti) ti fa cadere una cometa trasportata, che chiunque
  può raccogliere. Se muori cadono tutte; se cadi nel vuoto sono perse.

- **Non c'è più un bombardamento a tempo**: i pianeti si colpiscono in qualsiasi momento dai ponti.

- Il pianeta **conserva la vita** tra un ciclo e l'altro finché non viene distrutto.
- Quando esplode: pioggia bonus di meteoriti con fortuna aumentata, Frammenti per tutti i contributori, arriva il pianeta successivo.
- In Studio i tempi sono uguali al gioco vero; `Game.Cycle.FastInStudio = true` li accorcia (20 s / 60 s) per testare.

## 4. Il lancio

1. Durante il Bombardamento il giocatore sale su un pad del suo **tier** (Tier II richiede Demigod, Tier III Cosmic God;
   se non ce l'ha appare un avviso).
2. **Decollo** (0,3 s): si solleva sopra il vuoto. La camera è dietro e di lato, il dio si vede piccolo in basso a
   sinistra, ondeggia, **si gira verso dove miri** e si inclina mentre carica.
3. **Mira**: un **marker rosso 3D sulla superficie del pianeta** mostra esattamente dove cadrà il meteorite (segue
   anche i crateri), con un arco di puntini 3D. Se manchi, il colpo finisce sul bordo più vicino.
4. **Carica**: tieni premuto, l'ago corre avanti e indietro sull'anello. La **zona dorata è stretta (7%) e cambia
   posizione a ogni lancio**: rilasciare lì = **CRITICO**. Se stai già tenendo premuto quando sali sul pad, la carica
   parte subito (prima restavi bloccato).
5. **Volo**: camera che insegue la cometa (che ti guarda urlando), poi inquadratura larga dell'area d'impatto.
6. **Impatto**: lampo, onde d'urto, polvere del colore della crosta, pezzi di pianeta, e **l'effetto dell'elemento**
   (vedi §7). Il server scava un **cratere vero** nel terreno. La camera resta 2,5 s sul cratere (click per saltare).
7. Il giocatore torna al centro della piattaforma; il meteorite torna al piedistallo stordito (ricarica). `Q` annulla.

### Formula del danno

```
danno = DannoBase(tipo)
      × (0,4 + 0,6 × crescita)          -- crescita 0..1 sull'altare
      × Moltiplicatore mutazione
      × (0,5 + carica)                   -- carica 0..1
      × (2 + 0,1 × livello Precisione, se critico)
      × (1 + √Potere / 25)
      × (1 + 0,08 × livello Forza)
      × Moltiplicatore Evoluzione
      × (3 se Ira Divina attiva)
```

## 5. Meteoriti

### Rarità (probabilità per meteorite caduto)

| Rarità | Peso | Colore |
|---|---|---|
| Comune | 62 | grigio |
| Rara | 26 | blu |
| Epica | 9 | viola |
| Leggendaria | 2,5 | oro |
| Mitica | 0,45 | rosa |
| Extraterrestre | 0,05 | verde (solo dal cielo, niente fusione) |

### Tipi (roster v2: ognuno ha corpo e faccia propri, niente scia)

Corpo compatto e tondeggiante (è un proiettile), due occhi sempre, faccia diversa per ognuno. Descrizioni complete
(`look` ed `expression`) in `src/shared/Config/Meteors.lua`.

| Rarità | Comete |
|---|---|
| Comune | Grumble (sasso lunare brontolone) · Cinder (palla di carbone iperattiva) · Flurry (palla di neve dispettosa) · Zap (palla di pelo elettrico) · Sprout (sasso muschioso tranquillo) |
| Rara | Magmaw (basalto e lava, bullo con le zanne) · Gloop (slime tossico pazzo) · Geode (geode furbo, la bocca è la crepa di cristalli) · Puffer (pesce palla spaziale) · Scarab (scarabeo arrotolato a palla) |
| Epica | Aurowl (gufo dell'aurora) · Bastion (cavaliere di vetro nero) · Stormram (ariete di nuvola temporalesca) · Prism (gemma arrogante) · Specter (fantasma inquietante) |
| Leggendaria | Solaris (re sole) · Leviathan (balena dello spazio) · Phoenix (fenice raccolta nelle ali) · Frostfang (drago di ghiaccio) · Midas (oro e gemme, avido) |
| Mitica | Singularity (buco nero con anello) · Supernova (stella che esplode dall'armatura) · Galaxy (galassia in una sfera) · Chrono (orologio cosmico) · Eclipse (metà sole, metà luna) |
| Extraterrestre | Visitor (alieno grigio argentato) · Xenobloom (baccello alieno carnivoro) |

Blue Comet: Epica, esclusiva dello Starter Pack. I salvataggi con i vecchi nomi vengono convertiti (`LEGACY_IDS` in
`DataService`).

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

Nessun livello massimo (tranne Magazzino): il costo cresce piano (`base × crescita^livello`, crescita 1,13–1,25)
e l'effetto continua a salire. Quelli che romperebbero il gioco (velocità, ricarica, fortuna) si avvicinano a un
limite senza mai arrivarci. Bottone **MAX** = compra quanti livelli puoi. Tutto in `Config/Game.lua → Game.Upgrades`.

| Upgrade (nome in gioco) | Effetto totale al livello L | Max |
|---|---|---|
| Swiftness | +30 × (1 − 0,95^L) velocità | — |
| Might | +8% danno × L | — |
| Precision | critico ×(2 + 0,1 × L) | — |
| Recharge | ricarica × (1 − 0,75 × (1 − 0,96^L)), fino a −75% | — |
| Luck | 50% × (1 − 0,97^L) di salire di rarità | — |
| Greed | +6% Frammenti × L | — |
| Altar Energy | +5% Potere/s × L | — |
| Storage | +5 posti × L | 40 |

### Valute
- **Potere**: statistica che cresce sempre, non si spende.
- **Frammenti Stellari**: guadagnati colpendo e distruggendo pianeti e vendendo meteoriti. Si spendono negli upgrade.

## 7. Pianeti (Terrain)

Tre pianeti in cielo insieme, uno per corsia del Bifrost (`Config/Planets.lua → Tiers`):

| Tier | Requisito | Raggio | Sequenza |
|---|---|---|---|
| I (sinistra) | tutti | 520 → 750 | Rocky → Ice → Candy |
| II (centro) | Demigod | 600 → 870 | Lava → Crystal |
| III (destra) | Cosmic God | 680 → 990 | Shadow |

Dopo l'ultimo pianeta di un tier si ricomincia con vita e premi ×2,5. **I pianeti crescono con la vita**:
raggio × (vita / vita del primo)^0,12, massimo ×1,45. Ogni pianeta ha un aspetto suo: anelli (Rocky, Candy, Crystal,
Shadow, Legendary), lune (Rocky, Ice, Shadow), strisce (Candy), spuntoni giganti (Ice, Crystal), vulcani (Lava).
- **Fatti di Terrain**: crosta con i materiali del pianeta e "continenti" di altri materiali, calotte polari, e
  dettagli: **vulcani** con lava e fumo (Lava), **spuntoni di ghiaccio** (Ice), **cristalli** (Crystal), montagne
  innevate e crateri (Rocky), colline alla menta e limone (Candy), spuntoni scuri (Shadow).
- **Strati veri**: sotto la crosta il **mantello** di lava (CrackedLava), al centro una cavità con il **nucleo** al neon.
- **Crateri**: ogni colpo scava una sfera d'aria. Raggio = R × (quota danno × 1,3)^(1/3) tra 5% e 30% di R: la somma
  dei crateri svuota il pianeta. Il bordo viene "bruciato" e resta il **segno dell'elemento**:
  Flurry/Leviathan/Blue Comet → ghiaccio e spuntoni di cristallo; Magmaw/Cinder → lava; Gloop → melma tossica;
  Geode → cristalli; Solaris → vetro dorato; Singularity → buco nero più grande; Supernova → cratere più grande con lava.
- **VFX per elemento** (client): ghiaccio che spunta, schizzi di lava ad arco, fulmini, nube tossica con bolle,
  schegge di cristallo, nastri d'aurora, raggi solari, implosione nera, onde arcobaleno.
- **Arrivo** (2,4 s, stile "terremoto che spacca l'aria"): una **linea sottile** si disegna nello spazio, poi partono
  le **crepe come vetro rotto** (rami + ragnatela) con un'onda d'urto; la crepa **si apre** su un **tunnel azzurro**
  ("quantum leap") da cui esce luce, i **frammenti di vetro** volano via, il pianeta esce in un lampo azzurro (lo
  schermo si tinge di azzurro per un attimo) e la crepa si richiude in una linea.
- Pianeti a ~1.750 stud dalla loro piattaforma (grandi ~40° nel campo visivo). Il terreno del pianeta viene
  creato e cancellato a fette su più frame, così l'esplosione non blocca più il gioco.
- **Fine**: supernova, il pianeta si frantuma in pezzi di crosta e lava; annuncio con chi ha dato il **colpo finale** e l'MVP.

Vita = VitaBase × (0,6 + 0,4 × giocatori presenti all'arrivo). Il Legendary Planet (prodotto) sostituisce il pianeta del Tier I.

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
| Big Bag | 199 | Trasporti 3 comete invece di 1 |

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

- **Grafica tema A "Sky Ruins"** (`art/ui/A`, ID in `Config/Assets.UI.Images`): finestre e pannelli con cornice di
  pietra e rame, bottoni (principale ciano, blu, rosso, grigio = non disponibile) con stati hover/premuto, pillole
  delle valute, barre, carte per rarità nell'Indice, tasto di chiusura, schermata iniziale con logo. Senza gli ID il
  codice torna ai riquadri colorati di prima. Applicata da `Controllers/UI.lua` (UI.Panel, UI.Button, UI.Window).

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

## 12. Lotti dei giocatori

Ogni giocatore ha un lotto: Isoletta delle Comete (i meteoriti dell'altare fluttuano sui piedistalli) + Isola della
Casa. La casa si **migliora al leggio** davanti a lei (finestra "Your House"): 6 livelli, ognuno è un modello
(`Assets/Houses/House1..6`, le ville di Codex) e dà un bonus a Shard e Potere al secondo:

| Livello | Nome | Costo (Shard) | Evoluzione richiesta | Bonus |
|---|---|---|---|---|
| 1 | Star Pavilion | — | Star Spirit | — |
| 2 | Celestial Villa | 2.500 | Minor Deity | +10% |
| 3 | Demigod Residence | 15.000 | Demigod | +20% |
| 4 | Titan Cliff Villa | 90.000 | Titan | +35% |
| 5 | Cosmic Sky Mansion | 500.000 | Cosmic God | +50% |
| 6 | Supreme Palace | 3.000.000 | Supreme Deity | +75% |

## 12a. Meteoriti: equipaggiamento, nutrimento, abilità

- **Equip** (Inventario): il meteorite equipaggiato è il tuo **pet** ed è il primo che lanci (anche se non è sull'altare).
- **Nutrire** con **Stardust ✨** (si guadagna nella Cosmic Hunt): +15% danno e un po' più grande per livello, max 10;
  al livello 5 diventa *Awakened*, al 10 *Ascended*. Costo = 40 × rarità^1,5 × 1,55^livello.
- **Abilità** (una per tipo, in `Config/Meteors.lua`): Burn/Poison/Eruption (danno extra in 3 s), Chain Lightning e
  Nova Blast (secondo colpo), Deep Freeze e Solar Flare (il pianeta prende più danni da tutti per 8 s), Shatter
  (critico più forte), Aurowl/Leviathan (più Frammenti), Rock Solid/Singularity (più danno), Hyperspeed (ricarica dimezzata).
- **Reattore a Fusione**: si sblocca a 3 pianeti distrutti; 3 meteoriti uguali in magazzino → 1 della rarità dopo.

## 12c. Cosmic Hunt (modalità volo)

Portale sull'isola centrale → 120 s nello spazio profondo (6.000 stud sopra la mappa). Telecamera dietro la spalla,
il mouse gira la visuale (bloccato al centro, mirino fisso), WASD vola dove guardi, Spazio su, Ctrl giù, Shift turbo.
Su mobile: joystick per volare, trascini per guardare, tocchi un pianeta per lanciare. Gamepad: levette e R2.
- **Posa**: fermo fluttua con le braccia aperte; in volo veloce si stende col **pugno avanti** stile supereroe; a ogni
  lancio fa lo **swing del braccio**. La cometa equipaggiata sta **in mano** (si vede anche dagli altri) e parte da lì.
- **Pianetini** di Terrain (materiali dei pianeti grandi, nucleo di lava) con **barra della vita**: servono 2-6 colpi
  (comete più rare e nutrite colpiscono più forte); ogni colpo scava un **cratere** quando la cometa arriva.
- **Rottura**: crepe luminose e nucleo che si gonfia per 0,9 s, poi esplode in pezzi; lo **Stardust vola verso di te**.
  Ricompare altrove dopo 4 s con un lampo azzurro. Record personale salvato (`bestHunt`).

## 12b. Extra (fatti)

- **Pet**: la tua cometa migliore ti fluttua accanto, visibile a tutti e girata verso la camera di chi guarda.
- **Titoli** sopra la testa per pianeti distrutti (Planet Cracker 1, Breaker 10, Star Breaker 50, Planet Eater 200,
  World Ender 1000), ✦ per ogni Ascensione e ★ ogni 25 livelli di upgrade.
- **Fusione**: al Reattore a Fusione (vedi 12a).
- **Eventi cosmici** (35% delle piogge): Eclipse (mutazioni ×5), Golden Rain, Meteor Frenzy (doppi meteoriti),
  Lucky Stars (fortuna ×3). Il mondo si colora un po' durante l'evento.
- **Facce 3D**: occhi, pupille, sopracciglia, bocca, guance e accessori sono parti del corpo (non più adesivi).

## 13. Proposte (da decidere)

### Modalità per sfoggiare le comete
1. **Arena dei Meteoriti (1v1 / 4 giocatori)**: ognuno porta 3 comete, a turno si lanciano su uno scudo-pianeta
   avversario. Vince chi lo rompe prima. Rarità e crescita contano, ma mira e critici di più (skill > soldi).
2. **Gara di Distruzione (evento ogni 30 min)**: un PIANETA BOSS gigante per tutto il server, 3 minuti.
   Classifica del danno in diretta; i primi 3 ottengono una mutazione rara garantita.
3. **Sfilata / Concorso di Bellezza**: passerella sul Bifrost, ognuno mette la sua cometa migliore, gli altri
   votano. Premio: titolo "Most Beautiful Comet" e cornice dorata sul profilo. Sfoggio puro, zero potere.
4. **Torre dei Mondi (PvE infinito)**: piani con pianeti sempre più duri, si sale finché si riesce.
   Classifica per piano raggiunto. Ottima per far valere gli upgrade infiniti.
5. **Museo personale**: la casa mostra le comete più rare in vetrine; gli altri possono visitarla e "mettere
   una stella". Classifica delle case più stellate.

### Collezioni per rarità e armi (fatto)
5 rarità (Comune, Rara, Epica, Leggendaria, Mitica) con 5 comete ciascuna + 2 **Extraterrestri** (le più rare, solo
dal cielo). Elenco in `docs/COMETE_FAMIGLIE.md`. Quando trovi **tutte le comete di una rarità** sblocchi la sua arma e
scegli nell'Index quale di quelle comete ne è la testa (Club, Hammer, Lance, Scythe, Mace, Ray Lance).
Chi ti colpisce mentre **trasporti** comete verso casa ti sbalza e **te ne fa cadere una** (vedi "Portare a casa le
comete"). Armi: ricarica 1,1 s, portata 11 stud; Star Slap (tutti): ricarica 1,8 s, portata 7,7 stud. 2,5 s di
immunità; niente colpi su chi sta lanciando o è nella Cosmic Hunt.

### Idee del proprietario (da fare più avanti)
- **Cavalcare la propria cometa** (tipo nuvola Speedy di Goku): si sblocca a una certa Evoluzione (es. Titan).
  La cometa equipaggiata si allarga sotto i piedi e diventa una cavalcatura volante per muoversi per la mappa
  (più veloce del Bifrost); comete più rare = più veloci e con una scia diversa.
- **PvP con comete-arma**: in una futura modalità PvP ogni cometa ha due forme. **Attacco cometa** (la lanci come
  adesso, a distanza) oppure **attacco arma**: la cometa si trasforma in un'arma del suo elemento (Magma → martello
  di lava, Frost → lancia di ghiaccio, Spark → frusta elettrica, Void → falce oscura...). Si cambia forma con un tasto.

### Ancora da fare (dalla lista "più figo")
- Replay al rallentatore del colpo finale su un maxischermo nell'isola centrale.
- Evento Buco Nero che risucchia le comete a terra.
- Effetto visivo sul personaggio per le stelle degli upgrade.

## 14. Roadmap

- **v0.1 (questa)**: cittadella, ponti, ciclo, pioggia, altari e crescita, lancio, pianeti a strati, Potere +1, evoluzioni, ascensione, upgrade, negozio, trading, salvataggi.
- **Prossimo**: suoni e animazioni (ID in `Config/Assets.lua`), eventi cosmici (Eclissi → mutazioni), indice con ricompense, classifica globale, maxischermo replay nell'hub.
- **v0.2 (fatto)**: nuova interfaccia, premi giornalieri, regalo a tempo, codici, indice, hook per modelli/animazioni/suoni.
- **v0.9**: nuova spaccatura (linea → vetro rotto → tunnel azzurro), fix della telecamera bloccata sul pianeta,
  molti meno messaggi (annunci in coda, toast max 2, numeri di danno solo tuoi, i successi degli altri solo in chat),
  Cosmic Hunt rifatta (camera, posa da supereroe, cometa in mano, pianetini di terreno con crateri ed esplosioni),
  prompt di Codex rifatti in stile ville moderne di lusso. Le 13 comete modellate in Blender (script
  `art/blender/meteors_build.py`): niente accessori, corna/creste/cristalli/pinne fanno parte della roccia;
  stile low-poly con crateri e **faccia scavata nella roccia** che brilla da dentro (senza mesh, la faccia a pezzi
  ora ha occhi a fessura luminosi, sopracciglia di roccia a V e denti aguzzi).
- **v0.8**: 12 giocatori, isolette dei pad, ponti più larghi, pianeti diversi che crescono, meno lag, resti sul pad finché lanci, VFX vento e fulmini, equip/nutrire/abilità, facce cattive, Reattore a Fusione, Cosmic Hunt, Stardust.
- **v0.7**: mappa ×3, tre ponti separati con piattaforme da 4 pad, pianeti più grandi e vicini, luce diurna e skybox del proprietario, accessori non più al neon, fine del blocco all'esplosione.
- **v0.6**: mappa dallo schizzo, pianeti di Terrain a 3 tier con crateri e spaccatura, lancio rifatto, VFX per elemento, facce 3D, pet, titoli, fusione, eventi cosmici.
- **v0.5**: terreno, cielo con pianeti/galassie/nebulose, classifica globale, upgrade infiniti (8 tipi).
- **v0.3**: forziere gruppo, negozio facce a rotazione, Auto-Lancio, Pioggia di Meteoriti acquistabile.
- **Settimanale**: un pianeta nuovo + 1–2 meteoriti nuovi.
