# Plasmetrics

Plasma 6 system monitor widget. QML in `contents/ui/`, settings schema in `contents/config/main.xml`, data collected by `contents/code/stats.sh`.

Never change the `Id` in `metadata.json`: it ties placed widgets and their settings to the package.

## "Deploy"

When the user says "deploy", do these in order:

1. **Release notes**: make sure `CHANGES.md` has a `## <version>` section matching `Version` in `metadata.json` (the release workflow reads the notes by that heading). Write short, user-facing bullets.
2. **Build**: run `python3 tools/build-plasmoid.py`. It writes `dist/plasmetrics-<version>.plasmoid`, the file to upload to the KDE Store. `dist/` is gitignored. Tell the user the path.
3. **Commit**: commit all changes on the current branch.

Deploy does not push, tag or publish. Pushing a `v<version>` tag is what runs the GitHub release workflow, so only do that when asked.

## Testing locally

```
kpackagetool6 -t Plasma/Applet -u .
systemctl --user restart plasma-plasmashell
```
