function ParseLightRewriteMatchRules(
    dm: CDefinitionsManagerAccessor,
    node: SCustomNode,
    group: CLightRewriteMatchGroup,
    allowGroups: bool
) {
    var rule: ILightRewriteMatchRule;
    var subGroup: CLightRewriteMatchAny;
    var child: SCustomNode;
    var i, count: int;

    count = node.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        child = node.subNodes[i];

        if (allowGroups && child.nodeName == 'any') {
            subGroup = new CLightRewriteMatchAny in group;
            ParseLightRewriteMatchRules(dm, child, subGroup, false);
            if (subGroup.rules.Size() > 0) group.rules.PushBack(subGroup);
        }
        else {
            rule = ParseLightRewriteRule(group, dm, child);
            if (rule) group.rules.PushBack(rule);
        }
    }
}

function ParseLightRewriteRule(
    owner: CObject,
    dm: CDefinitionsManagerAccessor,
    node: SCustomNode
): ILightRewriteMatchRule {
    if (node.nodeName == 'match') return ParseLightRewriteMatchRule(owner, dm, node);
    if (node.nodeName == 'match_scale') return ParseLightRewriteScaleRule(owner, dm, node);
    return NULL;
}

function ParseLightRewriteMatchRule(
    owner: CObject,
    dm: CDefinitionsManagerAccessor,
    matchNode: SCustomNode
): CLightRewriteMatchRule {
    var rule: CLightRewriteMatchRule;
    var strVal: string;

    if (matchNode.values.Size() == 0) return NULL;

    dm.GetCustomNodeAttributeValueString(matchNode, 'type', strVal);

    rule = new CLightRewriteMatchRule in owner;
    rule.matchValue = matchNode.values[0];

    if (strVal == "layer") rule.matchType = LR_Match_Layer;

    if (dm.GetCustomNodeAttributeValueString(matchNode, 'mode', strVal)) {
        switch (strVal) {
            case "endsWith":  rule.matchMode = LR_Match_EndsWith;  break;
            case "contains":  rule.matchMode = LR_Match_Contains;  break;
            case "exact":     rule.matchMode = LR_Match_Exact;     break;
        }
    }

    return rule;
}

function ParseLightRewriteScaleRule(
    owner: CObject,
    dm: CDefinitionsManagerAccessor,
    scaleNode: SCustomNode
): CLightRewriteScaleRule {
    var rule: CLightRewriteScaleRule;
    var strVal: string;

    if (!dm.GetCustomNodeAttributeValueString(scaleNode, 'mode', strVal)) {
        LogLightRewriteXml("Skipping invalid scale filter - missing mode attribute.");
        return NULL;
    }

    rule = new CLightRewriteScaleRule in owner;
    if (strVal == "larger") rule.matchValue = LR_Scale_Larger;
    else if (strVal == "smaller") rule.matchValue = LR_Scale_Smaller;

    if (dm.GetCustomNodeAttributeValueString(scaleNode, 'scale', strVal)) {
        rule.scale = StringToFloat(strVal, 1.0);
    }

    return rule;
}
