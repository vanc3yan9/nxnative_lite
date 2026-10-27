# Lightweight iOS installation

Build any supported game with the normal NSP workflow and `--lite`:

```sh
python3 scripts/build_ipa_from_nsp.py /path/to/game -k /path/to/prod.keys --lite -o /path/to/output/Game.ipa
```

The output is an unsigned `Game.ipa` and `Game-data.zip`. The IPA retains rewritten executable code, shaders, fonts and optional pipeline archives. The ZIP holds `romfs/` and, when supplied, `aoc/`. Each game's bundle embeds its own SHA-256 resource manifest. There is no shared universal executable: build one shell per game and version.

Install the IPA using your own signing method. Open it once to create its document folders. Extract the matching ZIP on your computer, then copy its `romfs` and optional `aoc` folders directly into the app's Documents using Finder file sharing or Files. Do not copy the enclosing ZIP folder or overwrite `save`. Return to the app and select Check and Start.

The first successful check hashes every required resource before starting the game. Later starts use a receipt tied to the bundled manifest; they do not rescan the entire data set. A changed manifest triggers verification again. Replacing files manually after successful verification requires **Recheck game resources** in the launcher and a complete app restart. Deleting `Documents/recheck-data.txt` is not needed: the app consumes it. To request verification without the launcher, create that empty file yourself and restart.

For optional side artwork, pass `--side-art-dir /path/to/art`. Supply `side-background-left.png` and `side-background-right.png`. The launcher's Side artwork toggle defaults to off and remembers the choice. This does not alter game resolution or stretch the game image. Artwork is optional and not distributed by this repository.

Without `--lite`, the existing all-in-one IPA mode is unchanged. Lightweight mode currently supports iOS IPA output, not `--prepare-xcode` or Mac output. The shell still contains game-derived executable and shader data; it is not a game-free public download. Use your own game dumps and keys, and keep generated artifacts outside this repository.

This changes resource delivery, not game compatibility. NVN, Vulkan and OpenGL shader packaging stays on the existing paths. Games still need working nxnative profiles. Real-device gameplay and installation must be tested separately from source compilation and synthetic resource tests.
