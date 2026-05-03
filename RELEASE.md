## Creating a Release

### Via GitHub Actions

Run the "Create Mod Release" workflow from the Actions tab:

- Enter a release tag (e.g., `v1.0.0`)
- Optionally provide a release name
- Check/uncheck the pre-release option
- The workflow creates a draft release with the zip attached

## Create Release Process

The steps required to build a release package.

### Initial configuration

- Copy `.env.example` to `.env`, and edit the values

### Release Package Structure

The mod release is a zip file containing the source files in a specific folder structure:

```
modLightRewrite-<tag>.zip
├── bin/
│   └── config/
│       └── r4game/
│           └── user_config_matrix/
│               └── pc/
│                   └── LightRewrite.xml
└── mods/
    └── modLightRewrite/
        └── content/
            ├── *.w3strings
            ├── blob0.bundle
            ├── metadata.store
            └── scripts/
                └── local/
                    └── modLightRewrite/
                        └── [Witcher scripts from src/]
```

### Steps to Create a Release

High level overview of the build process. For actual steps, see build scripts.

1. **Localisation (when needed)** — If you changed plain-text translations, regenerate the matching `w3strings` binaries before building; see `l10n/README.md`.
2. **Stage scripts** — Copy the Witcher sources from `src/` into the mod script tree under `mods/`.
3. **Stage localisation** — Copy the `w3strings` files from `l10n/` into the mod's `mods/modLightRewrite/content/` folder.
4. **Bundle** — Run `wcc_lite pack` so the staged gameplay XML under `build/bundle/` is written as bundle files in the mod `mods/modLightRewrite/content/` folder.
5. **Metadata store** — Run `wcc_lite metadatastore` on `mods/modLightRewrite/content/` to generate `metadata.store`.
6. **Package** — Produce one zip whose root contains both `mods` and `bin`, matching the layout above.

### Build requirements

- PowerShell 7: `winget install -e --id Microsoft.PowerShell`
