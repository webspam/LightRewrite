# Agent guidance for Light Rewrite

Read any per-directory README files.

## Repository overview

Light Rewrite is a Witcher 3 (Next-Gen) mod written in WitcherScript. It adjusts light
source properties at runtime so that candles, torches, and similar entities behave well
under modern ray-traced lighting - without editing level files.

| Directory | Purpose |
|-----------|---------|
| `bin/` | Game config files - the in-game options menu definition (`LightRewrite.xml`) installed under the Witcher 3 user config matrix path at deploy time |
| `build/` | Generated build output - produced by `build.ps1`; contains the packaged mod (`mods/modLightRewrite/`) ready to deploy into the game's `Mods` folder |
| `data/` | Source XML light profiles (defaults, skellige, vizima_castle, white_orchard) and the XSD schema; copied and prefixed at build time then packed into the mod's content bundle |
| `debug/` | In-game debugging scripts - not part of the distributed mod; `debug/editor/` is a live light-authoring overlay copied in by `debug.ps1` |
| `l10n/` | Localisation - plain-text translation files per locale plus pre-generated `.w3strings` binaries; binaries must be rebuilt manually with `w3strings encoder` when translations change |
| `src/` | WitcherScript mod source; subdirectories: `menu/` (in-game sliders), `rewriter/` (light rewriter classes), `xml/` (XML config loading and match rules) |
| `tmp/` | Local build cache - stores cached `blob0.bundle` / `metadata.store` and XML hash records so `debug.ps1` can skip `wcc_lite` when data files are unchanged |
| `tools/` | Developer utilities; currently contains `Export-Lights.ps1` for exporting light source data from the game |
