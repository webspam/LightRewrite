function FindLightRewriteProfileNames(out profileNames: array<name>) {
    var dm: CDefinitionsManagerAccessor;
    var lrNode: SCustomNode;
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
            LogLightRewriteXml("[XmlConfig] Found profile: " + NameToString(nameVal));
        }
    }
}

function ParseLightRewriteType(str: string): ELightRewriteType {
    switch (str) {
        case "LRT_Candle":     return LRT_Candle;
        case "LRT_Spotlight":  return LRT_Spotlight;
        default:               return LRT_None;
    }
}
