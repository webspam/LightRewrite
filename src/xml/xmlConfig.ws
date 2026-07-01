function FindLightRewriteProfileNames(out profileNames: array<name>) {
    var dm: CDefinitionsManagerAccessor;
    var lrNode, overridesNode, entryNode: SCustomNode;
    var i, count: int;
    var nameVal: name;

    dm = theGame.GetDefinitionsManager();
    lrNode = dm.GetCustomDefinition('light_rewrite');

    count = lrNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        if (
            dm.GetCustomNodeAttributeValueName(lrNode.subNodes[i], 'profile_name', nameVal) &&
            !profileNames.Contains(nameVal)
        ) {
            profileNames.PushBack(nameVal);
        }

        LogLightRewrite("[XmlConfig] Found profile: " + NameToString(nameVal));
    }
}

function ParseLightRewriteType(str: string): ELightRewriteType {
    switch (str) {
        case "LRT_Candle":      return LRT_Candle;
        case "LRT_Spotlight":   return LRT_Spotlight;
        case "LRT_Torch":       return LRT_Torch;
        case "LRT_Brazier":     return LRT_Brazier;
        case "LRT_Candelabra":  return LRT_Candelabra;
        case "LRT_Campfire":    return LRT_Campfire;
        case "LRT_Chandelier":  return LRT_Chandelier;
        default:                return LRT_None;
    }
}
