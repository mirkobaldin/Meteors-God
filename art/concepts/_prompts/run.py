"""Genera con Codex le immagini di PROMPTS.md che mancano.

Uso (da qualsiasi cartella):
    uv run --no-project python art/concepts/_prompts/run.py              # tutte, una corsia per thread
    uv run --no-project python art/concepts/_prompts/run.py sassolino    # solo le immagini che contengono "sassolino"

Ogni corsia (lane) lavora in ordine, così un'immagine può usare come riferimento quelle prima di lei.
Un'immagine già presente non viene rifatta: per rifarla cancellala.
"""

import glob
import os
import re
import subprocess
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.dirname(os.path.dirname(HERE))
LOGS = os.environ.get("METEOR_LOGS", os.path.join(HERE, "logs"))
CODEX = sorted(glob.glob(os.path.expanduser(
    "~/.vscode/extensions/openai.chatgpt-*/bin/windows-x86_64/codex.exe")))[-1]
TIMEOUT = 20 * 60
MAX_QUOTA_WAITS = 2  # attese per "usage limit" di Codex prima di arrendersi su un'immagine

WRAPPER = """You are generating ONE concept image for the Roblox game Meteor Gods. Use your built-in image generation tool
exactly once (regenerate at most once if the result clearly violates the prompt). The attached images, if any, are
references: the prompt says how to use them. Do not open any other image of the project.
After generating, copy the generated image file to this exact path (create folders if needed): {out}
Do not create, edit or delete any other file. Do not run git or anything else. At the end reply with: the source path of
the generated image, the destination path, and one line on anything in the image that does not follow the prompt.

PROMPT:
{prompt}
"""


def parse(path):
    blocks, images, cur = {}, [], None
    for line in open(path, encoding="utf-8").read().splitlines():
        if line.startswith("# BLOCK "):
            cur = {"kind": "block", "name": line[8:].strip(), "text": []}
            blocks[cur["name"]] = cur
        elif line.startswith("# IMAGE "):
            cur = {"kind": "image", "out": line[8:].strip(), "lane": "1", "blocks": [], "refs": [], "text": []}
            images.append(cur)
        elif cur is None:
            continue
        elif cur["kind"] == "image" and line.startswith(("lane:", "blocks:", "refs:")):
            key, val = line.split(":", 1)
            cur[key] = val.strip() if key == "lane" else val.split()
        else:
            cur["text"].append(line)
    for img in images:
        parts = ["\n".join(blocks[b]["text"]).strip() for b in img["blocks"]]
        parts.append("\n".join(img["text"]).strip())
        img["prompt"] = "\n\n".join(p for p in parts if p)
    return images


def log(msg):
    line = f"{time.strftime('%H:%M:%S')} {msg}"
    print(line, flush=True)
    with open(os.path.join(LOGS, "run.log"), "a", encoding="utf-8") as f:
        f.write(line + "\n")


def quota_wait(logfile, start):
    """Secondi da aspettare se Codex ha risposto 'usage limit' dopo la posizione start del log, altrimenti None."""
    with open(logfile, encoding="utf-8", errors="replace") as f:
        f.seek(start)
        found = re.findall(r'resets_in_seconds\\?":\s*(\d+)', f.read())
    return int(found[-1]) + 90 if found else None


def generate(img):
    out = os.path.join(ART, img["out"]).replace("\\", "/")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    name = img["out"].replace("/", "_")
    logfile = os.path.join(LOGS, name + ".log")
    attempt, waits = 0, 0
    while attempt < 2:
        # i riferimenti si ricalcolano a ogni giro: durante un'attesa possono essere arrivati
        refs = [os.path.join(ART, r).replace("\\", "/") for r in img["refs"]]
        refs = [r for r in refs if os.path.exists(r)]
        cmd = [CODEX, "exec", "--skip-git-repo-check", "-s", "workspace-write", "-C", ART,
               "-o", os.path.join(LOGS, name + ".codex.txt")]
        for r in refs:
            cmd += ["-i", r]
        cmd.append("-")
        attempt += 1
        log(f"START {img['out']} (tentativo {attempt}, riferimenti: {len(refs)})")
        start = os.path.getsize(logfile) if os.path.exists(logfile) else 0
        try:
            with open(logfile, "a", encoding="utf-8") as lf:
                subprocess.run(cmd, input=WRAPPER.format(out=out, prompt=img["prompt"]), text=True,
                               encoding="utf-8", stdout=lf, stderr=subprocess.STDOUT, timeout=TIMEOUT)
        except subprocess.TimeoutExpired:
            log(f"TIMEOUT {img['out']}")
        if os.path.exists(out):
            log(f"OK {img['out']}")
            return True
        wait = quota_wait(logfile, start)
        if wait and waits < MAX_QUOTA_WAITS:
            waits += 1
            attempt -= 1
            log(f"QUOTA esaurita, {img['out']} aspetta {wait // 60} min (fino alle "
                f"{time.strftime('%H:%M', time.localtime(time.time() + wait))})")
            time.sleep(wait)
    log(f"FAIL {img['out']}")
    return False


def lane(items):
    for img in items:
        if not os.path.exists(os.path.join(ART, img["out"])):
            generate(img)


def main():
    os.makedirs(LOGS, exist_ok=True)
    images = parse(os.path.join(HERE, "PROMPTS.md"))
    filters = [a.lower() for a in sys.argv[1:]]
    if filters:
        images = [i for i in images if any(f in i["out"].lower() for f in filters)]
    lanes = {}
    for img in images:
        lanes.setdefault(img["lane"], []).append(img)
    missing = sum(not os.path.exists(os.path.join(ART, i["out"])) for i in images)
    log(f"--- {missing} immagini da fare su {len(images)}, corsie: {', '.join(sorted(lanes))}")
    threads = [threading.Thread(target=lane, args=(items,)) for items in lanes.values()]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    missing = [i["out"] for i in images if not os.path.exists(os.path.join(ART, i["out"]))]
    log(f"--- fine, mancano {len(missing)}: {' '.join(missing)}")


if __name__ == "__main__":
    main()
