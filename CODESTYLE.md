# Code Style

Normative, not descriptive: where existing code disagrees, the existing code changes.

## Naming

- `C` - concrete class
- `I` - abstract base used as an interface
- `S` - struct
- `E` - enum

Casing:

- members are `camelCase`
- functions are `PascalCase`
- `const var` constants are `SCREAMING_SNAKE_CASE`
- `TAG_` constants are `name`

### Namespaces

No language-level namespaces exist. Global names must be quasi-namespaced using a prefix.

Use prefixes to avoid latent clashes:

- Free functions (e.g. `LR_` for the LightRewrite mod)
- Methods (as above) / fields (e.g. `lrSettings`) added to existing base script classes via `@addField` / `@addMethod`
- Enum members are automatically global symbols and need prefixes

For classes / structs, prefer descriptive names, e.g. `CLightRewriteSettings`.

## Null handling

- Uninitialised object handles are `NULL`
- A failed cast yields a falsy value, so cast then guard:

```ws
light = (CPointLightComponent)components[i];
if (!light) continue;
```

## Local var initialisers

Prefer initialisers over split declarations, where it does not impact legibility / intent:

```ws
var count: int = components.Size();
```

- Loop counters and co-typed scratch group on one line (`var i, count: int;`), with count assigned immediately before the loop
- Cache `Size()` into `count` before a loop rather than re-calling it each pass
- Size arrays with `Grow`/`Resize` (fills default values)

## Prefer early return / continue over nested `if`

Always blank line after an early `continue` or `return` (or group thereof).

```ws
for (i = 0; i < count; i += 1) {
    light = (CPointLightComponent)components[i];
    if (!light) continue;
    if (light.shadowCastingMode == LSCM_None) continue;

    ...
}
```

## Miscellaneous

- A short body sits inline without braces (`if (wasEnabled) light.SetEnabled(false);`); compound bodies take braces
- Ternaries are not functional in witcherscript
- Prefer `switch` with `default` when there are more than two branches

## One return value

- Extra outputs are `out` parameters; a `bool` return signals success or "found".
- Trailing optionals use `optional`, with a caller-side guard - no `foo?.bar`, write `if (foo) foo.bar;`.

```ws
private function GetEntitySphere(entity: CGameplayEntity, out centre: Vector, out radius: float): bool
```

## Attaching to the engine

- Use `Init(...)` when a constructor is needed
- Default to always calling `super.X(...)` when overriding a method, and flag in a comment if intentionally avoiding that
- Prefer abstract methods (`function Abstract();` in an `abstract` class) wherever practical over empty virtual functions (`function Virtual() {}`)

## Performance worth taking

Take performance wins by default when it does not impact readability:

- Compare squared vector distances to avoid `SqrtF` calls
- Sort-and-sweep with an early `break` over an all-pairs scan

Don't optimise speculatively, and don't let performance bend the shape of the code - but don't leave an O(n) scan where the access is by key.

## Logging

Logging is for debugging, not for normal runtime. There are no log levels; trace logging is never an option.

Log through `LogLightRewrite` or a custom named helper where needed.
