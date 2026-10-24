# Warp to light

Debug-only console command that drops the player next to a light source, facing it, in any world.

```
lrwarp(x, y, z)
lrwarp(x, y, z, "skellige")
```

`world` is optional (defaults to the current world) and matches any of:

- World directory, e.g. `novigrad`, `skellige`, `kaer_morhen`, `bob`, `prolog_village_winter`
- World file stem, e.g. `prolog_village`
- Area name, e.g. `AN_Skellige_ArdSkellig`
- Full `.w2w` path

## Flow

1. Same world, target within streaming range: search and teleport immediately
2. Same world, target far: teleport onto the light, then search on a deferred (0s) player timer
3. Other world: `ScheduleWorldChangeToPosition` onto the light; `CR4Player.OnSpawned` arms the deferred timer, since it runs before the first frame

## Look point

`LRDebug_LookPointResolver` finds the closest light-bearing gameplay entity within 1m of the XYZ and uses its first existing FX slot (`fire`, `fire1-4`, `fx`, `fx1-3`). An entity without FX slots uses the XYZ. If no entity is found, the search is retried until streaming catches up, then falls back to the XYZ on the final attempt.

## Search

`LRDebug_StandSpotFinder` probes 16 directions at radii 1.25 to 7m, in three rings at `light.Z - 1`, `light.Z` and `light.Z + 1`, keeping the best-scoring candidate. A candidate must have:

- Clear horizontal path from the light
- Walkable floor below (normal Z >= 0.7)
- Standing room (vertical ray + capsule sweep)
- `NavigationCircleTest` clear at 0.6m
- Eye-level line of sight to the light
- At least half of 32 directions open: body-radius sweeps, 2m long, at 0.6 / 1.1 / 1.6m height

Score prefers ~2m distance, light near eye height, and open surroundings (open fraction × 4).

Fallbacks: floor directly under the light, then `NavigationFindSafeSpot`.

Player heading and camera (held for 30 camera ticks via `OnGameCameraTick`) face the exact light position.
