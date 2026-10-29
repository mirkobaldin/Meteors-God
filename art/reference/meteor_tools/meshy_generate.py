# Generate the raw meteor sculpt with Meshy image-to-3D from the front view of meteor_base.png.
# usage (any Python with requests, e.g. Blender's bundled one):
#   set MESHY_API_KEY=msy_...      (never commit the key)
#   python meshy_generate.py       -> meshy_meteor.glb next to this script (run meshy_input.py first)
import base64, json, os, sys, time
import requests

HERE = os.path.dirname(os.path.abspath(__file__))
API = "https://api.meshy.ai/openapi/v1/image-to-3d"
KEY = os.environ.get("MESHY_API_KEY")
if not KEY:
    sys.exit("set MESHY_API_KEY first")
H = {"Authorization": "Bearer " + KEY}

with open(os.path.join(HERE, "meshy_front.png"), "rb") as f:
    img = "data:image/png;base64," + base64.b64encode(f.read()).decode()
# symmetric face, full-detail raw mesh, no texture (materials come from BlendKit)
body = {"image_url": img, "ai_model": "latest", "symmetry_mode": "on", "should_remesh": False, "should_texture": False}
r = requests.post(API, headers=H, json=body, timeout=60)
r.raise_for_status()
task = r.json()["result"]
print("task", task)
while True:
    d = requests.get(API + "/" + task, headers=H, timeout=30).json()
    print(d.get("status"), d.get("progress"), flush=True)
    if d.get("status") == "SUCCEEDED":
        g = requests.get(d["model_urls"]["glb"], timeout=300)
        with open(os.path.join(HERE, "meshy_meteor.glb"), "wb") as f:
            f.write(g.content)
        print("saved meshy_meteor.glb")
        break
    if d.get("status") in ("FAILED", "CANCELED"):
        sys.exit(json.dumps(d.get("task_error")))
    time.sleep(15)
