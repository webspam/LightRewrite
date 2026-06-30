# Debug Editor

In-game light authoring overlay for Light Rewrite: floating labels on nearby light-bearing entities, a camera-forward highlight for the active target, and live attribute tweaks via keyboard and mouse.

Debug-only - not part of the distributed mod. Copy this folder into any `Mods/MODNAME/content/scripts` alongside the main mod scripts, or use `debug.ps1` from the repo to deploy it with the rest of the debug bundle.

## Input bindings

Every action must be bound in `input.settings` before the editor can be used. Example bindings are listed in the header of `lightLabels.ws` - copy the ones you want and change the keys to taste.

All keys are disabled in-game until `LRDebug_ToggleLabels` is toggled on. You can also bind direct-select actions (e.g. `LRDebug_SelectBrightness`) to jump straight to an attribute.

## Using it

- Turn labels on before any other control
- Face the light you want to edit; focus mode extends pick range
- Swap between point and spot lights
- Hold a modifier key (e.g. for brightness) and move the mouse to adjust that setting
- Toggle group edit to apply every change to all lights sharing the target's entity and layer path

## Requires

- `mod_sharedutils_oneliners` (`SU_Oneliner` base for label and toast oneliners)
- Main Light Rewrite mod (`CLightRewriteSourceParams`, `ILightSourceRewriter`, `CLightRewriteSettings`, etc.)

## Files

- **`lightLabels.ws`** - Entry point. Hooks the overlay into the player and the input bindings, and drives the periodic scan for nearby lights
- **`LRDebug_Targeting.ws`** - Targets the most camera-forward light each scan and exposes it via `GetTarget()`
- **`LRDebug_AttributeEditor.ws`** - Holds the attribute and light type currently being edited, and applies each change to the light
- **`LRDebug_LabelManager.ws`** - Creates and refreshes a floating label for every nearby light entity each scan tick
- **`LRDebug_LightOneLiner.ws`** - The floating label shown above a light entity
- **`LRDebug_PathLabel.ws`** - Screen label subclass that shows the active target's path at the bottom centre
- **`LRDebug_ToastOneLiner.ws`** - Brief on-screen confirmation messages
- **`LRDebug_EntityUtils.ws`** - Shared helpers for finding light components, recognising candles, and creating rewriters
- **`LRDebug_Export.ws`** - Exports the session's edits to the log, for distilling into XML

## Data flow

1. `lightLabels.ws` captures player input
2. `LRDebug_Targeting` picks the light you are aiming at
3. `LRDebug_AttributeEditor` turns the input into an attribute change
4. `ILightSourceRewriter` applies the change immediately
5. `LRDebug_LightOneLiner` refreshes the floating label
