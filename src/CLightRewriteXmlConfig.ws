// Proof-of-concept reader for defaults.xml via the game's definitions manager.
// Logs every <default> entry and its child elements to the LightRewrite log channel.
function ReadLightRewriteXmlConfig() {
    var dm       : CDefinitionsManagerAccessor;
    var lrNode   : SCustomNode;
    var defaults : SCustomNode;
    var entry    : SCustomNode;
    var shadows  : SCustomNode;
    var colour   : SCustomNode;
    var i, count : int;
    var strVal   : string;

    dm       = theGame.GetDefinitionsManager();
    lrNode   = dm.GetCustomDefinition('light_rewrite');
    defaults = dm.GetCustomDefinitionSubNode(lrNode, 'defaults');

    count = defaults.subNodes.Size();
    LogLightRewrite("[XmlConfig] defaults.xml entries: " + count);

    for (i = 0; i < count; i += 1) {
        entry = defaults.subNodes[i];

        dm.GetCustomNodeAttributeValueString(entry, 'logging_name', strVal);
        LogLightRewrite("[XmlConfig] --- " + strVal + " ---");

        dm.GetCustomNodeAttributeValueString(entry, 'brightness',          strVal); LogLightRewrite("[XmlConfig]   brightness=" + strVal);
        dm.GetCustomNodeAttributeValueString(entry, 'radius',              strVal); LogLightRewrite("[XmlConfig]   radius=" + strVal);
        dm.GetCustomNodeAttributeValueString(entry, 'attenuation',         strVal); LogLightRewrite("[XmlConfig]   attenuation=" + strVal);
        dm.GetCustomNodeAttributeValueString(entry, 'use_spotlight_color', strVal); LogLightRewrite("[XmlConfig]   use_spotlight_color=" + strVal);

        shadows = dm.GetCustomDefinitionSubNode(entry, 'shadows');
        dm.GetCustomNodeAttributeValueString(shadows, 'fade_distance', strVal); LogLightRewrite("[XmlConfig]   shadows.fade_distance=" + strVal);
        dm.GetCustomNodeAttributeValueString(shadows, 'fade_range',    strVal); LogLightRewrite("[XmlConfig]   shadows.fade_range=" + strVal);
        dm.GetCustomNodeAttributeValueString(shadows, 'blend_factor',  strVal); LogLightRewrite("[XmlConfig]   shadows.blend_factor=" + strVal);

        colour = dm.GetCustomDefinitionSubNode(entry, 'override_colour');
        dm.GetCustomNodeAttributeValueString(colour, 'r', strVal); LogLightRewrite("[XmlConfig]   colour.r=" + strVal);
        dm.GetCustomNodeAttributeValueString(colour, 'g', strVal); LogLightRewrite("[XmlConfig]   colour.g=" + strVal);
        dm.GetCustomNodeAttributeValueString(colour, 'b', strVal); LogLightRewrite("[XmlConfig]   colour.b=" + strVal);
    }
}
