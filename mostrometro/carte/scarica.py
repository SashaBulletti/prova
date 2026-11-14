#!/usr/bin/env python3
"""Scarica i disegni elencati in lavori/urls.txt ("numero url" per riga) e li salva in disegni/NNN.jpg (800 px)."""
import io, os, subprocess
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
fatti = 0
for riga in open(os.path.join(QUI, "lavori", "urls.txt")):
    if not riga.strip():
        continue
    n, url = riga.split()
    dest = os.path.join(QUI, "disegni", f"{int(n):03d}.jpg")
    if os.path.exists(dest):
        continue
    dati = subprocess.run(["curl", "-sSfL", url], capture_output=True, check=True).stdout
    Image.open(io.BytesIO(dati)).convert("RGB").resize((800, 800), Image.LANCZOS).save(dest, "JPEG", quality=86)
    png = os.path.join(QUI, "disegni", f"{int(n):03d}.png")
    if os.path.exists(png):
        os.remove(png)
    fatti += 1
print("scaricati", fatti, "- disegni pronti:", len([f for f in os.listdir(os.path.join(QUI, "disegni")) if f.endswith(".jpg")]))
