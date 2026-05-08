# Debug Editor Subsystem

An in-game light authoring overlay for the Light Rewrite mod. It renders floating labels
over nearby light-bearing entities, highlights the entity most directly in front of the
camera, and lets the developer tweak light attributes live with a keyboard and scroll wheel.

This is debug-only code — it is not part of the distributed mod. To use it, copy the
files in this directory into any `Mods/MODNAME/content/scripts` folder alongside the main
mod scripts.

---

## File overview

### `lightLabels.ws` — Entry point and input wiring

Injects fields into `CR4Player` and registers all input listeners. Because the player may
not be fully ready at spawn time, setup is deferred via a one-shot timer. Once active, a
repeating timer drives the label manager's `Scan()` call roughly every 100 ms.

All input actions must be bound in `input.settings`. The file header shows example
bindings. The master toggle (labels on/off) gates every other input — none of the
attribute or path controls do anything while labels are off.

The scroll wheel input uses a normalised value (the raw engine value divided by a constant
to account for the engine sending multiples per event). When `ShowDeveloperModeAlt` is
held during a scroll event, the scroll cycles the selected attribute rather than adjusting
its value.

Direct attribute-selection hotkeys (`LRDebug_SelectBrightness`, `LRDebug_SelectRadius`,
etc.) jump directly to a specific attribute index without cycling.

### `LRDebug_LabelManager.ws` — Label lifecycle and target selection

Manages the collection of `LRDebug_LightOneLiner` instances and tracks which entity is
the active editing target.

**`Scan()`** is called each timer tick and does two things:

1. Iterates nearby entities (from `FindGameplayEntitiesInRange`). Entities that already
   have an oneliner have it restarted if it went idle. Entities without one are checked
   for point or spot light components; if they have at least one, a new oneliner is
   created.

2. Among entities within the visibility range, selects the one most directly in front of
   the camera (highest dot product between the camera-forward vector and the vector to the
   entity) as the highlighted target. The previous target is de-highlighted; the new one
   is highlighted.

Visibility range expands when the game's focus mode (Witcher Senses) is active.

`ApplyAttributeAdjustment` delegates to `LRDebug_AttributeEditor.AdjustAttribute` and
then calls `RefreshTargetOneliner` if the adjustment succeeded.

`ToggleRewriterOnTarget` uses the `inOriginalState` flag (tracked by
`LRDebug_EntityUtils`) to toggle between the rewritten and original state, then shows a
brief confirmation toast.

### `LRDebug_LightOneLiner.ws` — Per-entity floating label

A state-machine class extending `SU_Oneliner` (from `mod_sharedutils_oneliners`). One
instance is created per entity and reused for its lifetime rather than being torn down and
recreated as the player moves.

**States:**
- `Idle` — registered but not updating position
- `FollowEntity` — updates position each frame to track the entity's world position, with
  a small upward offset. Exits to `Idle` when labels are toggled off or the entity moves
  out of range.

**Markup generation** is done in `GenerateText()` and only runs on explicit events:
highlight change, path-label toggle, or attribute cycle. The per-frame loop does no markup
work.

The label displays:
- A count of point and spot light components (green if non-zero, grey if zero)
- When highlighted: the currently selected attribute name and its current value, rendered
  in a distinct colour
- When path labels are enabled: the entity's filename, directory path, and level layer
  path, parsed from the entity's `ToString()` representation

The `lrdebugOneliner` field is injected onto `CGameplayEntity` here so all other files
can access it.

### `LRDebug_AttributeEditor.ws` — Attribute selection and adjustment

Owns the currently selected attribute index and all logic for reading, stepping, clamping,
and writing attribute values.

**Attribute stepping** is dynamic: the step size scales with the current value's magnitude
so that large values change in larger increments and small values in smaller ones. Clamped
attributes like `attenuation` and `shadowBlendFactor` use a fixed fine step instead.
Large scroll deltas are applied in sub-steps so that a fast swipe cannot jump across
step-size thresholds in one event.

**Lazy initialisation of params:** when an attribute is first adjusted on an entity, the
current live value from the light component is read and stored into `CLightRewriteSourceParams`
before the delta is applied. Subsequent adjustments work against the stored params.

For candle entities with an active spotlight, the spotlight is treated as the source light
rather than the point light.

Boolean attributes (`useSpotlightColor`, `alignPointLights`, `overrideColour`) interpret
a positive scroll value as "enable" and a negative value as "disable" — they cannot be
changed incrementally.

After every adjustment, `RewriteLight()` is called on the rewriter to apply the change
immediately to the running game.

**Responsibility boundary:** `AdjustAttribute` and `CycleAttribute` deliberately do not
refresh the oneliner's display text. The caller (`LRDebug_LabelManager`) is responsible
for calling `RefreshTargetOneliner` after each operation so the call flow stays explicit.

### `LRDebug_AdjustAccelerator.ws` — Scroll-wheel acceleration

Tracks burst patterns in the scroll event stream to ramp a step multiplier for faster
adjustments when scrolling quickly.

Acceleration activates after a tight burst of consecutive events. Once active, the
multiplier increases with streak length and caps at a configured maximum. A direction
reversal cuts the streak and schedules a brief deceleration window. A pause longer than
the reset threshold clears all state, supporting the "lift finger and reposition"
pattern common on physical scroll wheels.

Returns a multiplier of 1.0 while not accelerating so callers need no special-case logic.

### `LRDebug_EntityUtils.ws` — Entity and component utilities

Free functions and class extensions used across the editor subsystem:

- **Component helpers** — retrieve the first point or spot light component on an entity
  by component class name.
- **Entity classification** — heuristic candle detection based on the entity's name
  string; candle holders are excluded. Used to determine which rewriter type to create
  and which light component to treat as the source.
- **`LRDebug_GetOrCreateRewriter()`** (injected onto `CGameplayEntity`) — returns the
  entity's existing rewriter if it has one, otherwise creates a transient debug rewriter
  so that entities not covered by the active Light Rewrite profile can still be edited.
- **`inOriginalState` tracking** — injects a boolean onto `ILightSourceRewriter` and
  wraps `RewriteLight()` and `RestoreOriginalState()` on the concrete rewriter types to
  keep the flag accurate.
- **`LRDebug_SetMenuOverrideParams` / `LRDebug_ClearMenuOverrideParams`** (injected onto
  `ILightSourceRewriter`) — expose the `menuOverrideParams` field that the main mod uses
  for menu-driven overrides; the editor reuses the same slot.

### `LRDebug_ToastOneLiner.ws` — Transient notification

A brief floating text notification that follows the player at head height for a fixed
duration, then goes idle. Used to confirm toggle actions. Implemented as a state-machine
`SU_Oneliner` with `Idle` and `FollowPlayer` states.

---

## Data flow summary

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

---

## Dependencies

- `mod_sharedutils_oneliners` — provides the `SU_Oneliner` base class used by both
  `LRDebug_LightOneLiner` and `LRDebug_ToastOneLiner`.
- The main Light Rewrite mod scripts — `CLightRewriteSourceParams`, `ILightSourceRewriter`,
  `CLightRewriteSettings`, and related types must be present.
