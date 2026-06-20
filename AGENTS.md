# Agent guidance for Light Rewrite

Read any per-directory README files.

## Repository overview

Light Rewrite is a Witcher 3 (Next-Gen) mod written in WitcherScript. It adjusts light source properties at runtime so that candles, torches, and similar entities behave well under modern ray-traced lighting - without editing game level files.

| Directory | Purpose |
|-----------|---------|
| `bin/` | In-game options menu definition (`LightRewrite.xml`) |
| `build/` | Packaged mod; output from `build.ps1` |
| `data/` | Source XML light profiles and XSD schema |
| `debug/` | Debug scripts (not distributed) |
| `debug/editor/` | Light-authoring overlay |
| `l10n/` | Translations and generated `.w3strings` binaries |
| `src/` | Mod source code |
| `tmp/` | Local temp dir & build cache |
| `tools/` | Developer utilities |
