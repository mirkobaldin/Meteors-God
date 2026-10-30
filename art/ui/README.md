# Meteor Gods UI art

**Tema scelto: A — Sky Ruins.** Pietra e rame distinguono il tema dei giovani dèi
conservando il contrasto con i bagliori azzurri delle comete. Il kit completo A
comprende 51 PNG; la prova B conserva i 37 PNG delle sezioni 1, 2 e 6.
`status.json` conferma il completamento degli 88 PNG richiesti.
I prompt B con stato `not_selected` sono conservati per eventuali prove future.

La prova confronta **A — Sky Ruins** e **B — Starport**: sezioni 1, 2 e 6,
37 PNG per tema. I nomi e le dimensioni seguono `docs/PROMPT_CODEX_UI.md`.

Le immagini sono generate singolarmente con lo strumento integrato `image_gen`.
`prompts.json` conserva il prompt di ogni file e il percorso della sorgente generata.
`export.ps1` esporta le sorgenti nelle dimensioni richieste, conserva l'alpha,
riserva 48 px di margine alle icone e prepara le cornici e i bottoni per il 9-slice:
centri uniformi, angoli specchiati e bordi centrali ripetibili.
Le tavole `_review/A.png` e `_review/B.png` contengono etichette per il confronto;
non vanno importate nel gioco.
Le tavole `_review/A_icons48.png` e `_review/B_icons48.png` mostrano le icone
esattamente a 48 × 48 px per controllarne la leggibilità su telefono.

## Verifica

Da PowerShell, nella radice del repository:

```powershell
& ./art/ui/export.ps1
& ./art/ui/validate.ps1 -SelectedTheme A -RequireComplete
```

L'esportazione richiede le sorgenti locali registrate in `prompts.json`.
La verifica funziona sui PNG di questo repository senza le sorgenti.
`validation.json` registra dimensioni, alpha, SHA-256 e rettangoli `SliceCenter`.
Per le cornici il rettangolo è `(64, 64, width - 64, height - 64)`;
per i bottoni il margine è 48 px, oppure 47 px per le tab alte 96 px.
Gli stati pressed sono traslati esattamente di 2 px verso il basso: i loro
rettangoli `SliceCenter` hanno entrambe le coordinate Y aumentate di 2 px.
Le pillole usano `(128, 48, 448, 80)` per preservare lo slot icona sinistro;
le barre hanno una sezione centrale ripetibile in orizzontale.
Il tasto di chiusura e le icone usano `ScaleType.Fit`.
Cornici, bottoni, pillole e traccia della barra usano `ScaleType.Slice` con i
rettangoli del report; i riempimenti delle barre usano `ScaleType.Stretch`.
Le sei carte mantengono la sagoma di Common e un'apertura trasparente per
mostrare la cometa sottostante; cambiano intarsi, gemme, colore e bagliore.

## Roblox

I 51 asset A sono caricati in **Dio dei Meteore**, place `79582717445938`.
`uploaded_assets.json` associa ogni nome file alla URI Roblox e al SHA-256 del
PNG caricato. `roblox_validation.json` registra la verifica tramite ImageLabel:
51 asset richiesti, 51 caricati correttamente dal ContentProvider.

Importare soltanto i PNG della cartella del tema scelto.
Le icone corrispondono a `Assets.Icons.<Name>`; le altre immagini a
`Assets.UI.Images.<nome_file_senza_estensione>` in `src/shared/Config/Assets.lua`.
`Assets.Image(id)` restituisce la URI Roblox utilizzabile nelle ImageLabel.
Il toolkit esistente usa già `Assets.Icons`; le altre texture sono disponibili
nel registro per l'applicazione ai rispettivi componenti dell'interfaccia.

Per il caricamento tramite il connettore Studio si può servire la cartella del
tema su `127.0.0.1:18765`, in alternativa all'Asset Manager → Bulk Import:

```powershell
uv run --no-project python -m http.server 18765 --bind 127.0.0.1 --directory art/ui/A
```
