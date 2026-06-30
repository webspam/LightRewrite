## XML functions in CDefinitionsManagerAccessor

The global `theGame.GetDefinitionsManager()` returns a singleton `CDefinitionsManagerAccessor` object.

### Behaviour

**`values`** holds the text content between a node's tags, as an array of `name`.

```xml
<!-- values[0] = 'candle', attributes.Size() = 0 -->
<match>candle</match>

<!-- values[0] = 'entryOne', values[1] = 'entryTwo' (CSV, trimmed) -->
<match>entryOne, entryTwo</match>

<!-- values[0] = 'levels\x\', attributes.Size() = 2 -->
<match type="layer" mode="startsWith">levels\x\</match>
```

- Attribute-only nodes (self-closing) have `values.Size() = 0`
- `GetCustomNodeAttributeValueString` returns `false` when the attribute is absent
- All XML files sharing the same `<custom>` definition name are merged by the engine; `GetCustomDefinition` returns the combined tree
