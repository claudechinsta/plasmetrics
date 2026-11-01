# Plasmetrics

Plasma 6 system monitor widget. QML in `contents/ui/`, settings schema in `contents/config/main.xml`, data collected by `contents/code/stats.sh`.

Never change the `Id` in `metadata.json`: it ties placed widgets and their settings to the package.

## "Deploy"

When the user says "deploy", do these in order:

1. **Release notes**: make sure `CHANGES.md` has a `## <version>` section matching `Version` in `metadata.json` (the release workflow reads the notes by that heading). Write short, user-facing bullets.
2. **Store description**: update `store-description.txt` (the KDE Store listing text, pasted there by hand) if features changed, and show it to the user.
3. **Build**: run `python3 tools/build-plasmoid.py`. It writes `dist/plasmetrics-<version>.plasmoid`, the file to upload to the KDE Store. `dist/` is gitignored. Tell the user the path.
4. **Commit**: commit all changes on the current branch.
5. **Push and tag**: push the branch, then create the annotated tag `v<version>` and push it. The tag triggers the GitHub release workflow, which publishes the release with the `CHANGES.md` notes. Skip the tag if it already exists.

Uploading the `.plasmoid` to the KDE Store is done by the user by hand.

## Testing locally

```
kpackagetool6 -t Plasma/Applet -u .
systemctl --user restart plasma-plasmashell
```
