## XML functions in CDefinitionsManagerAccessor

The global `theGame.GetDefinitionsManager()` returns a singleton `CDefinitionsManagerAccessor` object.

### Function signatures

```witcherscript
function GetCustomDefinition(definition : name) : SCustomNode;
function GetAttributeValueAsInt(out node : SCustomNodeAttribute, out val : int) : bool;
function GetAttributeValueAsFloat(out node : SCustomNodeAttribute, out val : float) : bool;
function GetAttributeValueAsBool(out node : SCustomNodeAttribute, out val : bool) : bool;
function GetAttributeValueAsString(out node : SCustomNodeAttribute) : string;
function GetAttributeName(out node : SCustomNodeAttribute) : name;
function GetAttributeValueAsCName(out node : SCustomNodeAttribute) : name;
function GetSubNodeByAttributeValueAsCName(out node : SCustomNode, rootNodeName : name, attributeName : name, attributeValue : name) : bool;
function GetCustomDefinitionSubNode(out node : SCustomNode, subnode : name) : SCustomNode;
function FindAttributeIndex(out node : SCustomNode, attName : name) : int;
function GetCustomNodeAttributeValueString(out node : SCustomNode, attName : name, out val : string) : bool;
function GetCustomNodeAttributeValueName(out node : SCustomNode, attName : name, out val : name) : bool;
function GetCustomNodeAttributeValueInt(out node : SCustomNode, attName : name, out val : int) : bool;
function GetCustomNodeAttributeValueBool(out node : SCustomNode, attName : name, out val : bool) : bool;
function GetCustomNodeAttributeValueFloat(out node : SCustomNode, attName : name, out val : float) : bool;
```

### Structs

```witcherscript
struct SCustomNodeAttribute {
  var attributeName : name;
}

struct SCustomNode {
  var nodeName : name;
  var attributes : array<SCustomNodeAttribute>;
  var values : array<name>;
  var subNodes : array<SCustomNode>;
}
```

### Behaviour

**`values`** holds the text content between a node's tags, as an array of `name`.

```xml
<!-- values[0] = 'candle', attributes.Size() = 0 -->
<match>candle</match>

<!-- values[0] = 'entryOne', values[1] = 'entryTwo' (CSV, trimmed) -->
<match>entryOne, entryTwo</match>

<!-- values[0] = 'levels\x\', attributes.Size() = 2 -->
<match type="layer" mode="startsWith">levels\x\</match>

<!-- values.Size() = 0, attributes.Size() = 3 -->
<colour r="240" g="245" b="255" />
```

- `values` is populated by splitting tag text content on commas; each entry is trimmed.
- `values` and `attributes` coexist on the same node independently.
- Attribute-only nodes (e.g. self-closing) have `values.Size() = 0`.
- Backslash paths survive intact as `name` values (no escaping needed).
- `GetCustomNodeAttributeValueString` returns `false` when the attribute is absent — safe to use as a presence check.
- `GetCustomDefinitionSubNode` returns a node by tag name. To iterate multiple same-named children (e.g. several `<match>` nodes), iterate `subNodes` directly and check `nodeName`.
- All XML files sharing the same `<custom>` definition name are merged by the engine; `GetCustomDefinition` returns the combined tree.
