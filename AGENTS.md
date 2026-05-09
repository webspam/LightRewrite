# Agent guidance for Light Rewrite

## Most important rule: read the README before touching a directory

**Before making any change in a directory, read the `README.md` in that directory.**
README files contain the context essential for making correct changes — design decisions,
constraints, and behavioural descriptions. They are written for both humans and agents.

Skipping them leads to changes that conflict with existing conventions or break assumptions that are not obvious from the code alone.

This applies at every level: root README, `debug/README.md`, `debug/editor/README.md`, `src/xml/README.md`, and any others. Navigate to the README nearest to the code you are changing and read it first.

### .cursor/rules/

`.cursor/rules/` contains agent rules for this project. The directory is gitignored
(it mixes project-level and local-only rules), but the rules inside are active and
should be followed. Do not delete or recreate the directory.

Before starting work, read the `.mdc` files in `.cursor/rules/` whose `description`
or `globs` fields are relevant to the files you are about to touch. Each file is short
— when in doubt, read it.

## Repository overview

Light Rewrite is a Witcher 3 (Next-Gen) mod written in WitcherScript. It adjusts light
source properties at runtime so that candles, torches, and similar entities behave well
under modern ray-traced lighting — without editing level files.

| Directory | Purpose |
|-----------|---------|
| `bin/` | Game config files — the in-game options menu definition (`LightRewrite.xml`) installed under the Witcher 3 user config matrix path at deploy time |
| `build/` | Generated build output — produced by `build.ps1`; contains the packaged mod (`mods/modLightRewrite/`) ready to deploy into the game's `Mods` folder |
| `data/` | Source XML light profiles (defaults, skellige, vizima_castle, white_orchard) and the XSD schema; copied and prefixed at build time then packed into the mod's content bundle |
| `debug/` | In-game debugging scripts — not part of the distributed mod; `debug/editor/` is a live light-authoring overlay copied in by `debug.ps1` |
| `l10n/` | Localisation — plain-text translation files per locale plus pre-generated `.w3strings` binaries; binaries must be rebuilt manually with `w3strings encoder` when translations change |
| `src/` | WitcherScript mod source; subdirectories: `menu/` (in-game sliders), `rewriter/` (light rewriter classes), `xml/` (XML config loading and match rules) |
| `tmp/` | Local build cache — stores cached `blob0.bundle` / `metadata.store` and XML hash records so `debug.ps1` can skip `wcc_lite` when data files are unchanged |
| `tools/` | Developer utilities; currently contains `Export-Lights.ps1` for exporting light source data from the game |
