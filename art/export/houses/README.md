# Export case

`House1.fbx` ... `House6.fbx` sono i modelli per il 3D Importer di Roblox Studio.
I file `.glb` contengono la stessa geometria e i materiali PBR per anteprima e scambio.

Ogni casa contiene `Base`, `Sign` e mesh raggruppate per materiale. Le texture PNG sono incorporate; una copia condivisa si trova in `textures/`.

I sorgenti modificabili e la guida completa sono in [`../../blender/houses/README.md`](../../blender/houses/README.md).
Per vedere tutte le case, aprire `art/blender/houses/Houses_Collection.blend`.

`validation.json` riporta i controlli su nomi, texture, dimensioni, ingombri e triangoli, inclusa la reimportazione FBX/GLB in Blender.
Prima dell'uso nel gioco, configurare in Studio materiali Glass/Neon, ancoraggio e collisioni come descritto nella guida.
