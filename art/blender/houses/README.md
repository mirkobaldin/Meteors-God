# Case moderne di Meteor Gods

Sei modelli Blender modificabili basati sui concept `art/concepts/houses/house1.png` fino a `house6.png`.
Sono interpretazioni 3D stilizzate dei concept: geometria reale con arredi e materiali separati.

| File | Evoluzione | Elementi distintivi |
| --- | --- | --- |
| House1.blend | Star Spirit | Padiglione vetrato, deck di legno, meteorite, due luci da giardino |
| House2.blend | Minor Deity | Due piani, volume superiore a sbalzo, cucina, terrazza e vasca riflettente |
| House3.blend | Demigod | Salone a doppia altezza, stelle sospese, piscina, costellazione e fire pit sul tetto |
| House4.blend | Titan | Tre piani, piscina con cascata, sala trofei, osservatorio con telescopio |
| House5.blend | Cosmic God | Piano superiore sospeso, ponti di vetro, due anelli animati e giardino luminoso |
| House6.blend | Supreme Deity | Atrio centrale, padiglioni laterali, tetti curvi, scale di vetro, cascate e stella armillare |

Aprire `Houses_Collection.blend` per vedere tutte le case affiancate. Gli spostamenti delle radici in questa scena servono solo alla presentazione; nei file singoli ogni casa ha il pivot al centro del pavimento.

## File prodotti

- Sorgenti: `art/blender/houses/House1.blend` ... `House6.blend`.
- Export: `art/export/houses/House1.fbx` ... `House6.fbx` e versioni `.glb`.
- Texture condivise: `art/export/houses/textures/`, PNG 512x512; incluse anche nei file GLB e nei file Blender.
- Anteprime: `art/renders/houses/House1.png` ... `House6.png`, PNG trasparenti 1536x1024.
- Schede da modello reale: `House1_sheet.png` ... `House6_sheet.png` nella stessa cartella, con vista 3/4, frontale, laterale e dall'alto.
- Insieme: `art/renders/houses/Houses_Progression.png`.
- Misure, materiali e triangoli: `art/export/houses/HouseN_manifest.json`.

## Struttura e materiali

I file Blender conservano pezzi, arredi, vetri e luci modificabili. Gli export raggruppano le mesh per materiale, in blocchi inferiori a 12.000 triangoli, mantenendo `Base` e `Sign` separati. `Base` ha origine nel pivot del modello; `Sign` conserva l'origine sulla targhetta accanto all'ingresso, per poterci attaccare il nome del proprietario. La targhetta e vuota.

Materiali PBR: vetro trasmissivo, rovere chiaro, travertino, marmo pallido, oro spazzolato, tessuti, acqua, prato e dettagli emissivi. L'illuminazione e le texture sono incluse nei `.blend`; le luci di presentazione sono nella collezione separata `Presentation`.

In House5 i due anelli completano un giro nei fotogrammi 1-241 (riproduzione 1-240). FBX e GLB sono esportati nella posa iniziale senza animazioni.

## Roblox Studio

1. Importare il file FBX con il 3D Importer di Studio.
2. Usare `House1` ... `House6` come nomi dei Model, `Base` come PrimaryPart e mantenere la targhetta `Sign` separata.
3. Verificare scala e orientamento: 1 unita Blender = 1 stud; fronte Blender -Y; FBX Z forward / Y up, come la pipeline esistente. Raggio di ingombro inferiore a 100 stud per ogni casa.
4. Assegnare ai vetri un materiale Glass e la trasparenza desiderata; assegnare Neon ai dettagli luminosi e alle cascate. La trasmissione e l'emissione dei materiali Blender non sostituiscono le impostazioni Roblox.
5. Ancorare le parti e definire collisioni semplici per pavimenti e scale; disabilitare collisioni di vetri, arredi piccoli, anelli e decorazioni secondo il gameplay. Le curve sono convertite in mesh negli export.
6. Salvare i Model come `assets/Houses/HouseN.rbxm` oppure collocarli in `ReplicatedStorage.Assets.Houses`, secondo `docs/ASSET_PIPELINE.md`.

Gli export sono pronti per l'importazione e la rifinitura in Studio; questa lavorazione non carica asset e non cambia il place. I meteoriti nelle case sono trofei decorativi statici, separati dai meteoriti utilizzabili nel gioco.

## Rigenerazione

```powershell
& 'C:/Program Files/Blender Foundation/Blender 4.4/blender.exe' --background --python art/blender/houses_build.py
```

Opzioni: `-- --only 4`, `-- --no-render`, `-- --overview-only`, `-- --export-only`. La rigenerazione sostituisce gli output generati: salvare eventuali modifiche manuali con un altro nome prima di eseguirla.
