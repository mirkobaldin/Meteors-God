# Comete nuove: 5 famiglie × 5 rarità (25 comete)

Tutte hanno la **stessa mesh base** (`art/reference/meteor_base.glb`): palla di placche di roccia, sopracciglia di
pietra ricce stile Gear 5, occhi e bocca scavati, nucleo luminoso che si vede dalle crepe. Cambiano roccia, colori,
colore del nucleo e le cose che **crescono dalla roccia** (mai accessori). Più è rara, più è elaborata:
Comune = base + colore della famiglia · Rara = prime escrescenze · Epica = corazza / elementi grossi ·
Leggendaria = cresta regale · Mitica = trasformata, pezzi che fluttuano, nucleo spettacolare.
La **Mitica** di ogni famiglia è la testa dell'**arma** di quella famiglia.

| Famiglia | Comune | Rara | Epica | Leggendaria | Mitica (arma) |
|---|---|---|---|---|---|
| 🔥 **Inferno** (vulcani) | Cinderling | Magmaw | Pyroclast | Solar Tyrant | Phoenix Nova → *Phoenix Nova Hammer* |
| ❄️ **Glacier** (ghiaccio) | Frostling | Hailbreaker | Glacierfang | Aurora Warden | Absolute Zero → *Absolute Zero Lance* |
| ⚡ **Storm** (tempesta) | Staticle | Thunderhorn | Tempest Eye | Storm Sovereign | Ion Leviathan → *Ion Leviathan Mace* |
| ☣️ **Toxic** (palude aliena) | Sporeling | Venomspike | Plague Bloom | Hive Queen | Blight Titan → *Blight Maul* |
| 🌌 **Void** (cosmo oscuro) | Duskstone | Shadowfang | Nebula Maw | Eclipse Lord | Galaxy Singularity → *Singularity Scythe* |

Descrizioni complete (in inglese, usate da Codex e Meshy): `art/concepts/comets/comets.json`.

Idee per una 6ª famiglia, se la vuoi: **Celestial** (stelle e oro): Stardust · Comet Knight · Constellation ·
Royal Comet · Galaxy Emperor.

## Pipeline
1. **Codex** → immagini di ogni cometa (frontale + 3/4) partendo dalla mesh base: `docs/PROMPT_CODEX_COMETE.md`.
2. Approvi le immagini.
3. **Claude Code locale con la chiave API di Meshy** → modelli 3D da quelle immagini: `docs/PROMPT_MESHY.md`.
4. La sessione cloud collega le 25 comete al gioco (config, nucleo Neon, mascella, pupille, export, famiglie e armi).
