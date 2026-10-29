import bpy, numpy as np

def load(path):
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    a = a.reshape(h, w, 4)[::-1]  # top-down rows
    bpy.data.images.remove(img)
    return a

def save(a, path):
    h, w = a.shape[:2]
    if a.shape[2] == 3:
        a = np.concatenate([a, np.ones((h, w, 1), np.float32)], 2)
    img = bpy.data.images.new("tmp", w, h, alpha=True)
    img.pixels.foreach_set(np.ascontiguousarray(a[::-1]).ravel())
    img.filepath_raw = path
    img.file_format = 'PNG'
    img.save()
    bpy.data.images.remove(img)

def crop(a, x0, y0, x1, y1, scale=1):
    c = a[y0:y1, x0:x1]
    if scale > 1:
        c = c.repeat(scale, 0).repeat(scale, 1)
    return c
