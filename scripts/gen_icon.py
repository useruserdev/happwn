#!/usr/bin/env python3
"""Generate the happwn app icon (open padlock = decrypt) with Pillow.

Outputs:
  ios/happwn/Assets.xcassets/AppIcon.appiconset/AppIcon.png  (1024, RGB, full-bleed)
  assets/icon.png                                            (1024, rounded, alpha)
"""
import os
from PIL import Image, ImageDraw, ImageFilter

S = 1024
CX = S // 2
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def gradient():
    """Smooth diagonal gradient via a 2x2 upscale."""
    g = Image.new("RGB", (2, 2))
    g.putpixel((0, 0), (124, 58, 237))   # violet (top-left)
    g.putpixel((1, 0), (91, 88, 246))    # indigo (top-right)
    g.putpixel((0, 1), (37, 99, 235))    # blue   (bottom-left)
    g.putpixel((1, 1), (56, 189, 248))   # sky    (bottom-right)
    return g.resize((S, S), Image.BILINEAR).convert("RGBA")


def add_glow(img):
    """Soft white highlight in the upper-left for depth."""
    glow = Image.new("L", (S, S), 0)
    ImageDraw.Draw(glow).ellipse(
        [-S * 0.25, -S * 0.30, S * 0.65, S * 0.60], fill=255
    )
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.10)).point(lambda v: int(v * 0.28))
    white = Image.new("RGBA", (S, S), (255, 255, 255, 255))
    return Image.composite(white, img, glow)


def draw_lock(layer, color, dy=0):
    """Draw an open padlock (body + lifted shackle) onto `layer` in `color`."""
    d = ImageDraw.Draw(layer)
    t = 62  # shackle thickness

    # --- shackle on its own layer so we can rotate it "open" ---
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    box = [CX - 150, 318, CX + 150, 618]            # top arch
    sd.arc(box, start=180, end=360, fill=color, width=t)
    # two legs going down from the arch ends
    sd.rounded_rectangle([CX - 150 - t // 2, 468, CX - 150 + t // 2, 600],
                         radius=t // 2, fill=color)
    sd.rounded_rectangle([CX + 150 - t // 2, 468, CX + 150 + t // 2, 600],
                         radius=t // 2, fill=color)
    # rotate around the left leg so the right side lifts up = unlocked
    sh = sh.rotate(24, resample=Image.BICUBIC, center=(CX - 150, 560))
    layer.alpha_composite(sh, (0, dy))

    # --- body ---
    d.rounded_rectangle([CX - 230, 556 + dy, CX + 230, 904 + dy],
                        radius=72, fill=color)


def keyhole(layer):
    """Punch a keyhole (circle + tapered slot) out of the lock body."""
    d = ImageDraw.Draw(layer)
    cyc = 706
    d.ellipse([CX - 52, cyc - 52, CX + 52, cyc + 52], fill=(0, 0, 0, 0))
    d.polygon([(CX - 30, cyc + 8), (CX + 30, cyc + 8),
               (CX + 52, cyc + 150), (CX - 52, cyc + 150)], fill=(0, 0, 0, 0))


def build():
    img = add_glow(gradient())

    # drop shadow under the lock
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_lock(shadow, (10, 16, 60, 150), dy=22)
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    img = Image.alpha_composite(img, shadow)

    # white lock with a transparent keyhole, composited over the background
    lock = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_lock(lock, (255, 255, 255, 255))
    keyhole(lock)
    img = Image.alpha_composite(img, lock)

    # iOS app icon: full-bleed square, no alpha (system applies the mask)
    appicon_dir = os.path.join(ROOT, "ios", "happwn", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(appicon_dir, exist_ok=True)
    img.convert("RGB").save(os.path.join(appicon_dir, "AppIcon.png"))

    # rounded variant with alpha for README / About
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=224, fill=255)
    rounded = img.copy()
    rounded.putalpha(mask)
    assets_dir = os.path.join(ROOT, "assets")
    os.makedirs(assets_dir, exist_ok=True)
    rounded.save(os.path.join(assets_dir, "icon.png"))

    print("wrote", os.path.join(appicon_dir, "AppIcon.png"))
    print("wrote", os.path.join(assets_dir, "icon.png"))


if __name__ == "__main__":
    build()
