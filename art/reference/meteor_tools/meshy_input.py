# Square front-view crop of the reference sheet, used as the Meshy image-to-3D input (step 1 of 4).
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from imgutil import load, save
import numpy as np
ref = load(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "meteor_base.png"))[..., :3]
c = ref[14:588, 20:790]                     # front view panel only
bg = np.median(np.concatenate([c[:15].reshape(-1, 3), c[-15:].reshape(-1, 3)]), 0)
h, w = c.shape[:2]
S = max(h, w) + 60
sq = np.ones((S, S, 3), np.float32) * bg
sq[(S - h) // 2:(S - h) // 2 + h, (S - w) // 2:(S - w) // 2 + w] = c
save(sq, os.path.dirname(__file__) + "/meshy_front.png")
print("saved", sq.shape, "bg", bg)
