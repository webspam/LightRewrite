# Debug Editor

In-game light authoring overlay for Light Rewrite: floating labels on nearby light-bearing entities, a camera-forward highlight for the active target, and live attribute tweaks via keyboard and scroll wheel.

Debug-only - not part of the distributed mod. Copy this folder into any `Mods/MODNAME/content/scripts` alongside the main mod scripts, or use `debug.ps1` from the repo to deploy it with the rest of the debug bundle.

## Input bindings

Every action must be bound in `input.settings` before the editor can be used. Example bindings are listed in the header of `lightLabels.ws` - copy the ones you want and change the keys to taste.

All keys are disabled in-game until `LRDebug_ToggleLabels` is toggled on. You can also bind direct-select actions (e.g. `LRDebug_SelectBrightness`) to jump straight to an attribute.

## Using it

- Turn labels on before any other control
- Scroll to adjust; `ShowDeveloperModeAlt` + scroll to cycle attribute
- Face the light you want to edit; focus mode extends pick range
- Swap between point and spot lights
- Hold a modifier key (e.g. for brightness) and move the mouse to adjust that setting

## Requires

- `mod_sharedutils_oneliners` (`SU_Oneliner` base for label and toast oneliners)
- Main Light Rewrite mod (`CLightRewriteSourceParams`, `ILightSourceRewriter`, `CLightRewriteSettings`, etc.)

## Files

- **`lightLabels.ws`** - Entry point. Hooks the overlay into the player and the input bindings, and drives the periodic scan for nearby lights.
- **`LRDebug_LabelManager.ws`** - The heart of the overlay: tracks nearby light entities, decides which one you are aiming at, and routes edits and label updates accordingly.
- **`LRDebug_AttributeEditor.ws`** - Holds the attribute and light type currently being edited, and applies each change to the light.
- **`LRDebug_AdjustAccelerator.ws`** - Speeds up adjustment when you scroll quickly.
- **`LRDebug_LightOneLiner.ws`** - The floating label shown above a light entity.
- **`LRDebug_TargetMarkers.ws`** - Markers for each individual light on the targeted entity.
- **`LRDebug_WorldMarker.ws`** - A single label pinned to a point in the world.
- **`LRDebug_ToastOneLiner.ws`** - Brief on-screen confirmation messages.
- **`LRDebug_EntityUtils.ws`** - Shared helpers for finding light components, recognising candles, and creating rewriters.
- **`LRDebug_LightSpacer.ws`** - One-shot pass that shrinks crowded shadow-casting lights to reduce overlaps.
- **`LRDebug_Export.ws`** - Exports the session's edits to the log, for distilling into XML.

## Data flow

1. `lightLabels.ws` captures player input
2. `LRDebug_LabelManager` picks the light you are aiming at
3. `LRDebug_AttributeEditor` turns the input into an attribute change
4. `LRDebug_AdjustAccelerator` scales the step when scrolling fast
5. `ILightSourceRewriter` applies the change immediately
6. `LRDebug_LightOneLiner` refreshes the floating label
