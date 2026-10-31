#!/usr/bin/env python3
"""Build dist/plasmetrics-<version>.plasmoid from the package files."""
import json, os, zipfile

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(root)
version = json.load(open("metadata.json"))["KPlugin"]["Version"]
out = f"dist/plasmetrics-{version}.plasmoid"
os.makedirs("dist", exist_ok=True)
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for f in ("metadata.json", "LICENSE"):
        z.write(f)
    for base, _, files in os.walk("contents"):
        for f in sorted(files):
            z.write(os.path.join(base, f))
print(out)
