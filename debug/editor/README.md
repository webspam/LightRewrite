# Debug Editor

In-game light authoring overlay for Light Rewrite: floating labels on nearby light-bearing entities, a camera-forward highlight for the active target, and live attribute tweaks via keyboard and scroll wheel.

Debug-only - not part of the distributed mod. Copy this folder into any `Mods/MODNAME/content/scripts` alongside the main mod scripts, or use `debug.ps1` from the repo to deploy it with the rest of the debug bundle.

## Files

### `lightLabels.ws` - entry point and input

Injects fields into `CR4Player`, defers setup with a one-shot timer (player may not be ready at spawn), then registers input listeners and a repeating timer (~100 ms) that calls `LRDebug_LabelManager.Scan()`.

All actions must be bound in `input.settings` (example bindings in the file header). `LRDebug_ToggleLabels` gates everything else. Scroll input is normalised (engine sends multiples of ±3 per event). Hold `ShowDeveloperModeAlt` during scroll to cycle the selected attribute instead of adjusting it. Direct-select actions (`LRDebug_SelectBrightness`, etc.) jump to a specific attribute when bound. `LRDebug_ExportEdited` triggers export.

### `LRDebug_LabelManager.ws` - labels and target

Creates and reuses `LRDebug_LightOneLiner` instances for nearby entities with point or spot lights (`FindNearbyLights` → `FindGameplayEntitiesInRange`). Restarts idle oneliners; picks the highlighted target as the most in-front entity within range (10 m, 25 m with Witcher Senses). Delegates value changes to `LRDebug_AttributeEditor` and refreshes the target label on success. `ToggleRewriterOnTarget` flips rewritten vs original via `inOriginalState` and shows a toast.

### `LRDebug_LightOneLiner.ws` - floating label

Extends `SU_Oneliner`; one instance per entity, reused for its lifetime. States: `Idle` (not tracking) and `FollowEntity` (tracks entity position with a small Z offset until labels off or out of range). Markup is regenerated only on highlight change, path toggle, or attribute change - not every frame.

Shows point/spot counts (green/grey), and when highlighted the selected attribute name and value. Optional path lines (filename, path, layer) from `entity.ToString()`. Injects `lrdebugOneliner` on `CGameplayEntity`.

### `LRDebug_AttributeEditor.ws` - attributes

Owns the selected attribute index, dynamic step sizes (magnitude-based; fine fixed steps for clamped attrs), and sub-stepping on large scroll deltas. Params are lazy-initialised per field from the live source light on first adjustment (`LRDebug_GetParams` seeds the object earlier from effective rewriter params). Candles with an active spotlight use the spot as the source. Booleans (`useSpotlightColor`, `alignPointLights`, `overrideColour`) toggle on scroll sign. Each change applies via `menuOverrideParams` and `RewriteLight()`. Does not refresh the oneliner - callers must call `RefreshTargetOneliner`.

### `LRDebug_AdjustAccelerator.ws` - scroll acceleration

Ramps a step multiplier after a burst of scroll events; direction reversal halves the streak; a pause resets state. Returns 1.0 when not accelerating.

### `LRDebug_EntityUtils.ws` - helpers

Point/spot component lookup, candle name heuristic (excludes holders), debug rewriter creation for entities outside the active profile (`LRDebug_GetOrCreateRewriter`), `inOriginalState` tracking on `ILightSourceRewriter`, and `menuOverrideParams` accessors.

### `LRDebug_ToastOneLiner.ws` - notifications

Brief text at head height for confirmations (e.g. rewriter on/off).

### `LRDebug_Export.ws` - export

`LRDebug_ExportEditedLights()` scans tagged light entities and logs `[LRDebug_Export]` lines for anything with session edits, for distillation into XML via `tools/Export-Lights.ps1`.

## Data flow

```
CR4Player (lightLabels.ws)
  │  input events
  ▼
LRDebug_LabelManager          ← Scan() tick, target selection
  │  target entity
  ▼
LRDebug_AttributeEditor       ← AdjustAttribute(), CycleAttribute()
  │  scroll value
  ▼
LRDebug_AdjustAccelerator     ← GetMultiplier()
  │  multiplied step
  ▼
CLightRewriteSourceParams     ← updated on entity
  │
  ▼
ILightSourceRewriter.RewriteLight()   ← applies change immediately
  │
  ▼
LRDebug_LightOneLiner.RegenerateText()  ← updates floating label
```

## Using it

- Bind actions in `input.settings` - see `lightLabels.ws` header (e.g. Numpad 7/8/9: toggle labels, path labels, export).
- Turn labels on before any other control.
- Scroll to adjust; `ShowDeveloperModeAlt` + scroll to cycle attribute.
- Face the light you want to edit; focus mode extends pick range.

## Requires

- `mod_sharedutils_oneliners` (`SU_Oneliner` base for label and toast oneliners)
- Main Light Rewrite mod (`CLightRewriteSourceParams`, `ILightSourceRewriter`, `CLightRewriteSettings`, etc.)
