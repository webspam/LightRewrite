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
modLightRewrite.zip
└── mods/
    └── modLightRewrite/
        └── content/
            └── scripts/
                └── local/
                    └── [contents of src/ directory]
```

### Steps to Create a Release

1. **Create the folder structure:**
   - Create nested directories: `mods/modLightRewrite/content/scripts/local`

2. **Copy source files:**
   - Copy all files from the `src/` directory into `mods/modLightRewrite/content/scripts/local/`

3. **Create the zip archive:**
   - Zip the `mods/` directory (including the full folder hierarchy)
   - Name the zip file: `modLightRewrite.zip`

### Build requirements

- PowerShell 7: `winget install -e --id Microsoft.PowerShell`
